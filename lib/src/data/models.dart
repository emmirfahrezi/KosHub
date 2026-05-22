part of '../../main.dart';

class KosData {
  const KosData({
    required this.id,
    required this.name,
    required this.area,
    required this.address,
    required this.price,
    required this.rating,
    required this.reviewCount,
    required this.category,
    required this.totalRooms,
    required this.availableRooms,
    required this.description,
    required this.facilities,
    required this.gallery,
    required this.approvalMode,
    required this.ownerId,
    required this.ownerName,
    required this.ownerStatus,
    required this.ownerPhoto,
    required this.listingStatus,
  });

  final String id;
  final String name;
  final String area;
  final String address;
  final int price;
  final double rating;
  final int reviewCount;
  final String category;
  final int totalRooms;
  final int availableRooms;
  final String description;
  final List<String> facilities;
  final List<String> gallery;
  final String approvalMode;
  final String ownerId;
  final String ownerName;
  final String ownerStatus;
  final String ownerPhoto;
  final String listingStatus;

  bool get isPublished => listingStatus == 'active';

  String get listingStatusLabel {
    switch (listingStatus) {
      case 'pending_review':
        return 'Menunggu Review';
      case 'needs_revision':
        return 'Perlu Revisi';
      case 'hidden':
        return 'Disembunyikan';
      case 'suspended':
        return 'Suspended';
      default:
        return 'Aktif';
    }
  }

  factory KosData.fromMap(String id, Map<String, dynamic> map) {
    return KosData(
      id: id,
      name: map['nama_kos'] as String? ?? '-',
      area: map['area'] as String? ?? '-',
      address: map['alamat'] as String? ?? '-',
      price: (map['harga_mulai'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['total_review'] as num?)?.toInt() ?? 0,
      category: map['gender'] as String? ?? '-',
      totalRooms:
          (map['total_rooms'] as num?)?.toInt() ??
          (map['available_rooms'] as num?)?.toInt() ??
          0,
      availableRooms: (map['available_rooms'] as num?)?.toInt() ?? 0,
      description: map['deskripsi'] as String? ?? '-',
      facilities: (map['fasilitas'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      gallery: (map['foto_urls'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      approvalMode: map['approval_mode'] as String? ?? 'Manual Approval',
      ownerId: map['owner_id'] as String? ?? '',
      ownerName: map['owner_name'] as String? ?? 'Pemilik Kos',
      ownerStatus: map['owner_status'] as String? ?? 'Online',
      ownerPhoto: map['owner_photo'] as String? ?? '',
      listingStatus: map['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': ownerId,
      'owner_name': ownerName,
      'owner_status': ownerStatus,
      'owner_photo': ownerPhoto,
      'nama_kos': name,
      'area': area,
      'alamat': address,
      'deskripsi': description,
      'harga_mulai': price,
      'fasilitas': facilities,
      'gender': category,
      'approval_mode': approvalMode,
      'foto_urls': gallery,
      'rating': rating,
      'total_review': reviewCount,
      'total_rooms': totalRooms,
      'available_rooms': availableRooms,
      'status': listingStatus,
    };
  }
}

class AppUserData {
  const AppUserData({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.photoUrl,
    required this.phoneNumber,
    required this.ktpNumber,
    required this.emergencyContact,
    required this.accountStatus,
    required this.verificationStatus,
    required this.bankAccountLabel,
    required this.loginActivity,
    required this.createdAt,
    required this.isActive,
    required this.requestedRole,
    required this.activationPaymentStatus,
    required this.activationPaymentProofUrl,
    required this.activationPaymentMethod,
    required this.ownerActivationFee,
    required this.ownerActivationDiscount,
    required this.ownerVoucherCode,
    required this.ownerApplicationSubmittedAt,
    required this.adminNotes,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String photoUrl;
  final String phoneNumber;
  final String ktpNumber;
  final String emergencyContact;
  final String accountStatus;
  final String verificationStatus;
  final String bankAccountLabel;
  final String loginActivity;
  final DateTime createdAt;
  final bool isActive;
  final String requestedRole;
  final String activationPaymentStatus;
  final String activationPaymentProofUrl;
  final String activationPaymentMethod;
  final int ownerActivationFee;
  final int ownerActivationDiscount;
  final String ownerVoucherCode;
  final DateTime? ownerApplicationSubmittedAt;
  final String adminNotes;

  bool get isAdmin => _isAdminRole(role);
  bool get hasOwnerRequest => role == 'pemilik' || requestedRole == 'pemilik';
  bool get canAccessOwnerShell =>
      role == 'pemilik' &&
      isActive &&
      accountStatus == 'Aktif' &&
      verificationStatus == 'Terverifikasi';
  bool get hasActivationProof => activationPaymentProofUrl.trim().isNotEmpty;
  int get ownerNetActivationFee =>
      math.max(0, ownerActivationFee - ownerActivationDiscount);

  String get roleLabel {
    if (role != 'pemilik' && requestedRole == 'pemilik') {
      return 'Calon Pemilik Kos';
    }
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'moderator':
        return 'Moderator';
      case 'finance_admin':
        return 'Finance Admin';
      case 'customer_service':
        return 'Customer Service';
      case 'pemilik':
        return 'Pemilik Kos';
      default:
        return 'Penyewa';
    }
  }

  DateTime get sortKey => createdAt;

  factory AppUserData.fromMap(String id, Map<String, dynamic> map) {
    return AppUserData(
      id: id,
      name: map['name'] as String? ?? '-',
      email: map['email'] as String? ?? '-',
      role: map['role'] as String? ?? 'penyewa',
      photoUrl: map['photo_url'] as String? ?? '',
      phoneNumber: map['phone_number'] as String? ?? '-',
      ktpNumber: map['ktp_number'] as String? ?? '-',
      emergencyContact: map['emergency_contact'] as String? ?? '-',
      accountStatus: map['account_status'] as String? ?? 'Aktif',
      verificationStatus: map['verification_status'] as String? ?? 'Pending',
      bankAccountLabel: map['bank_account'] as String? ?? 'Belum diisi',
      loginActivity:
          map['login_activity'] as String? ?? 'Belum ada login tercatat',
      createdAt:
          (map['created_at'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isActive: map['is_active'] as bool? ?? true,
      requestedRole: map['requested_role'] as String? ?? '',
      activationPaymentStatus:
          map['activation_payment_status'] as String? ?? 'Belum Bayar',
      activationPaymentProofUrl:
          map['activation_payment_proof_url'] as String? ?? '',
      activationPaymentMethod:
          map['activation_payment_method'] as String? ?? 'Transfer Manual',
      ownerActivationFee:
          (map['owner_activation_fee'] as num?)?.toInt() ??
          _ownerActivationBaseFee,
      ownerActivationDiscount:
          (map['owner_activation_discount'] as num?)?.toInt() ?? 0,
      ownerVoucherCode: map['owner_voucher_code'] as String? ?? '',
      ownerApplicationSubmittedAt:
          (map['owner_application_submitted_at'] as Timestamp?)?.toDate(),
      adminNotes: map['admin_notes'] as String? ?? '',
    );
  }
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.totalUsers,
    required this.totalOwners,
    required this.totalKos,
    required this.activeRooms,
    required this.ownerRequestsToday,
    required this.platformRevenue,
    required this.pendingOwnerPayments,
    required this.pendingOwnerVerifications,
    required this.blockedUsers,
    required this.pendingListings,
    required this.recentActivities,
    required this.latestOwnerSummary,
    required this.topListingSummary,
    required this.latestPaymentSummary,
  });

  final int totalUsers;
  final int totalOwners;
  final int totalKos;
  final int activeRooms;
  final int ownerRequestsToday;
  final int platformRevenue;
  final int pendingOwnerPayments;
  final int pendingOwnerVerifications;
  final int blockedUsers;
  final int pendingListings;
  final List<AdminActivityItem> recentActivities;
  final String latestOwnerSummary;
  final String topListingSummary;
  final String latestPaymentSummary;

  factory AdminDashboardData.empty() {
    return const AdminDashboardData(
      totalUsers: 0,
      totalOwners: 0,
      totalKos: 0,
      activeRooms: 0,
      ownerRequestsToday: 0,
      platformRevenue: 0,
      pendingOwnerPayments: 0,
      pendingOwnerVerifications: 0,
      blockedUsers: 0,
      pendingListings: 0,
      recentActivities: [],
      latestOwnerSummary: 'Belum ada data pemilik terbaru.',
      topListingSummary: 'Belum ada listing aktif.',
      latestPaymentSummary: 'Belum ada pembayaran aktivasi owner.',
    );
  }

  factory AdminDashboardData.fromCollections({
    required List<AppUserData> users,
    required List<KosData> kosList,
    required List<BookingData> bookings,
  }) {
    final today = _dayKey(DateTime.now());
    final owners = users
        .where(
          (user) =>
              user.role == 'pemilik' &&
              user.accountStatus == 'Aktif' &&
              user.verificationStatus == 'Terverifikasi',
        )
        .toList();
    final ownerApplicants = users
        .where((user) => user.hasOwnerRequest)
        .toList();
    owners.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    final activeRooms = kosList.fold<int>(
      0,
      (total, kos) => total + (kos.totalRooms - kos.availableRooms),
    );
    final ownerRequestsToday = ownerApplicants.where((user) {
      final submittedAt = user.ownerApplicationSubmittedAt;
      return submittedAt != null && _dayKey(submittedAt) == today;
    }).length;
    final platformRevenue = ownerApplicants
        .where((user) => user.activationPaymentStatus == 'Lunas')
        .fold<int>(0, (total, user) => total + user.ownerNetActivationFee);
    final pendingOwnerPayments = ownerApplicants
        .where((user) => user.activationPaymentStatus == 'Menunggu Konfirmasi')
        .length;
    final pendingOwnerVerifications = ownerApplicants
        .where((user) => user.verificationStatus == 'Menunggu Verifikasi')
        .length;
    final blockedUsers = users
        .where(
          (user) =>
              user.accountStatus == 'Diblokir' ||
              user.accountStatus == 'Suspended',
        )
        .length;
    final pendingListings = kosList
        .where((kos) => kos.listingStatus != 'active')
        .length;

    final bookingCounts = <String, int>{};
    for (final booking in bookings.where(
      (item) => item.status != 'Dibatalkan',
    )) {
      bookingCounts.update(
        booking.kos.name,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    String topListingSummary = 'Belum ada listing aktif.';
    if (bookingCounts.isNotEmpty) {
      final top = bookingCounts.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      topListingSummary = '${top.key} | ${top.value} booking';
    }

    final recentActivities = ownerApplicants.take(5).map((owner) {
      return AdminActivityItem(
        title: '${owner.name} mengajukan akun pemilik',
        subtitle:
            '${owner.activationPaymentStatus} | ${owner.verificationStatus}',
        timeLabel: _formatTime(
          owner.ownerApplicationSubmittedAt ?? owner.createdAt,
        ),
        icon: Icons.badge_rounded,
      );
    }).toList();

    if (recentActivities.length < 5) {
      recentActivities.addAll(
        kosList
            .take(5 - recentActivities.length)
            .map(
              (kos) => AdminActivityItem(
                title: '${kos.name} di ${kos.area}',
                subtitle: '${kos.ownerName} | ${kos.listingStatusLabel}',
                timeLabel: _formatTime(DateTime.now()),
                icon: Icons.apartment_rounded,
              ),
            ),
      );
    }

    final latestPayment = ownerApplicants
      ..sort((a, b) {
        final aDate = a.ownerApplicationSubmittedAt ?? a.createdAt;
        final bDate = b.ownerApplicationSubmittedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });

    return AdminDashboardData(
      totalUsers: users.where((user) => !user.isAdmin).length,
      totalOwners: owners.length,
      totalKos: kosList.length,
      activeRooms: activeRooms,
      ownerRequestsToday: ownerRequestsToday,
      platformRevenue: platformRevenue,
      pendingOwnerPayments: pendingOwnerPayments,
      pendingOwnerVerifications: pendingOwnerVerifications,
      blockedUsers: blockedUsers,
      pendingListings: pendingListings,
      recentActivities: recentActivities,
      latestOwnerSummary: ownerApplicants.isEmpty
          ? 'Belum ada owner baru.'
          : '${ownerApplicants.first.name} | ${ownerApplicants.first.verificationStatus}',
      topListingSummary: topListingSummary,
      latestPaymentSummary: latestPayment.isEmpty
          ? 'Belum ada pembayaran aktivasi owner.'
          : '${latestPayment.first.name} | ${latestPayment.first.activationPaymentStatus}',
    );
  }
}

class AdminActivityItem {
  const AdminActivityItem({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final IconData icon;
}

class ChatPreviewData {
  const ChatPreviewData({
    required this.id,
    required this.kos,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhoto,
    required this.penyewaId,
    required this.penyewaName,
    required this.penyewaPhoto,
    required this.lastMessage,
    required this.timeLabel,
    required this.sortKey,
  });

  final String id;
  final KosData kos;
  final String ownerId;
  final String ownerName;
  final String ownerPhoto;
  final String penyewaId;
  final String penyewaName;
  final String penyewaPhoto;
  final String lastMessage;
  final String timeLabel;
  final DateTime sortKey;

  String displayNameFor(String currentUserId) {
    return currentUserId == ownerId ? penyewaName : ownerName;
  }

  String displayPhotoFor(String currentUserId) {
    return currentUserId == ownerId ? penyewaPhoto : ownerPhoto;
  }

  factory ChatPreviewData.fromMap({
    required String id,
    required Map<String, dynamic> data,
    required KosData kos,
  }) {
    final timestamp =
        (data['last_message_time'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return ChatPreviewData(
      id: id,
      kos: kos,
      ownerId: data['owner_id'] as String? ?? kos.ownerId,
      ownerName: data['owner_name'] as String? ?? kos.ownerName,
      ownerPhoto: data['owner_photo'] as String? ?? kos.ownerPhoto,
      penyewaId: data['penyewa_id'] as String? ?? '',
      penyewaName: data['penyewa_name'] as String? ?? 'Penyewa',
      penyewaPhoto: data['penyewa_photo'] as String? ?? '',
      lastMessage: data['last_message'] as String? ?? '',
      timeLabel: _formatTime(timestamp),
      sortKey: timestamp,
    );
  }
}

class ChatMessageData {
  const ChatMessageData({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timeLabel,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String timeLabel;

  factory ChatMessageData.fromMap(String id, Map<String, dynamic> map) {
    final timestamp =
        (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    return ChatMessageData(
      id: id,
      senderId: map['sender_id'] as String? ?? '',
      senderName: map['sender_name'] as String? ?? '',
      text: map['text'] as String? ?? '',
      timeLabel: _formatTime(timestamp),
    );
  }
}

class BookingData {
  const BookingData({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.userPhoto,
    required this.emergencyContact,
    required this.kos,
    required this.roomLabel,
    required this.note,
    required this.paymentProofUrl,
    required this.startDate,
    required this.startDateValue,
    required this.endDate,
    required this.endDateValue,
    required this.durationLabel,
    required this.monthlyPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.cancelReason,
    required this.total,
    required this.totalPrice,
    required this.sortKey,
    required this.paymentUpdatedAt,
    required this.ownerNotes,
  });

  factory BookingData.empty(String roomLabel, KosData kos) {
    return BookingData(
      id: '',
      userId: '',
      userName: 'Belum terisi',
      userEmail: '-',
      userPhone: '-',
      userPhoto: '',
      emergencyContact: '-',
      kos: kos,
      roomLabel: roomLabel,
      note: '',
      paymentProofUrl: '',
      startDate: '-',
      startDateValue: DateTime.fromMillisecondsSinceEpoch(0),
      endDate: '-',
      endDateValue: DateTime.fromMillisecondsSinceEpoch(0),
      durationLabel: '-',
      monthlyPrice: 0,
      paymentMethod: '-',
      paymentStatus: 'Tersedia',
      status: 'Tersedia',
      cancelReason: '',
      total: _currency(0),
      totalPrice: 0,
      sortKey: DateTime.fromMillisecondsSinceEpoch(0),
      paymentUpdatedAt: null,
      ownerNotes: const [],
    );
  }

  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String userPhoto;
  final String emergencyContact;
  final KosData kos;
  final String roomLabel;
  final String note;
  final String paymentProofUrl;
  final String startDate;
  final DateTime startDateValue;
  final String endDate;
  final DateTime endDateValue;
  final String durationLabel;
  final int monthlyPrice;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String cancelReason;
  final String total;
  final int totalPrice;
  final DateTime sortKey;
  final DateTime? paymentUpdatedAt;
  final List<String> ownerNotes;

  factory BookingData.fromMap({
    required String id,
    required Map<String, dynamic> map,
    required KosData kos,
  }) {
    final timestamp =
        (map['created_at'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final startDateValue = _parseStoredDate(
      map['start_date'],
      fallbackLabel: map['start_date_label'] as String?,
      fallback: timestamp,
    );
    final durationLabel = map['duration_label'] as String? ?? '-';
    final endDateValue = _parseStoredDate(
      map['end_date'],
      fallbackLabel: map['end_date_label'] as String?,
      fallback: _addMonths(startDateValue, _monthsFromDuration(durationLabel)),
    );
    return BookingData(
      id: id,
      userId: map['user_id'] as String? ?? '',
      userName: map['user_name'] as String? ?? 'Penyewa',
      userEmail: map['user_email'] as String? ?? '-',
      userPhone: map['user_phone'] as String? ?? '-',
      userPhoto: map['user_photo'] as String? ?? '',
      emergencyContact: map['emergency_contact'] as String? ?? '-',
      kos: kos,
      roomLabel: map['room_label'] as String? ?? '-',
      note: map['note'] as String? ?? '',
      paymentProofUrl: map['payment_proof_url'] as String? ?? '',
      startDate:
          map['start_date_label'] as String? ?? _formatLongDate(startDateValue),
      startDateValue: startDateValue,
      endDate:
          map['end_date_label'] as String? ?? _formatLongDate(endDateValue),
      endDateValue: endDateValue,
      durationLabel: durationLabel,
      monthlyPrice: (map['monthly_price'] as num?)?.toInt() ?? kos.price,
      paymentMethod: map['payment_method'] as String? ?? '-',
      paymentStatus: map['payment_status'] as String? ?? 'Pending',
      status: map['status'] as String? ?? '-',
      cancelReason: map['cancel_reason'] as String? ?? '',
      total: _currency((map['total_price'] as num?)?.toInt() ?? 0),
      totalPrice: (map['total_price'] as num?)?.toInt() ?? 0,
      sortKey: timestamp,
      paymentUpdatedAt: (map['payment_updated_at'] as Timestamp?)?.toDate(),
      ownerNotes: (map['owner_notes'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class OwnerVoucherData {
  const OwnerVoucherData({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountAmount,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final int discountAmount;
  final bool isActive;
  final DateTime createdAt;

  factory OwnerVoucherData.fromMap(String id, Map<String, dynamic> map) {
    return OwnerVoucherData(
      id: id,
      code: map['code'] as String? ?? '',
      title: map['title'] as String? ?? 'Voucher Owner',
      description: map['description'] as String? ?? '',
      discountAmount: (map['discount_amount'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      createdAt:
          (map['created_at'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class HomeBannerData {
  const HomeBannerData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.placement,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String placement;
  final bool isActive;
  final DateTime createdAt;

  factory HomeBannerData.fromMap(String id, Map<String, dynamic> map) {
    return HomeBannerData(
      id: id,
      title: map['title'] as String? ?? 'Banner KosHub',
      subtitle: map['subtitle'] as String? ?? '',
      imageUrl: map['image_url'] as String? ?? '',
      placement: map['placement'] as String? ?? 'hero',
      isActive: map['is_active'] as bool? ?? true,
      createdAt:
          (map['created_at'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
