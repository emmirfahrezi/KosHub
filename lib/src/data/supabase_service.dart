part of '../../main.dart';

class SupabaseService {
  SupabaseService._();

  static final instance = SupabaseService._();
  static const _publicUploadBucket = 'app-uploads';

  supabase.SupabaseClient get _client => supabase.Supabase.instance.client;

  Future<String> uploadPublicImage({
    required User user,
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async {
    try {
      final extension = _normalizedImageExtension(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final objectPath = '$folder/${user.id}/$timestamp.$extension';

      await _client.storage
          .from(_publicUploadBucket)
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: supabase.FileOptions(
              upsert: false,
              contentType: _imageContentType(extension),
            ),
          );

      return _client.storage.from(_publicUploadBucket).getPublicUrl(objectPath);
    } catch (_) {
      throw SupabaseAppException(
        plugin: 'supabase_storage',
        code: 'upload-failed',
        message:
            'Upload gambar gagal. Pastikan bucket Storage `app-uploads` dan policy upload-nya sudah dibuat di project Supabase.',
      );
    }
  }

  Future<String> uploadOwnerImage({
    required User user,
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) {
    return uploadPublicImage(
      user: user,
      bytes: bytes,
      fileName: fileName,
      folder: folder,
    );
  }

  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    final credential = await SupabaseAuth.instance.signInWithPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await ensureUserProfile(
      user,
      fallbackName: user.displayName ?? email.split('@').first,
    );

    final existing = await _profileMap(user.id);
    final existingRole = existing?['role'] as String? ?? 'penyewa';
    final canSeedAdmin = _adminSeedEmails.contains(email.toLowerCase());

    if (!_isAdminRole(existingRole) && canSeedAdmin) {
      await _client
          .from('profiles')
          .update({
            'name':
                existing?['name'] as String? ??
                user.displayName ??
                'Admin Koshub',
            'email': user.email,
            'role': 'super_admin',
            'is_active': true,
            'account_status': 'Aktif',
            'verification_status': 'Terverifikasi',
            'login_activity': 'Login ${_formatLongDate(DateTime.now())}',
          })
          .eq('id', user.id);
      return;
    }

    if (!_isAdminRole(existingRole)) {
      await SupabaseAuth.instance.signOut();
      throw SupabaseAppException(
        plugin: 'supabase',
        code: 'permission-denied',
        message: 'Akun ini bukan admin aplikasi Koshub.',
      );
    }

    await _client
        .from('profiles')
        .update({'login_activity': 'Login ${_formatLongDate(DateTime.now())}'})
        .eq('id', user.id);
  }

  Future<void> ensureUserProfile(
    User user, {
    required String fallbackName,
  }) async {
    final existingData = await _profileMap(user.id);
    await _client.from('profiles').upsert({
      'id': user.id,
      'name': user.displayName ?? fallbackName,
      'email': user.email ?? '-',
      'role': existingData?['role'] as String? ?? 'penyewa',
      'is_active': existingData?['is_active'] as bool? ?? true,
      'photo_url': user.photoURL ?? existingData?['photo_url'] ?? '',
      'phone_number': existingData?['phone_number'] as String? ?? '',
      'account_status': existingData?['account_status'] as String? ?? 'Aktif',
      'verification_status':
          existingData?['verification_status'] as String? ?? 'Belum Verifikasi',
      'requested_role': existingData?['requested_role'] as String? ?? '',
      'activation_payment_status':
          existingData?['activation_payment_status'] as String? ??
          'Belum Bayar',
      'owner_activation_fee':
          (existingData?['owner_activation_fee'] as num?)?.toInt() ??
          _ownerActivationBaseFee,
      'owner_activation_discount':
          (existingData?['owner_activation_discount'] as num?)?.toInt() ?? 0,
      'owner_voucher_code':
          existingData?['owner_voucher_code'] as String? ?? '',
    });
  }

  String _normalizedImageExtension(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'png';
    }
    if (lower.endsWith('.webp')) {
      return 'webp';
    }
    if (lower.endsWith('.gif')) {
      return 'gif';
    }
    if (lower.endsWith('.heic')) {
      return 'heic';
    }
    if (lower.endsWith('.heif')) {
      return 'heif';
    }
    return 'jpg';
  }

  String _imageContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> updateTenantProfile({
    required User user,
    required String name,
    required String phoneNumber,
    required String photoUrl,
    String? newPassword,
  }) async {
    await user.updateProfile(displayName: name, photoUrl: photoUrl);
    if (newPassword != null && newPassword.trim().isNotEmpty) {
      await user.updatePassword(newPassword.trim());
    }

    await _client
        .from('profiles')
        .update({
          'name': name.trim(),
          'email': user.email ?? '-',
          'phone_number': phoneNumber.trim(),
          'photo_url': photoUrl.trim(),
        })
        .eq('id', user.id);
  }

  Future<void> updateOwnerBankAccount({
    required User user,
    required String bankAccount,
  }) async {
    final value = bankAccount.trim();
    try {
      await _client
          .from('profiles')
          .update({'bank_account': value})
          .eq('id', user.id);

      try {
        await _client
            .from('kos')
            .update({'bank_account': value})
            .eq('owner_id', user.id);
      } on supabase.PostgrestException catch (error) {
        final message = error.message.toLowerCase();
        if (message.contains('bank_account') &&
            (message.contains('column') || message.contains('schema cache'))) {
          throw SupabaseAppException(
            plugin: 'supabase',
            code: 'kos-bank-account-column-missing',
            message:
                'Rekening tersimpan di profil owner, tapi tabel kos di database belum punya kolom `bank_account`. Jalankan update schema Supabase dulu agar rekening bisa tampil di halaman booking.',
          );
        }
        rethrow;
      }
    } on SupabaseAppException {
      rethrow;
    } on supabase.PostgrestException catch (error) {
      throw SupabaseAppException(
        plugin: 'supabase',
        code: error.code ?? 'postgrest-error',
        message: error.message,
      );
    } catch (_) {
      throw SupabaseAppException(
        plugin: 'supabase',
        code: 'update-owner-bank-account-failed',
        message: 'Rekening pembayaran belum berhasil disimpan. Coba lagi.',
      );
    }
  }

  Future<void> registerOwnerKos({
    required User user,
    required String ownerName,
    required String kosName,
    required String area,
    required String address,
    required String description,
    required int monthlyPrice,
    required int availableRooms,
    required String category,
    required String approvalMode,
    required List<String> facilities,
    required String photoUrl,
    required String phoneNumber,
    required String ktpNumber,
    required String emergencyContact,
    required String bankAccount,
    required String paymentProofUrl,
    required String voucherCode,
  }) async {
    await user.updateDisplayName(ownerName);
    final existingVoucher = await _findOwnerVoucherByCode(voucherCode);
    final voucherDiscount = existingVoucher?.discountAmount ?? 0;
    final activationFee = _ownerActivationBaseFee;

    await _client.from('profiles').upsert({
      'id': user.id,
      'name': ownerName,
      'email': user.email ?? '-',
      'role': 'penyewa',
      'requested_role': 'pemilik',
      'is_active': false,
      'photo_url': user.photoURL ?? photoUrl,
      'phone_number': phoneNumber,
      'ktp_number': ktpNumber,
      'emergency_contact': emergencyContact,
      'bank_account': bankAccount,
      'account_status': 'Menunggu Aktivasi',
      'verification_status': paymentProofUrl.isEmpty
          ? 'Menunggu Pembayaran'
          : 'Menunggu Verifikasi',
      'activation_payment_method': 'Transfer Manual',
      'activation_payment_status': paymentProofUrl.isEmpty
          ? 'Belum Bayar'
          : 'Menunggu Konfirmasi',
      'activation_payment_proof_url': paymentProofUrl,
      'owner_activation_fee': activationFee,
      'owner_activation_discount': voucherDiscount,
      'owner_voucher_code': existingVoucher?.code ?? '',
      'owner_application_submitted_at': DateTime.now()
          .toUtc()
          .toIso8601String(),
      'admin_notes': '',
      'owner_status': 'Menunggu aktivasi admin',
    });

    await _client.from('kos').insert({
      'owner_id': user.id,
      'owner_name': ownerName,
      'owner_status': 'Menunggu aktivasi admin',
      'owner_photo': user.photoURL ?? photoUrl,
      'bank_account': bankAccount,
      'nama_kos': kosName,
      'area': area,
      'alamat': address,
      'deskripsi': description,
      'harga_mulai': monthlyPrice,
      'fasilitas': facilities,
      'gender': category,
      'approval_mode': approvalMode,
      'foto_urls': [photoUrl],
      'rating': 0,
      'total_review': 0,
      'total_rooms': availableRooms,
      'available_rooms': availableRooms,
      'status': 'pending_review',
    });
  }

  Future<void> updateOwnerKos({
    required User user,
    required String kosId,
    required String ownerName,
    required String kosName,
    required String area,
    required String address,
    required String description,
    required int monthlyPrice,
    required int availableRooms,
    required String category,
    required String approvalMode,
    required List<String> facilities,
    required String photoUrl,
    required String phoneNumber,
    required String ktpNumber,
    required String emergencyContact,
    required String bankAccount,
    required String paymentProofUrl,
    required String voucherCode,
  }) async {
    await user.updateDisplayName(ownerName);
    final userData = await _profileMap(user.id) ?? const <String, dynamic>{};
    final voucher = await _findOwnerVoucherByCode(voucherCode);
    final isApprovedOwner =
        userData['role'] == 'pemilik' &&
        (userData['account_status'] as String? ?? '') == 'Aktif' &&
        (userData['verification_status'] as String? ?? '') == 'Terverifikasi';
    final desiredListingStatus = isApprovedOwner ? 'active' : 'pending_review';

    await _client.from('profiles').upsert({
      'id': user.id,
      'name': ownerName,
      'email': user.email ?? '-',
      'role': isApprovedOwner ? 'pemilik' : 'penyewa',
      'requested_role': 'pemilik',
      'is_active': isApprovedOwner,
      'photo_url': user.photoURL ?? photoUrl,
      'phone_number': phoneNumber,
      'ktp_number': ktpNumber,
      'emergency_contact': emergencyContact,
      'bank_account': bankAccount,
      'account_status': isApprovedOwner ? 'Aktif' : 'Menunggu Aktivasi',
      'verification_status': isApprovedOwner
          ? 'Terverifikasi'
          : (paymentProofUrl.isEmpty
                ? 'Menunggu Pembayaran'
                : 'Menunggu Verifikasi'),
      'activation_payment_method': 'Transfer Manual',
      'activation_payment_status': isApprovedOwner
          ? 'Lunas'
          : (paymentProofUrl.isEmpty ? 'Belum Bayar' : 'Menunggu Konfirmasi'),
      'activation_payment_proof_url': paymentProofUrl,
      'owner_activation_fee':
          (userData['owner_activation_fee'] as num?)?.toInt() ??
          _ownerActivationBaseFee,
      'owner_activation_discount':
          voucher?.discountAmount ??
          (userData['owner_activation_discount'] as num?)?.toInt() ??
          0,
      'owner_voucher_code':
          voucher?.code ?? userData['owner_voucher_code'] as String? ?? '',
      'owner_application_submitted_at':
          userData['owner_application_submitted_at'] ??
          DateTime.now().toUtc().toIso8601String(),
      'owner_status': isApprovedOwner ? 'Online' : 'Menunggu aktivasi admin',
    });

    await _client
        .from('kos')
        .update({
          'owner_id': user.id,
          'owner_name': ownerName,
          'owner_status': isApprovedOwner
              ? 'Online'
              : 'Menunggu aktivasi admin',
          'owner_photo': user.photoURL ?? photoUrl,
          'bank_account': bankAccount,
          'nama_kos': kosName,
          'area': area,
          'alamat': address,
          'deskripsi': description,
          'harga_mulai': monthlyPrice,
          'fasilitas': facilities,
          'gender': category,
          'approval_mode': approvalMode,
          'foto_urls': [photoUrl],
          'total_rooms': availableRooms,
          'available_rooms': availableRooms,
          'status': desiredListingStatus,
        })
        .eq('id', kosId);
  }

  Stream<AppUserData?> userProfileStream(String uid) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .map((rows) {
          if (rows.isEmpty) {
            return null;
          }
          return AppUserData.fromMap(uid, _asStringMap(rows.first)!);
        });
  }

  Future<AppUserData?> fetchUserProfile(String userId) async {
    final row = await _profileMap(userId);
    if (row == null) {
      return null;
    }
    return AppUserData.fromMap(userId, row);
  }

  Future<KosData?> fetchKosById(String kosId) async {
    return _resolveKosData(kosId: kosId, fallbackMap: null);
  }

  Future<KosData?> fetchOwnerKosByOwnerId(String ownerId) async {
    final rows = await _client
        .from('kos')
        .select()
        .eq('owner_id', ownerId)
        .eq('status', 'active');
    final items = rows
        .map((row) => KosData.fromMap(row['id'].toString(), row))
        .toList();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items.isEmpty ? null : items.first;
  }

  Stream<KosData?> ownerKosStream(String ownerId) {
    return _client
        .from('kos')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .map((rows) {
          final items = rows
              .where((row) => row['status'] == 'active')
              .map((row) => KosData.fromMap(row['id'].toString(), row))
              .toList();
          items.sort((a, b) => a.name.compareTo(b.name));
          return items.isEmpty ? null : items.first;
        });
  }

  Stream<KosData?> ownerManagedKosStream(String ownerId) {
    return _client
        .from('kos')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .map((rows) {
          final items = rows
              .map((row) => KosData.fromMap(row['id'].toString(), row))
              .toList();
          items.sort((a, b) => b.id.compareTo(a.id));
          return items.isEmpty ? null : items.first;
        });
  }

  Stream<List<KosData>> kosStream() {
    return _client
        .from('kos')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .map((rows) {
          final items = rows
              .map((row) => KosData.fromMap(row['id'].toString(), row))
              .toList();
          items.sort((a, b) => a.name.compareTo(b.name));
          return items;
        });
  }

  Future<void> seedSampleData() async {
    final user = SupabaseAuth.instance.currentUser;
    if (user == null) {
      throw SupabaseAppException(
        plugin: 'supabase',
        code: 'unauthenticated',
        message: 'Login dulu untuk membuat data demo.',
      );
    }

    final ownerName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email?.split('@').first ?? 'Pemilik Kos Demo';
    final ownerPhoto =
        user.photoURL ??
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80';

    await _client.from('profiles').upsert({
      'id': user.id,
      'name': ownerName,
      'email': user.email ?? '-',
      'role': 'pemilik',
      'is_active': true,
      'photo_url': ownerPhoto,
      'owner_status': 'Online',
      'requested_role': 'pemilik',
      'account_status': 'Aktif',
      'verification_status': 'Terverifikasi',
      'activation_payment_status': 'Lunas',
      'owner_activation_fee': _ownerActivationBaseFee,
      'owner_activation_discount': 0,
    });
    await _client.from('kos').insert([
      _sampleKosMap1.forOwner(
        ownerId: user.id,
        ownerName: ownerName,
        ownerPhoto: ownerPhoto,
      ),
      _sampleKosMap2.forOwner(
        ownerId: user.id,
        ownerName: ownerName,
        ownerPhoto: ownerPhoto,
      ),
    ]);
  }

  Future<String> createOrGetChat(KosData kos) async {
    final user = SupabaseAuth.instance.currentUser!;
    final profile = await _profileMap(user.id) ?? const <String, dynamic>{};
    final penyewaName =
        profile['name'] as String? ??
        user.displayName ??
        user.email?.split('@').first ??
        'Penyewa';
    final penyewaPhoto = profile['photo_url'] as String? ?? user.photoURL ?? '';
    final row = await _client
        .from('chats')
        .upsert({
          'kos_id': kos.id,
          'owner_name': kos.ownerName,
          'owner_photo': kos.ownerPhoto,
          'owner_id': kos.ownerId,
          'kos_snapshot': kos.toMap(),
          'penyewa_id': user.id,
          'penyewa_name': penyewaName,
          'penyewa_photo': penyewaPhoto,
          'participant_ids': [user.id, kos.ownerId],
        }, onConflict: 'kos_id,penyewa_id')
        .select('id')
        .single();
    return row['id'].toString();
  }

  Stream<List<ChatPreviewData>> userChatsStream(String userId) {
    return _client
        .from('chats')
        .stream(primaryKey: ['id'])
        .map((rows) async {
          final items = await Future.wait(
            rows
                .where(
                  (row) =>
                      (row['participant_ids'] as List<dynamic>? ?? const [])
                          .map((item) => item.toString())
                          .contains(userId),
                )
                .map((row) async {
                  final kos = await _resolveKosData(
                    kosId: row['kos_id'] as String? ?? '',
                    fallbackMap: _asStringMap(row['kos_snapshot']),
                  );
                  if (kos == null) {
                    return null;
                  }
                  return ChatPreviewData.fromMap(
                    id: row['id'].toString(),
                    data: row,
                    kos: kos,
                  );
                }),
          );
          final resolved = items.whereType<ChatPreviewData>().toList();
          resolved.sort((a, b) => b.sortKey.compareTo(a.sortKey));
          return resolved;
        })
        .asyncMap((value) => value);
  }

  Stream<ChatPreviewData?> chatPreviewStream({
    required String chatId,
    required KosData fallbackKos,
  }) {
    return _client
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq('id', chatId)
        .map((rows) {
          if (rows.isEmpty) {
            return null;
          }
          return ChatPreviewData.fromMap(
            id: rows.first['id'].toString(),
            data: rows.first,
            kos: fallbackKos,
          );
        });
  }

  Stream<List<ChatMessageData>> messagesStream(String chatId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at')
        .map((rows) {
          return rows.map((row) {
            return ChatMessageData.fromMap(row['id'].toString(), {
              ...row,
              'timestamp': row['created_at'],
            });
          }).toList();
        });
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
    required KosData kos,
  }) async {
    final user = SupabaseAuth.instance.currentUser!;
    final profile = await _profileMap(user.id) ?? const <String, dynamic>{};
    final senderName =
        profile['name'] as String? ??
        user.displayName ??
        user.email?.split('@').first ??
        'Pengguna';
    final senderPhoto = profile['photo_url'] as String? ?? user.photoURL ?? '';
    final isPenyewa = user.id != kos.ownerId;
    final chatMetadata = <String, dynamic>{
      'last_message': text,
      'last_message_time': DateTime.now().toUtc().toIso8601String(),
    };

    if (isPenyewa) {
      chatMetadata.addAll({
        'penyewa_id': user.id,
        'penyewa_name': senderName,
        'penyewa_photo': senderPhoto,
      });
    }

    await _client.from('chat_messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'sender_name': senderName,
      'text': text,
    });
    await _client.from('chats').update(chatMetadata).eq('id', chatId);
  }

  Stream<List<BookingData>> userBookingsStream(String userId) {
    return _bookingsStream('user_id', userId);
  }

  Stream<List<BookingData>> ownerBookingsStream(String ownerId) {
    return _bookingsStream('owner_id', ownerId);
  }

  Stream<List<AppUserData>> allUsersStream() {
    return _client.from('profiles').stream(primaryKey: ['id']).map((rows) {
      final items = rows
          .map((row) => AppUserData.fromMap(row['id'].toString(), row))
          .toList();
      items.sort((a, b) => b.sortKey.compareTo(a.sortKey));
      return items;
    });
  }

  Stream<List<AppUserData>> ownerUsersStream() {
    return allUsersStream().map(
      (items) => items.where((user) => user.hasOwnerRequest).toList(),
    );
  }

  Stream<List<KosData>> adminKosStream() {
    return _client.from('kos').stream(primaryKey: ['id']).map((rows) {
      final items = rows
          .map((row) => KosData.fromMap(row['id'].toString(), row))
          .toList();
      items.sort((a, b) => a.name.compareTo(b.name));
      return items;
    });
  }

  Stream<List<BookingData>> allBookingsStream() {
    return _bookingsStream(null, null);
  }

  Stream<AdminDashboardData> adminDashboardStream() {
    return allUsersStream().asyncMap((users) async {
      final kosRows = await _client.from('kos').select();
      final bookingRows = await _client.from('bookings').select();
      final kosList = kosRows
          .map((row) => KosData.fromMap(row['id'].toString(), row))
          .toList();
      final bookings = await Future.wait(
        bookingRows.map((row) => _bookingFromRow(row)),
      );

      return AdminDashboardData.fromCollections(
        users: users,
        kosList: kosList,
        bookings: bookings.whereType<BookingData>().toList(),
      );
    });
  }

  Stream<List<HomeBannerData>> homeBannersStream() {
    return _client.from('cms_home_banners').stream(primaryKey: ['id']).map((
      rows,
    ) {
      final items = rows
          .map((row) => HomeBannerData.fromMap(row['id'].toString(), row))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<OwnerVoucherData>> ownerVouchersStream() {
    return _client.from('owner_vouchers').stream(primaryKey: ['id']).map((
      rows,
    ) {
      final items = rows
          .map((row) => OwnerVoucherData.fromMap(row['id'].toString(), row))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> saveHomeBanner({
    String? bannerId,
    required String title,
    required String subtitle,
    required String imageUrl,
    required String placement,
    required bool isActive,
  }) async {
    final data = {
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'placement': placement,
      'is_active': isActive,
    };
    if (bannerId == null || bannerId.isEmpty) {
      await _client.from('cms_home_banners').insert(data);
    } else {
      await _client.from('cms_home_banners').update(data).eq('id', bannerId);
    }
  }

  Future<void> deleteHomeBanner(String bannerId) async {
    await _client.from('cms_home_banners').delete().eq('id', bannerId);
  }

  Future<void> saveOwnerVoucher({
    String? voucherId,
    required String code,
    required String title,
    required String description,
    required int discountAmount,
    required bool isActive,
  }) async {
    final data = {
      'code': code.toUpperCase(),
      'title': title,
      'description': description,
      'discount_amount': discountAmount,
      'is_active': isActive,
    };
    if (voucherId == null || voucherId.isEmpty) {
      await _client.from('owner_vouchers').insert(data);
    } else {
      await _client.from('owner_vouchers').update(data).eq('id', voucherId);
    }
  }

  Future<void> deleteOwnerVoucher(String voucherId) async {
    await _client.from('owner_vouchers').delete().eq('id', voucherId);
  }

  Future<void> updateUserFromAdmin({
    required String userId,
    required String role,
    required String accountStatus,
    required String verificationStatus,
    required String requestedRole,
    String? adminNotes,
  }) async {
    final isOwnerActive =
        role == 'pemilik' &&
        accountStatus == 'Aktif' &&
        verificationStatus == 'Terverifikasi';
    final isActive = accountStatus == 'Aktif' || accountStatus == 'Peringatan';
    await _client
        .from('profiles')
        .update({
          'role': role,
          'requested_role': requestedRole,
          'is_active': isActive,
          'account_status': accountStatus,
          'verification_status': verificationStatus,
          'owner_status': isOwnerActive ? 'Online' : 'Menunggu aktivasi admin',
          'admin_notes': adminNotes,
        })
        .eq('id', userId);

    await _client
        .from('kos')
        .update({
          'owner_status': isOwnerActive ? 'Online' : 'Menunggu aktivasi admin',
          'status': isOwnerActive
              ? 'active'
              : verificationStatus == 'Perlu Revisi'
              ? 'needs_revision'
              : accountStatus == 'Suspended'
              ? 'suspended'
              : accountStatus == 'Ditolak'
              ? 'hidden'
              : 'pending_review',
        })
        .eq('owner_id', userId);
  }

  Future<void> updateUserModerationStatus({
    required AppUserData user,
    required String accountStatus,
    String? adminNotes,
  }) async {
    await updateUserFromAdmin(
      userId: user.id,
      role: user.role,
      requestedRole: user.requestedRole,
      accountStatus: accountStatus,
      verificationStatus: user.verificationStatus,
      adminNotes: adminNotes,
    );
  }

  Future<void> reviewOwnerApplication({
    required AppUserData owner,
    required String decision,
    String adminNotes = '',
  }) async {
    switch (decision) {
      case 'approve':
        await updateUserFromAdmin(
          userId: owner.id,
          role: 'pemilik',
          requestedRole: 'pemilik',
          accountStatus: 'Aktif',
          verificationStatus: 'Terverifikasi',
          adminNotes: adminNotes,
        );
        await _client
            .from('profiles')
            .update({'activation_payment_status': 'Lunas'})
            .eq('id', owner.id);
        break;
      case 'reject':
        await updateUserFromAdmin(
          userId: owner.id,
          role: 'penyewa',
          requestedRole: 'pemilik',
          accountStatus: 'Ditolak',
          verificationStatus: 'Ditolak',
          adminNotes: adminNotes,
        );
        await _client
            .from('profiles')
            .update({
              'activation_payment_status': owner.hasActivationProof
                  ? 'Ditolak'
                  : owner.activationPaymentStatus,
            })
            .eq('id', owner.id);
        break;
      case 'revision':
        await updateUserFromAdmin(
          userId: owner.id,
          role: 'penyewa',
          requestedRole: 'pemilik',
          accountStatus: 'Menunggu Aktivasi',
          verificationStatus: 'Perlu Revisi',
          adminNotes: adminNotes,
        );
        break;
      case 'suspend':
        await updateUserFromAdmin(
          userId: owner.id,
          role: 'pemilik',
          requestedRole: 'pemilik',
          accountStatus: 'Suspended',
          verificationStatus: 'Suspended',
          adminNotes: adminNotes,
        );
        break;
    }
  }

  Future<void> updateActivationPaymentStatus({
    required String userId,
    required String paymentStatus,
  }) async {
    final verificationStatus = paymentStatus == 'Lunas'
        ? 'Terverifikasi'
        : paymentStatus == 'Menunggu Konfirmasi'
        ? 'Menunggu Verifikasi'
        : paymentStatus == 'Ditolak'
        ? 'Perlu Revisi'
        : 'Menunggu Pembayaran';
    await _client
        .from('profiles')
        .update({
          'activation_payment_status': paymentStatus,
          'verification_status': verificationStatus,
        })
        .eq('id', userId);
  }

  Future<void> updateKosListingStatus({
    required String kosId,
    required String listingStatus,
  }) async {
    await _client.from('kos').update({'status': listingStatus}).eq('id', kosId);
  }

  Future<void> createBooking({
    required KosData kos,
    required String durationLabel,
    required String paymentMethod,
    required DateTime startDate,
    required String startDateLabel,
    required String phoneNumber,
    required String emergencyContact,
    required String roomLabel,
    required String note,
    required String paymentProofUrl,
  }) async {
    final user = SupabaseAuth.instance.currentUser!;
    final profileData = await _profileMap(user.id) ?? const <String, dynamic>{};
    final role = profileData['role'] as String? ?? 'penyewa';

    if (role == 'pemilik' || kos.ownerId == user.id) {
      throw SupabaseAppException(
        plugin: 'supabase',
        code: 'permission-denied',
        message: 'Akun pemilik kos tidak bisa melakukan booking.',
      );
    }

    await _client
        .from('profiles')
        .update({
          'phone_number': phoneNumber,
          'emergency_contact': emergencyContact,
        })
        .eq('id', user.id);

    final durationInMonths = _monthsFromDuration(durationLabel);
    final endDate = _addMonths(startDate, durationInMonths);
    final bookingId = await _client.rpc(
      'create_booking_and_decrement_room',
      params: {
        'p_kos_id': kos.id,
        'p_room_label': roomLabel,
        'p_note': note,
        'p_payment_proof_url': paymentProofUrl,
        'p_start_date': _sqlDate(startDate),
        'p_start_date_label': startDateLabel,
        'p_end_date': _sqlDate(endDate),
        'p_end_date_label': _formatLongDate(endDate),
        'p_duration_label': durationLabel,
        'p_monthly_price': kos.price,
        'p_payment_method': paymentMethod,
        'p_total_price': _totalPrice(kos.price, durationLabel),
      },
    );
    if (kos.approvalMode == 'Auto Approval' && paymentProofUrl.isNotEmpty) {
      await _client
          .from('bookings')
          .update({'status': 'Sudah Dikonfirmasi'})
          .eq('id', bookingId.toString());
    }
  }

  Future<String> createOrGetOwnerChat(BookingData booking) async {
    final row = await _client
        .from('chats')
        .upsert({
          'kos_id': booking.kos.id,
          'owner_name': booking.kos.ownerName,
          'owner_photo': booking.kos.ownerPhoto,
          'owner_id': booking.kos.ownerId,
          'kos_snapshot': booking.kos.toMap(),
          'penyewa_id': booking.userId,
          'penyewa_name': booking.userName,
          'penyewa_photo': booking.userPhoto,
          'participant_ids': [booking.kos.ownerId, booking.userId],
        }, onConflict: 'kos_id,penyewa_id')
        .select('id')
        .single();
    return row['id'].toString();
  }

  Future<void> updateBookingStatus({
    required BookingData booking,
    required String status,
    String? cancelReason,
  }) async {
    final current = await _client
        .from('bookings')
        .select('status')
        .eq('id', booking.id)
        .maybeSingle();
    final previousStatus = current?['status'] as String? ?? booking.status;
    await _client
        .from('bookings')
        .update({'status': status, 'cancel_reason': cancelReason})
        .eq('id', booking.id);

    if (previousStatus != 'Dibatalkan' && status == 'Dibatalkan') {
      await _adjustAvailableRooms(booking.kos.id, 1);
    } else if (previousStatus == 'Dibatalkan' && status != 'Dibatalkan') {
      await _adjustAvailableRooms(booking.kos.id, -1);
    }
  }

  Future<void> updateBookingPaymentStatus({
    required String bookingId,
    required String paymentStatus,
  }) async {
    await _client
        .from('bookings')
        .update({
          'payment_status': paymentStatus,
          'payment_updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', bookingId);
  }

  Future<void> cancelBookingByTenant(BookingData booking) async {
    await updateBookingStatus(
      booking: booking,
      status: 'Dibatalkan',
      cancelReason: 'Dibatalkan oleh penyewa',
    );
  }

  Future<void> addOwnerNote({
    required String bookingId,
    required String note,
  }) async {
    final row = await _client
        .from('bookings')
        .select('owner_notes')
        .eq('id', bookingId)
        .maybeSingle();
    final notes = (row?['owner_notes'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList();
    notes.add(note);
    await _client
        .from('bookings')
        .update({'owner_notes': notes})
        .eq('id', bookingId);
  }

  Future<ReviewData?> fetchBookingReview(String bookingId) async {
    final row = await _client
        .from('kos_reviews')
        .select()
        .eq('booking_id', bookingId)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return ReviewData.fromMap(row['id'].toString(), row);
  }

  Future<void> submitBookingReview({
    required BookingData booking,
    required int rating,
    required String comment,
  }) async {
    final user = SupabaseAuth.instance.currentUser;
    if (user == null) {
      throw SupabaseAppException(
        plugin: 'supabase',
        code: 'unauthenticated',
        message: 'Silakan login ulang untuk mengirim rating.',
      );
    }
    if (booking.userId != user.id) {
      throw SupabaseAppException(
        plugin: 'supabase',
        code: 'permission-denied',
        message: 'Hanya penyewa terkait yang bisa memberi rating booking ini.',
      );
    }
    if (booking.status != 'Selesai') {
      throw SupabaseAppException(
        plugin: 'supabase',
        code: 'unavailable',
        message:
            'Rating baru bisa diberikan setelah masa sewa selesai dan booking masuk riwayat.',
      );
    }
    if (rating < 1 || rating > 5) {
      throw SupabaseAppException(
        plugin: 'supabase',
        code: 'invalid-argument',
        message: 'Pilih rating antara 1 sampai 5 bintang.',
      );
    }

    try {
      await _client.from('kos_reviews').upsert({
        'booking_id': booking.id,
        'kos_id': booking.kos.id,
        'owner_id': booking.kos.ownerId,
        'user_id': booking.userId,
        'user_name': booking.userName,
        'user_photo': booking.userPhoto,
        'rating': rating,
        'comment': comment.trim(),
      }, onConflict: 'booking_id');
    } on supabase.PostgrestException catch (error) {
      throw SupabaseAppException(
        plugin: 'supabase',
        code: error.code ?? 'postgrest-error',
        message: error.message,
      );
    } catch (_) {
      throw SupabaseAppException(
        plugin: 'supabase',
        code: 'submit-review-failed',
        message: 'Ulasan belum berhasil disimpan. Coba lagi.',
      );
    }
  }

  Future<void> extendBooking({
    required BookingData booking,
    required int additionalMonths,
  }) async {
    final newEndDate = _addMonths(booking.endDateValue, additionalMonths);
    final currentMonths = _monthsFromDuration(booking.durationLabel);
    final updatedMonths = currentMonths + additionalMonths;
    await _client
        .from('bookings')
        .update({
          'duration_label': '$updatedMonths bulan',
          'end_date': _sqlDate(newEndDate),
          'end_date_label': _formatLongDate(newEndDate),
          'total_price':
              booking.totalPrice + (booking.monthlyPrice * additionalMonths),
        })
        .eq('id', booking.id);
  }

  Stream<List<BookingData>> _bookingsStream(String? column, String? value) {
    if (column != null && value != null) {
      return _mapBookingRows(
        _client.from('bookings').stream(primaryKey: ['id']).eq(column, value),
      );
    }
    return _mapBookingRows(_client.from('bookings').stream(primaryKey: ['id']));
  }

  Stream<List<BookingData>> _mapBookingRows(
    Stream<List<Map<String, dynamic>>> rowsStream,
  ) {
    return rowsStream
        .map((rows) async {
          final items = await Future.wait(
            rows.map((row) => _bookingFromRow(row)),
          );
          final resolved = items.whereType<BookingData>().toList();
          resolved.sort((a, b) => b.sortKey.compareTo(a.sortKey));
          return resolved;
        })
        .asyncMap((value) => value);
  }

  Future<BookingData?> _bookingFromRow(Map<String, dynamic> row) async {
    final kos = await _resolveKosData(
      kosId: row['kos_id'] as String? ?? '',
      fallbackMap: _asStringMap(row['kos_snapshot']),
    );
    if (kos == null) {
      return null;
    }
    return BookingData.fromMap(id: row['id'].toString(), map: row, kos: kos);
  }

  Future<KosData?> _resolveKosData({
    required String kosId,
    required Map<String, dynamic>? fallbackMap,
  }) async {
    if (fallbackMap != null && fallbackMap.isNotEmpty) {
      return KosData.fromMap(kosId, fallbackMap);
    }

    final row = await _client
        .from('kos')
        .select()
        .eq('id', kosId)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return KosData.fromMap(row['id'].toString(), row);
  }

  Future<OwnerVoucherData?> _findOwnerVoucherByCode(String code) async {
    if (code.trim().isEmpty) {
      return null;
    }
    final row = await _client
        .from('owner_vouchers')
        .select()
        .eq('code', code.trim().toUpperCase())
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return OwnerVoucherData.fromMap(row['id'].toString(), row);
  }

  Future<Map<String, dynamic>?> _profileMap(String userId) async {
    return _client.from('profiles').select().eq('id', userId).maybeSingle();
  }

  Future<void> _adjustAvailableRooms(String kosId, int delta) async {
    final row = await _client
        .from('kos')
        .select('available_rooms')
        .eq('id', kosId)
        .maybeSingle();
    final current = (row?['available_rooms'] as num?)?.toInt() ?? 0;
    await _client
        .from('kos')
        .update({'available_rooms': math.max(0, current + delta)})
        .eq('id', kosId);
  }

  String _sqlDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, entryValue) => MapEntry(key.toString(), entryValue),
      );
    }
    return null;
  }
}
