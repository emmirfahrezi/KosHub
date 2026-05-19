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
      'status': 'active',
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

  bool get isAdmin => _isAdminRole(role);

  String get roleLabel {
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
    );
  }
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.totalUsers,
    required this.totalOwners,
    required this.totalKos,
    required this.activeRooms,
    required this.bookingsToday,
    required this.platformRevenue,
    required this.activeComplaints,
    required this.blockedUsers,
    required this.reportedKos,
    required this.recentActivities,
    required this.latestOwnerSummary,
    required this.topKosSummary,
    required this.topBookingSummary,
  });

  final int totalUsers;
  final int totalOwners;
  final int totalKos;
  final int activeRooms;
  final int bookingsToday;
  final int platformRevenue;
  final int activeComplaints;
  final int blockedUsers;
  final int reportedKos;
  final List<AdminActivityItem> recentActivities;
  final String latestOwnerSummary;
  final String topKosSummary;
  final String topBookingSummary;

  factory AdminDashboardData.empty() {
    return const AdminDashboardData(
      totalUsers: 0,
      totalOwners: 0,
      totalKos: 0,
      activeRooms: 0,
      bookingsToday: 0,
      platformRevenue: 0,
      activeComplaints: 0,
      blockedUsers: 0,
      reportedKos: 0,
      recentActivities: [],
      latestOwnerSummary: 'Belum ada data pemilik terbaru.',
      topKosSummary: 'Belum ada listing aktif.',
      topBookingSummary: 'Belum ada booking masuk.',
    );
  }

  factory AdminDashboardData.fromCollections({
    required List<AppUserData> users,
    required List<KosData> kosList,
    required List<BookingData> bookings,
  }) {
    final today = _dayKey(DateTime.now());
    final owners = users.where((user) => user.role == 'pemilik').toList();
    owners.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    final activeRooms = kosList.fold<int>(
      0,
      (total, kos) => total + (kos.totalRooms - kos.availableRooms),
    );
    final bookingsToday = bookings.where((booking) {
      return _dayKey(booking.sortKey) == today;
    }).length;
    final platformRevenue = bookings
        .where((booking) => booking.paymentStatus == 'Lunas')
        .fold<int>(
          0,
          (total, booking) => total + (booking.totalPrice * 0.05).round(),
        );
    final activeComplaints = bookings.where((booking) {
      return booking.note.toLowerCase().contains('komplain') ||
          booking.note.toLowerCase().contains('lapor');
    }).length;
    final blockedUsers = users
        .where((user) => user.accountStatus == 'Diblokir')
        .length;
    final reportedKos = kosList
        .where((kos) => kos.description.toLowerCase().contains('laporan'))
        .length;

    final bookingCounts = <String, int>{};
    for (final booking in bookings) {
      bookingCounts.update(
        booking.kos.name,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    String topKosSummary = 'Belum ada listing aktif.';
    if (bookingCounts.isNotEmpty) {
      final top = bookingCounts.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      topKosSummary = '${top.key} | ${top.value} booking';
    }

    final recentActivities = bookings.take(5).map((booking) {
      return AdminActivityItem(
        title: '${booking.userName} booking ${booking.kos.name}',
        subtitle: '${booking.status} | ${booking.paymentStatus}',
        timeLabel: _formatTime(booking.sortKey),
        icon: Icons.bolt_rounded,
      );
    }).toList();

    if (recentActivities.length < 5) {
      recentActivities.addAll(
        owners
            .take(5 - recentActivities.length)
            .map(
              (owner) => AdminActivityItem(
                title: '${owner.name} masuk sebagai pemilik kos',
                subtitle:
                    '${owner.verificationStatus} | ${owner.accountStatus}',
                timeLabel: _formatTime(owner.createdAt),
                icon: Icons.verified_user_rounded,
              ),
            ),
      );
    }

    return AdminDashboardData(
      totalUsers: users.where((user) => !user.isAdmin).length,
      totalOwners: owners.length,
      totalKos: kosList.length,
      activeRooms: activeRooms,
      bookingsToday: bookingsToday,
      platformRevenue: platformRevenue,
      activeComplaints: activeComplaints,
      blockedUsers: blockedUsers,
      reportedKos: reportedKos,
      recentActivities: recentActivities,
      latestOwnerSummary: owners.isEmpty
          ? 'Belum ada owner baru.'
          : '${owners.first.name} | ${owners.first.verificationStatus}',
      topKosSummary: topKosSummary,
      topBookingSummary: bookings.isEmpty
          ? 'Belum ada booking masuk.'
          : '${bookings.first.kos.name} | ${bookings.first.status}',
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
