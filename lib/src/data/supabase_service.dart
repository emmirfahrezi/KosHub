part of '../../main.dart';

class SupabaseService {
  SupabaseService._();

  static final instance = SupabaseService._();
  static const _publicUploadBucket = 'app-uploads';

  supabase.SupabaseClient get _client => supabase.Supabase.instance.client;

  Map<String, dynamic>? _cachedProfileMap;

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
    await prepareSignedInUser(
      user,
      fallbackName: user.displayName ?? email.split('@').first,
    );

    final existing = await _profileMap(user.id);
    final existingRole = existing?['role'] as String? ?? 'penyewa';

    if (!_isAdminRole(existingRole)) {
      await SupabaseAuth.instance.signOut();
      throw SupabaseAppException(
        plugin: 'supabase',
        code: 'permission-denied',
        message: 'Akun ini bukan admin aplikasi Koshub.',
      );
    }
  }

  Future<void> prepareSignedInUser(
    User user, {
    required String fallbackName,
  }) async {
    await ensureUserProfile(user, fallbackName: fallbackName);

    final existing = await _profileMap(user.id);
    final existingRole = existing?['role'] as String? ?? 'penyewa';
    final email = (user.email ?? '').toLowerCase();

    if (!_isAdminRole(existingRole) && _adminSeedEmails.contains(email)) {
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

    if (_isAdminRole(existingRole)) {
      await _client
          .from('profiles')
          .update({
            'login_activity': 'Login ${_formatLongDate(DateTime.now())}',
          })
          .eq('id', user.id);
    }
  }

  Future<void> ensureUserProfile(
    User user, {
    required String fallbackName,
  }) async {
    _cachedProfileMap = null;
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
    final normalizedPhoneNumber = _normalizeIndonesianMobileNumber(
      phoneNumber,
    );
    if (normalizedPhoneNumber == null) {
      throw SupabaseAppException(
        plugin: 'validation',
        code: 'invalid-phone-number',
        message: _indonesianMobileNumberHint('Nomor HP'),
      );
    }

    _cachedProfileMap = null;
    await user.updateProfile(displayName: name, photoUrl: photoUrl);
    if (newPassword != null && newPassword.trim().isNotEmpty) {
      await user.updatePassword(newPassword.trim());
    }

    await _client
        .from('profiles')
        .update({
          'name': name.trim(),
          'email': user.email ?? '-',
          'phone_number': normalizedPhoneNumber,
          'photo_url': photoUrl.trim(),
        })
        .eq('id', user.id);
  }

  Future<Map<String, dynamic>> updateTenantProfileAndReturn({
    required User user,
    required String name,
    required String phoneNumber,
    required String photoUrl,
    String? newPassword,
  }) async {
    final normalizedPhoneNumber = _normalizeIndonesianMobileNumber(
      phoneNumber,
    );
    if (normalizedPhoneNumber == null) {
      throw SupabaseAppException(
        plugin: 'validation',
        code: 'invalid-phone-number',
        message: _indonesianMobileNumberHint('Nomor HP'),
      );
    }

    _cachedProfileMap = null;
    await user.updateProfile(displayName: name, photoUrl: photoUrl);
    if (newPassword != null && newPassword.trim().isNotEmpty) {
      await user.updatePassword(newPassword.trim());
    }

    final result = await _client
        .from('profiles')
        .update({
          'name': name.trim(),
          'email': user.email ?? '-',
          'phone_number': normalizedPhoneNumber,
          'photo_url': photoUrl.trim(),
        })
        .eq('id', user.id)
        .select()
        .single();
    return result;
  }


  Future<void> updateOwnerBankAccount({
    required User user,
    required String bankAccount,
  }) async {
    _cachedProfileMap = null;
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
    required double latitude,
    required double longitude,
    required String googleMapsLink,
    required List<String> facilities,
    required String photoUrl,
    required List<String> photoUrls,
    required String phoneNumber,
    required String ktpNumber,
    required String emergencyContact,
    required String bankAccount,
    required String paymentProofUrl,
    required String voucherCode,
  }) async {
    final normalizedPhoneNumber = _normalizeIndonesianMobileNumber(
      phoneNumber,
    );
    if (normalizedPhoneNumber == null) {
      throw SupabaseAppException(
        plugin: 'validation',
        code: 'invalid-phone-number',
        message: _indonesianMobileNumberHint('Nomor HP'),
      );
    }
    if (emergencyContact.trim().isNotEmpty &&
        !_hasValidIndonesianMobileNumber(emergencyContact)) {
      throw SupabaseAppException(
        plugin: 'validation',
        code: 'invalid-emergency-contact',
        message: _indonesianMobileNumberHint('Kontak darurat'),
      );
    }

    try {
      _cachedProfileMap = null;
      await user.updateDisplayName(ownerName);
      final galleryUrls = photoUrls.isEmpty ? [photoUrl] : photoUrls;
      final existingVoucher = await _resolveOwnerVoucherByCode(voucherCode);
      final activationFee = _ownerActivationBaseFee;
      final voucherDiscount = _ownerActivationDiscountFromVoucher(
        existingVoucher,
        activationFee: activationFee,
      );
      final isFreeActivation = activationFee - voucherDiscount <= 0;
      final activationPaymentMethod = isFreeActivation
          ? 'Voucher ${existingVoucher?.code ?? ''}'.trim()
          : 'Transfer Manual';

      await _client.from('profiles').upsert({
        'id': user.id,
        'name': ownerName,
        'email': user.email ?? '-',
        'role': 'penyewa',
        'requested_role': 'pemilik',
        'is_active': false,
        'photo_url': user.photoURL ?? photoUrl,
        'phone_number': normalizedPhoneNumber,
        'ktp_number': ktpNumber,
        'emergency_contact': emergencyContact.trim(),
        'bank_account': bankAccount,
        'account_status': 'Menunggu Aktivasi',
        'verification_status': isFreeActivation
            ? 'Menunggu Verifikasi'
            : paymentProofUrl.isEmpty
            ? 'Menunggu Pembayaran'
            : 'Menunggu Verifikasi',
        'activation_payment_method': activationPaymentMethod,
        'activation_payment_status': isFreeActivation
            ? 'Lunas'
            : paymentProofUrl.isEmpty
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
        'latitude': latitude,
        'longitude': longitude,
        'google_maps_link': googleMapsLink,
        'foto_urls': galleryUrls,
        'rating': 0,
        'total_review': 0,
        'total_rooms': availableRooms,
        'available_rooms': availableRooms,
        'status': 'pending_review',
      });
    } on supabase.PostgrestException catch (error) {
      throw SupabaseAppException(
        plugin: 'supabase',
        code: error.code ?? 'postgrest-error',
        message: _ownerKosSaveMessage(error),
      );
    } on SupabaseAppException {
      rethrow;
    } catch (_) {
      throw SupabaseAppException(
        plugin: 'supabase',
        code: 'register-owner-kos-failed',
        message: 'Pendaftaran pemilik gagal diproses. Coba lagi.',
      );
    }
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
    required double latitude,
    required double longitude,
    required String googleMapsLink,
    required List<String> facilities,
    required String photoUrl,
    required List<String> photoUrls,
    required String phoneNumber,
    required String ktpNumber,
    required String emergencyContact,
    required String bankAccount,
    required String paymentProofUrl,
    required String voucherCode,
  }) async {
    final normalizedPhoneNumber = _normalizeIndonesianMobileNumber(
      phoneNumber,
    );
    if (phoneNumber.trim().isNotEmpty && normalizedPhoneNumber == null) {
      throw SupabaseAppException(
        plugin: 'validation',
        code: 'invalid-phone-number',
        message: _indonesianMobileNumberHint('Nomor HP'),
      );
    }
    if (emergencyContact.trim().isNotEmpty &&
        !_hasValidIndonesianMobileNumber(emergencyContact)) {
      throw SupabaseAppException(
        plugin: 'validation',
        code: 'invalid-emergency-contact',
        message: _indonesianMobileNumberHint('Kontak darurat'),
      );
    }

    try {
      _cachedProfileMap = null;
      await user.updateDisplayName(ownerName);
      final userData = await _profileMap(user.id) ?? const <String, dynamic>{};
      final galleryUrls = photoUrls.isEmpty ? [photoUrl] : photoUrls;
      final voucher = await _resolveOwnerVoucherByCode(voucherCode);
      final activationFee =
          (userData['owner_activation_fee'] as num?)?.toInt() ??
          _ownerActivationBaseFee;
      final voucherDiscount = voucher == null
          ? math.min(
              (userData['owner_activation_discount'] as num?)?.toInt() ?? 0,
              activationFee,
            )
          : _ownerActivationDiscountFromVoucher(
              voucher,
              activationFee: activationFee,
            );
      final isFreeActivation = activationFee - voucherDiscount <= 0;
      final storedVoucherCode =
          userData['owner_voucher_code'] as String? ?? '';
      final paymentVoucherCode = voucher?.code ?? storedVoucherCode;
      final freeActivationPaymentMethod = paymentVoucherCode.isEmpty
          ? 'Voucher Gratis'
          : 'Voucher $paymentVoucherCode';
      final isApprovedOwner =
          userData['role'] == 'pemilik' &&
          (userData['account_status'] as String? ?? '') == 'Aktif' &&
          (userData['verification_status'] as String? ?? '') ==
              'Terverifikasi';
      final desiredListingStatus = isApprovedOwner
          ? 'active'
          : 'pending_review';

      await _client.from('profiles').upsert({
        'id': user.id,
        'name': ownerName,
        'email': user.email ?? '-',
        'role': isApprovedOwner ? 'pemilik' : 'penyewa',
        'requested_role': 'pemilik',
        'is_active': isApprovedOwner,
        'photo_url': user.photoURL ?? photoUrl,
        'phone_number':
            normalizedPhoneNumber ?? (userData['phone_number'] as String? ?? ''),
        'ktp_number': ktpNumber.isNotEmpty
            ? ktpNumber
            : (userData['ktp_number'] as String? ?? ''),
        'emergency_contact': emergencyContact.isNotEmpty
            ? emergencyContact
            : (userData['emergency_contact'] as String? ?? ''),
        'bank_account': bankAccount.isNotEmpty
            ? bankAccount
            : (userData['bank_account'] as String? ?? ''),
        'account_status': isApprovedOwner ? 'Aktif' : 'Menunggu Aktivasi',
        'verification_status': isApprovedOwner
            ? 'Terverifikasi'
            : (isFreeActivation
                  ? 'Menunggu Verifikasi'
                  : paymentProofUrl.isEmpty
                  ? 'Menunggu Pembayaran'
                  : 'Menunggu Verifikasi'),
        'activation_payment_method': isFreeActivation && !isApprovedOwner
            ? freeActivationPaymentMethod
            : 'Transfer Manual',
        'activation_payment_status': isApprovedOwner
            ? 'Lunas'
            : (isFreeActivation
                  ? 'Lunas'
                  : paymentProofUrl.isEmpty
                  ? 'Belum Bayar'
                  : 'Menunggu Konfirmasi'),
        'activation_payment_proof_url': paymentProofUrl.isNotEmpty
            ? paymentProofUrl
            : (userData['activation_payment_proof_url'] as String? ?? ''),
        'owner_activation_fee': activationFee,
        'owner_activation_discount': voucherDiscount,
        'owner_voucher_code': voucher?.code ?? storedVoucherCode,
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
            'latitude': latitude,
            'longitude': longitude,
            'google_maps_link': googleMapsLink,
            'foto_urls': galleryUrls,
            'total_rooms': availableRooms,
            'available_rooms': availableRooms,
            'status': desiredListingStatus,
          })
          .eq('id', kosId);
    } on supabase.PostgrestException catch (error) {
      throw SupabaseAppException(
        plugin: 'supabase',
        code: error.code ?? 'postgrest-error',
        message: _ownerKosSaveMessage(error),
      );
    } on SupabaseAppException {
      rethrow;
    } catch (_) {
      throw SupabaseAppException(
        plugin: 'supabase',
        code: 'update-owner-kos-failed',
        message: 'Perubahan listing gagal disimpan. Coba lagi.',
      );
    }
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

  String _ownerKosSaveMessage(supabase.PostgrestException error) {
    final message = error.message;
    final details = error.details?.toString() ?? '';
    final hint = error.hint?.toString() ?? '';
    final combined = '$message $details $hint'.toLowerCase();

    if (combined.contains('latitude') ||
        combined.contains('longitude') ||
        combined.contains('google_maps_link')) {
      return 'Kolom lokasi di Supabase belum siap. Jalankan script `supabase/migration_add_location.sql` di SQL Editor Supabase, lalu coba simpan lagi.';
    }

    if (combined.contains('row-level security') ||
        combined.contains('violates row-level security')) {
      return 'Akses simpan listing ditolak oleh policy Supabase. Periksa RLS/policy tabel profiles dan kos.';
    }

    return message.isEmpty ? 'Data listing belum berhasil disimpan.' : message;
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

  Stream<List<ChatPreviewData>> userChatsStream(String userId) async* {
    final profile = await fetchUserProfile(userId);
    final isOwner = profile?.role == 'pemilik';
    final stream = _client
        .from('chats')
        .stream(primaryKey: ['id'])
        .eq(isOwner ? 'owner_id' : 'penyewa_id', userId);

    yield* stream.map((rows) {
      final items = rows.map((row) {
        final kos = KosData.fromMap(
          row['kos_id'] as String? ?? '',
          _asStringMap(row['kos_snapshot']) ?? const {},
        );
        return ChatPreviewData.fromMap(
          id: row['id'].toString(),
          data: row,
          kos: kos,
        );
      }).toList();
      items.sort((a, b) => b.sortKey.compareTo(a.sortKey));
      return items;
    });
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
        .order('created_at', ascending: true)
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
      'last_sender_id': user.id,
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

  Stream<Set<String>> notificationReadKeysStream(String userId) {
    return _client
        .from('notification_reads')
        .stream(primaryKey: ['user_id', 'notification_key'])
        .eq('user_id', userId)
        .map(
          (rows) => rows
              .map((row) => row['notification_key'] as String? ?? '')
              .where((key) => key.isNotEmpty)
              .toSet(),
        );
  }

  Future<void> markNotificationRead(String notificationKey) async {
    final user = SupabaseAuth.instance.currentUser!;
    await _client.from('notification_reads').upsert({
      'user_id': user.id,
      'notification_key': notificationKey,
      'read_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Stream<List<BookingData>> ownerBookingsStream(String ownerId) async* {
    yield await fetchOwnerBookings(ownerId);
    yield* _bookingsStream('owner_id', ownerId);
  }

  Future<List<BookingData>> fetchOwnerBookings(String ownerId) async {
    final rows = await _client
        .from('bookings')
        .select()
        .eq('owner_id', ownerId);
    final items = await Future.wait(rows.map((row) => _bookingFromRow(row)));
    final resolved = items.whereType<BookingData>().toList();
    resolved.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return resolved;
  }

  Stream<List<ReviewData>> ownerReviewsStream(String ownerId) {
    return _client
        .from('kos_reviews')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .map((rows) {
          final reviews = rows
              .map((row) => ReviewData.fromMap(row['id'].toString(), row))
              .toList();
          reviews.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return reviews;
        });
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

  Future<int> ownerActivationDiscountForCode(String code) async {
    final voucher = await _resolveOwnerVoucherByCode(code);
    return _ownerActivationDiscountFromVoucher(voucher);
  }

  Future<OwnerVoucherData?> activeOwnerVoucherForCode(String code) {
    return _resolveOwnerVoucherByCode(code);
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
    required String roomLabel,
    required String note,
    required String paymentProofUrl,
  }) async {
    final normalizedPhoneNumber = _normalizeIndonesianMobileNumber(
      phoneNumber,
    );
    if (normalizedPhoneNumber == null) {
      throw SupabaseAppException(
        plugin: 'validation',
        code: 'invalid-phone-number',
        message: _indonesianMobileNumberHint('Nomor HP'),
      );
    }

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
        .update({'phone_number': normalizedPhoneNumber})
        .eq('id', user.id);

    final durationInMonths = _monthsFromDuration(durationLabel);
    final endDate = _addMonths(startDate, durationInMonths);
    await _client.rpc(
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
    // Auto approval check has been removed per manual-only approval update.
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
    final updated = await _client
        .from('bookings')
        .update({'status': status, 'cancel_reason': cancelReason})
        .eq('id', booking.id)
        .select('id, status')
        .maybeSingle();
    if (updated == null || updated['status'] != status) {
      throw SupabaseAppException(
        plugin: 'supabase',
        code: 'booking-status-not-updated',
        message: 'Status booking belum berhasil diperbarui.',
      );
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
    final normalizedCode = code.trim().toUpperCase();
    final row = await _client
        .from('owner_vouchers')
        .select()
        .ilike('code', normalizedCode)
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();
    if (row == null) {
      return null;
    }
    return OwnerVoucherData.fromMap(row['id'].toString(), row);
  }

  Future<OwnerVoucherData?> _resolveOwnerVoucherByCode(String code) async {
    return await _findOwnerVoucherByCode(code) ??
        _builtInOwnerActivationVoucherForCode(code);
  }

  Future<Map<String, dynamic>?> _profileMap(String userId) async {
    final currentUser = SupabaseAuth.instance.currentUser;
    if (currentUser != null && userId == currentUser.id && _cachedProfileMap != null) {
      return _cachedProfileMap;
    }
    final map = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    if (currentUser != null && userId == currentUser.id) {
      _cachedProfileMap = map;
    }
    return map;
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
