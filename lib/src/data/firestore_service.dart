part of '../../main.dart';

class FirestoreService {
  FirestoreService._();

  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _kos => _db.collection('kos');
  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');
  CollectionReference<Map<String, dynamic>> get _homeBanners =>
      _db.collection('cms_home_banners');
  CollectionReference<Map<String, dynamic>> get _ownerVouchers =>
      _db.collection('owner_vouchers');

  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    final userRef = _users.doc(user.uid);
    final snapshot = await userRef.get();
    final existing = snapshot.data() ?? const <String, dynamic>{};
    final existingRole = existing['role'] as String? ?? 'penyewa';
    final canSeedAdmin = _adminSeedEmails.contains(email.toLowerCase());

    if (!_isAdminRole(existingRole) && canSeedAdmin) {
      await userRef.set({
        'name':
            existing['name'] as String? ?? user.displayName ?? 'Admin Koshub',
        'email': user.email,
        'role': 'super_admin',
        'is_active': true,
        'account_status': 'Aktif',
        'verification_status': 'Terverifikasi',
        'login_activity': 'Login ${_formatLongDate(DateTime.now())}',
        'updated_at': FieldValue.serverTimestamp(),
        'created_at': existing['created_at'] ?? FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    if (!_isAdminRole(existingRole)) {
      await FirebaseAuth.instance.signOut();
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Akun ini bukan admin aplikasi Koshub.',
      );
    }

    await userRef.set({
      'login_activity': 'Login ${_formatLongDate(DateTime.now())}',
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> ensureUserProfile(
    User user, {
    required String fallbackName,
  }) async {
    final userRef = _users.doc(user.uid);
    final existingSnapshot = await userRef.get();
    final existingData = existingSnapshot.data();

    await userRef.set({
      'name': user.displayName ?? fallbackName,
      'email': user.email,
      'role': existingData?['role'] as String? ?? 'penyewa',
      'is_active': existingData?['is_active'] as bool? ?? true,
      'photo_url': user.photoURL,
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
      'created_at': existingData == null
          ? FieldValue.serverTimestamp()
          : existingData['created_at'],
    }, SetOptions(merge: true));
  }

  Future<void> updateTenantProfile({
    required User user,
    required String name,
    required String phoneNumber,
    required String photoUrl,
    String? newPassword,
  }) async {
    if (name.trim().isNotEmpty) {
      await user.updateDisplayName(name.trim());
    }
    if (newPassword != null && newPassword.trim().isNotEmpty) {
      await user.updatePassword(newPassword.trim());
    }

    await _users.doc(user.uid).set({
      'name': name.trim(),
      'email': user.email,
      'phone_number': phoneNumber.trim(),
      'photo_url': photoUrl.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    final batch = _db.batch();
    final userRef = _users.doc(user.uid);
    final userSnapshot = await userRef.get();
    final existingUserData = userSnapshot.data() ?? const <String, dynamic>{};
    final kosRef = _kos.doc();

    batch.set(userRef, {
      'name': ownerName,
      'email': user.email,
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
      'owner_application_submitted_at': FieldValue.serverTimestamp(),
      'admin_notes': '',
      'owner_status': 'Menunggu aktivasi admin',
      'updated_at': FieldValue.serverTimestamp(),
      'created_at':
          existingUserData['created_at'] ?? FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(kosRef, {
      'owner_id': user.uid,
      'owner_name': ownerName,
      'owner_status': 'Menunggu aktivasi admin',
      'owner_photo': user.photoURL ?? photoUrl,
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
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
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
    final userSnapshot = await _users.doc(user.uid).get();
    final userData = userSnapshot.data() ?? const <String, dynamic>{};
    final voucher = await _findOwnerVoucherByCode(voucherCode);
    final isApprovedOwner =
        userData['role'] == 'pemilik' &&
        (userData['account_status'] as String? ?? '') == 'Aktif' &&
        (userData['verification_status'] as String? ?? '') == 'Terverifikasi';
    final desiredListingStatus = isApprovedOwner ? 'active' : 'pending_review';
    final batch = _db.batch();
    final userRef = _users.doc(user.uid);
    final kosRef = _kos.doc(kosId);

    batch.set(userRef, {
      'name': ownerName,
      'email': user.email,
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
          FieldValue.serverTimestamp(),
      'owner_status': isApprovedOwner ? 'Online' : 'Menunggu aktivasi admin',
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(kosRef, {
      'owner_id': user.uid,
      'owner_name': ownerName,
      'owner_status': isApprovedOwner ? 'Online' : 'Menunggu aktivasi admin',
      'owner_photo': user.photoURL ?? photoUrl,
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
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<AppUserData?> userProfileStream(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return AppUserData.fromMap(uid, data);
    });
  }

  Stream<KosData?> ownerKosStream(String ownerId) {
    return _kos
        .where('owner_id', isEqualTo: ownerId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => KosData.fromMap(doc.id, doc.data()))
              .toList();
          items.sort((a, b) => a.name.compareTo(b.name));
          return items.isEmpty ? null : items.first;
        });
  }

  Stream<KosData?> ownerManagedKosStream(String ownerId) {
    return _kos.where('owner_id', isEqualTo: ownerId).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs
          .map((doc) => KosData.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => b.id.compareTo(a.id));
      return items.isEmpty ? null : items.first;
    });
  }

  Stream<List<KosData>> kosStream() {
    return _kos.where('status', isEqualTo: 'active').snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs
          .map((doc) => KosData.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => a.name.compareTo(b.name));
      return items;
    });
  }

  Future<void> seedSampleData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
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
    final userRef = _users.doc(user.uid);
    final kosMenteng = _kos.doc('demo-${user.uid}-menteng');
    final kosKemang = _kos.doc('demo-${user.uid}-kemang');

    await Future.wait([
      userRef.set({
        'name': ownerName,
        'email': user.email,
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
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
      kosMenteng.set(
        _sampleKosMap1.forOwner(
          ownerId: user.uid,
          ownerName: ownerName,
          ownerPhoto: ownerPhoto,
        ),
      ),
      kosKemang.set(
        _sampleKosMap2.forOwner(
          ownerId: user.uid,
          ownerName: ownerName,
          ownerPhoto: ownerPhoto,
        ),
      ),
    ]);
  }

  Future<String> createOrGetChat(KosData kos) async {
    final user = FirebaseAuth.instance.currentUser!;
    final profileSnapshot = await _users.doc(user.uid).get();
    final profile = profileSnapshot.data() ?? const <String, dynamic>{};
    final penyewaName =
        profile['name'] as String? ??
        user.displayName ??
        user.email?.split('@').first ??
        'Penyewa';
    final penyewaPhoto = profile['photo_url'] as String? ?? user.photoURL ?? '';
    final chatRef = _chatDoc(kosId: kos.id, penyewaId: user.uid);
    await chatRef.set({
      'kos_id': kos.id,
      'kos_name': kos.name,
      'owner_name': kos.ownerName,
      'owner_photo': kos.ownerPhoto,
      'owner_id': kos.ownerId,
      'kos_snapshot': kos.toMap(),
      'penyewa_id': user.uid,
      'penyewa_name': penyewaName,
      'penyewa_photo': penyewaPhoto,
      'participant_ids': [user.uid, kos.ownerId],
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return chatRef.id;
  }

  Stream<List<ChatPreviewData>> userChatsStream(String userId) {
    return _chats
        .where('participant_ids', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final items = await Future.wait(
            snapshot.docs.map((doc) async {
              final data = doc.data();
              final kos = await _resolveKosData(
                kosId: data['kos_id'] as String? ?? '',
                fallbackMap: _asStringMap(data['kos_snapshot']),
              );
              if (kos == null) {
                return null;
              }
              return ChatPreviewData.fromMap(id: doc.id, data: data, kos: kos);
            }),
          );
          final resolved = items.whereType<ChatPreviewData>().toList();
          resolved.sort((a, b) => b.sortKey.compareTo(a.sortKey));
          return resolved;
        });
  }

  Stream<ChatPreviewData?> chatPreviewStream({
    required String chatId,
    required KosData fallbackKos,
  }) {
    return _chats.doc(chatId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return ChatPreviewData.fromMap(
        id: snapshot.id,
        data: data,
        kos: fallbackKos,
      );
    });
  }

  Stream<List<ChatMessageData>> messagesStream(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessageData.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
    required KosData kos,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final profileSnapshot = await _users.doc(user.uid).get();
    final profile = profileSnapshot.data() ?? const <String, dynamic>{};
    final senderName =
        profile['name'] as String? ??
        user.displayName ??
        user.email?.split('@').first ??
        'Pengguna';
    final senderPhoto = profile['photo_url'] as String? ?? user.photoURL ?? '';
    final isPenyewa = user.uid != kos.ownerId;
    final chatMetadata = <String, dynamic>{
      'last_message': text,
      'last_message_time': FieldValue.serverTimestamp(),
      'last_sender_id': user.uid,
      'last_sender_name': senderName,
      'last_sender_photo': senderPhoto,
    };

    if (isPenyewa) {
      chatMetadata.addAll({
        'penyewa_id': user.uid,
        'penyewa_name': senderName,
        'penyewa_photo': senderPhoto,
      });
    }

    await _chats.doc(chatId).collection('messages').add({
      'sender_id': user.uid,
      'sender_name': senderName,
      'sender_photo': senderPhoto,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _chats.doc(chatId).set(chatMetadata, SetOptions(merge: true));
  }

  Stream<List<BookingData>> userBookingsStream(String userId) {
    return _bookings.where('user_id', isEqualTo: userId).snapshots().asyncMap((
      snapshot,
    ) async {
      final items = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data();
          final kos = await _resolveKosData(
            kosId: data['kos_id'] as String? ?? '',
            fallbackMap: _asStringMap(data['kos_snapshot']),
          );
          if (kos == null) {
            return null;
          }
          return BookingData.fromMap(id: doc.id, map: data, kos: kos);
        }),
      );
      final resolved = items.whereType<BookingData>().toList();
      resolved.sort((a, b) => b.sortKey.compareTo(a.sortKey));
      return resolved;
    });
  }

  Stream<List<BookingData>> ownerBookingsStream(String ownerId) {
    return _bookings.where('owner_id', isEqualTo: ownerId).snapshots().asyncMap(
      (snapshot) async {
        final items = await Future.wait(
          snapshot.docs.map((doc) async {
            final data = doc.data();
            final kos = await _resolveKosData(
              kosId: data['kos_id'] as String? ?? '',
              fallbackMap: _asStringMap(data['kos_snapshot']),
            );
            if (kos == null) {
              return null;
            }
            return BookingData.fromMap(id: doc.id, map: data, kos: kos);
          }),
        );
        final resolved = items.whereType<BookingData>().toList();
        resolved.sort((a, b) => b.sortKey.compareTo(a.sortKey));
        return resolved;
      },
    );
  }

  Stream<List<AppUserData>> allUsersStream() {
    return _users.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => AppUserData.fromMap(doc.id, doc.data()))
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
    return _kos.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => KosData.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => a.name.compareTo(b.name));
      return items;
    });
  }

  Stream<List<BookingData>> allBookingsStream() {
    return _bookings.snapshots().asyncMap((snapshot) async {
      final items = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data();
          final kos = await _resolveKosData(
            kosId: data['kos_id'] as String? ?? '',
            fallbackMap: _asStringMap(data['kos_snapshot']),
          );
          if (kos == null) {
            return null;
          }
          return BookingData.fromMap(id: doc.id, map: data, kos: kos);
        }),
      );
      final resolved = items.whereType<BookingData>().toList();
      resolved.sort((a, b) => b.sortKey.compareTo(a.sortKey));
      return resolved;
    });
  }

  Stream<AdminDashboardData> adminDashboardStream() {
    return _users.snapshots().asyncMap((userSnapshot) async {
      final kosSnapshot = await _kos.get();
      final bookingSnapshot = await _bookings.get();

      final users = userSnapshot.docs
          .map((doc) => AppUserData.fromMap(doc.id, doc.data()))
          .toList();
      final kosList = kosSnapshot.docs
          .map((doc) => KosData.fromMap(doc.id, doc.data()))
          .toList();
      final bookings = await Future.wait(
        bookingSnapshot.docs.map((doc) async {
          final data = doc.data();
          final kos = await _resolveKosData(
            kosId: data['kos_id'] as String? ?? '',
            fallbackMap: _asStringMap(data['kos_snapshot']),
          );
          if (kos == null) {
            return null;
          }
          return BookingData.fromMap(id: doc.id, map: data, kos: kos);
        }),
      );

      return AdminDashboardData.fromCollections(
        users: users,
        kosList: kosList,
        bookings: bookings.whereType<BookingData>().toList(),
      );
    });
  }

  Stream<List<HomeBannerData>> homeBannersStream() {
    return _homeBanners.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => HomeBannerData.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Stream<List<OwnerVoucherData>> ownerVouchersStream() {
    return _ownerVouchers.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => OwnerVoucherData.fromMap(doc.id, doc.data()))
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
    final doc = bannerId == null || bannerId.isEmpty
        ? _homeBanners.doc()
        : _homeBanners.doc(bannerId);
    final existing = bannerId == null || bannerId.isEmpty
        ? null
        : await doc.get();
    await doc.set({
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'placement': placement,
      'is_active': isActive,
      'updated_at': FieldValue.serverTimestamp(),
      'created_at':
          existing?.data()?['created_at'] ?? FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteHomeBanner(String bannerId) async {
    await _homeBanners.doc(bannerId).delete();
  }

  Future<void> saveOwnerVoucher({
    String? voucherId,
    required String code,
    required String title,
    required String description,
    required int discountAmount,
    required bool isActive,
  }) async {
    final doc = voucherId == null || voucherId.isEmpty
        ? _ownerVouchers.doc()
        : _ownerVouchers.doc(voucherId);
    final existing = voucherId == null || voucherId.isEmpty
        ? null
        : await doc.get();
    await doc.set({
      'code': code.toUpperCase(),
      'title': title,
      'description': description,
      'discount_amount': discountAmount,
      'is_active': isActive,
      'updated_at': FieldValue.serverTimestamp(),
      'created_at':
          existing?.data()?['created_at'] ?? FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteOwnerVoucher(String voucherId) async {
    await _ownerVouchers.doc(voucherId).delete();
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
    await _users.doc(userId).set({
      'role': role,
      'requested_role': requestedRole,
      'is_active': isActive,
      'account_status': accountStatus,
      'verification_status': verificationStatus,
      'owner_status': isOwnerActive ? 'Online' : 'Menunggu aktivasi admin',
      'admin_notes': adminNotes,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final kosDocs = await _kos.where('owner_id', isEqualTo: userId).get();
    for (final doc in kosDocs.docs) {
      await doc.reference.set({
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
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
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
        await _users.doc(owner.id).set({
          'activation_payment_status': 'Lunas',
          'owner_activated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
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
        await _users.doc(owner.id).set({
          'activation_payment_status': owner.hasActivationProof
              ? 'Ditolak'
              : owner.activationPaymentStatus,
        }, SetOptions(merge: true));
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
    await _users.doc(userId).set({
      'activation_payment_status': paymentStatus,
      'verification_status': verificationStatus,
      'payment_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateKosListingStatus({
    required String kosId,
    required String listingStatus,
  }) async {
    await _kos.doc(kosId).set({
      'status': listingStatus,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    final user = FirebaseAuth.instance.currentUser!;
    final userProfile = await _users.doc(user.uid).get();
    final profileData = userProfile.data() ?? const <String, dynamic>{};
    final role = profileData['role'] as String? ?? 'penyewa';

    if (role == 'pemilik' || kos.ownerId == user.uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Akun pemilik kos tidak bisa melakukan booking.',
      );
    }

    final bookingStatus =
        kos.approvalMode == 'Auto Approval' && paymentProofUrl.isNotEmpty
        ? 'Sudah Dikonfirmasi'
        : 'Menunggu Konfirmasi';
    final paymentStatus = paymentProofUrl.isNotEmpty
        ? 'Pending'
        : 'Belum Bayar';
    final durationInMonths = _monthsFromDuration(durationLabel);
    final endDate = _addMonths(startDate, durationInMonths);

    await _bookings.add({
      'user_id': user.uid,
      'user_name':
          profileData['name'] as String? ??
          user.displayName ??
          user.email?.split('@').first ??
          'Penyewa',
      'user_email': user.email,
      'user_phone': phoneNumber,
      'user_photo': user.photoURL,
      'emergency_contact': emergencyContact,
      'owner_id': kos.ownerId,
      'kos_id': kos.id,
      'kos_snapshot': kos.toMap(),
      'room_label': roomLabel,
      'note': note,
      'payment_proof_url': paymentProofUrl,
      'start_date': Timestamp.fromDate(startDate),
      'start_date_label': startDateLabel,
      'end_date': Timestamp.fromDate(endDate),
      'end_date_label': _formatLongDate(endDate),
      'duration_label': durationLabel,
      'monthly_price': kos.price,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'status': bookingStatus,
      'approval_mode': kos.approvalMode,
      'total_price': _totalPrice(kos.price, durationLabel),
      'created_day_key': _dayKey(DateTime.now()),
      'created_at': FieldValue.serverTimestamp(),
      'status_updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<String> createOrGetOwnerChat(BookingData booking) async {
    final chatRef = _chatDoc(kosId: booking.kos.id, penyewaId: booking.userId);
    await chatRef.set({
      'kos_id': booking.kos.id,
      'kos_name': booking.kos.name,
      'owner_name': booking.kos.ownerName,
      'owner_photo': booking.kos.ownerPhoto,
      'owner_id': booking.kos.ownerId,
      'kos_snapshot': booking.kos.toMap(),
      'penyewa_id': booking.userId,
      'penyewa_name': booking.userName,
      'penyewa_photo': booking.userPhoto,
      'participant_ids': [booking.kos.ownerId, booking.userId],
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return chatRef.id;
  }

  DocumentReference<Map<String, dynamic>> _chatDoc({
    required String kosId,
    required String penyewaId,
  }) {
    return _chats.doc('${kosId}_$penyewaId');
  }

  Future<void> updateBookingStatus({
    required BookingData booking,
    required String status,
    String? cancelReason,
  }) async {
    final bookingRef = _bookings.doc(booking.id);
    final kosRef = _kos.doc(booking.kos.id);

    await _db.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);
      final kosSnapshot = await transaction.get(kosRef);
      final bookingData = bookingSnapshot.data();
      final kosData = kosSnapshot.data();

      if (bookingData == null || kosData == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Data booking atau kos tidak ditemukan.',
        );
      }

      final previousStatus = bookingData['status'] as String? ?? '';
      var availableRooms = (kosData['available_rooms'] as num?)?.toInt() ?? 0;
      final wasCheckedIn = previousStatus == 'Sudah Check-in';
      final willCheckIn = status == 'Sudah Check-in';

      if (!wasCheckedIn && willCheckIn) {
        availableRooms = math.max(0, availableRooms - 1);
      } else if (wasCheckedIn && !willCheckIn) {
        availableRooms += 1;
      }

      final updateData = <String, dynamic>{
        'status': status,
        'cancel_reason': cancelReason,
        'status_updated_at': FieldValue.serverTimestamp(),
      };
      if (status == 'Sudah Dikonfirmasi') {
        updateData['confirmed_at'] = FieldValue.serverTimestamp();
      }
      if (status == 'Sudah Check-in') {
        updateData['check_in_at'] = FieldValue.serverTimestamp();
      }
      if (status == 'Selesai') {
        updateData['completed_at'] = FieldValue.serverTimestamp();
      }
      if (status == 'Dibatalkan') {
        updateData['cancelled_at'] = FieldValue.serverTimestamp();
      }

      transaction.update(bookingRef, updateData);
      transaction.update(kosRef, {
        'available_rooms': availableRooms,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateBookingPaymentStatus({
    required String bookingId,
    required String paymentStatus,
  }) async {
    await _bookings.doc(bookingId).set({
      'payment_status': paymentStatus,
      'payment_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> cancelBookingByTenant(BookingData booking) async {
    await _bookings.doc(booking.id).set({
      'status': 'Dibatalkan',
      'cancel_reason': 'Dibatalkan oleh penyewa',
      'status_updated_at': FieldValue.serverTimestamp(),
      'cancelled_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addOwnerNote({
    required String bookingId,
    required String note,
  }) async {
    await _bookings.doc(bookingId).set({
      'owner_notes': FieldValue.arrayUnion([note]),
      'owner_note_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> extendBooking({
    required BookingData booking,
    required int additionalMonths,
  }) async {
    final newEndDate = _addMonths(booking.endDateValue, additionalMonths);
    final currentMonths = _monthsFromDuration(booking.durationLabel);
    final updatedMonths = currentMonths + additionalMonths;
    await _bookings.doc(booking.id).set({
      'duration_label': '$updatedMonths bulan',
      'end_date': Timestamp.fromDate(newEndDate),
      'end_date_label': _formatLongDate(newEndDate),
      'total_price':
          booking.totalPrice + (booking.monthlyPrice * additionalMonths),
      'status_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<KosData?> _resolveKosData({
    required String kosId,
    required Map<String, dynamic>? fallbackMap,
  }) async {
    if (fallbackMap != null) {
      return KosData.fromMap(kosId, fallbackMap);
    }

    final kosDoc = await _kos.doc(kosId).get();
    if (!kosDoc.exists || kosDoc.data() == null) {
      return null;
    }

    return KosData.fromMap(kosDoc.id, kosDoc.data()!);
  }

  Future<OwnerVoucherData?> _findOwnerVoucherByCode(String code) async {
    if (code.trim().isEmpty) {
      return null;
    }
    final snapshot = await _ownerVouchers
        .where('code', isEqualTo: code.trim().toUpperCase())
        .where('is_active', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    final doc = snapshot.docs.first;
    return OwnerVoucherData.fromMap(doc.id, doc.data());
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
