part of '../../main.dart';

String _currency(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return 'Rp $buffer';
}

String _firebaseMessage(FirebaseException error) {
  switch (error.code) {
    case 'permission-denied':
      return error.message ??
          'Akses Firestore ditolak. Deploy/update rules Firestore dulu.';
    case 'unavailable':
      return 'Firestore belum bisa dihubungi. Periksa koneksi internet.';
    case 'not-found':
      return 'Data terkait tidak ditemukan. Muat ulang lalu coba lagi.';
    case 'unauthenticated':
      return 'Sesi login tidak valid. Silakan masuk ulang.';
    default:
      return error.message ?? 'Firebase gagal memproses permintaan.';
  }
}

String _streamErrorMessage(Object? error) {
  if (error is FirebaseException) {
    return _firebaseMessage(error);
  }
  return 'Terjadi kendala saat mengambil data admin. Cek rules Firestore dan koneksi.';
}

Future<void> _confirmCancelBooking(
  BuildContext context,
  BookingData booking,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Batalkan booking?'),
        content: Text(
          'Booking ${booking.kos.name} untuk ${booking.roomLabel} akan dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Batalkan'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  try {
    await FirestoreService.instance.cancelBookingByTenant(booking);
    if (!context.mounted) {
      return;
    }
    await _showLightDialog(
      context,
      title: 'Booking dibatalkan',
      message: 'Booking anda berhasil dibatalkan.',
    );
    if (!context.mounted) {
      return;
    }
    Navigator.pop(context);
  } on FirebaseException catch (error) {
    if (!context.mounted) {
      return;
    }
    _showLightDialog(
      context,
      title: 'Pembatalan gagal',
      message: _firebaseMessage(error),
    );
  }
}

Future<void> _showLightDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Oke'),
          ),
        ],
      );
    },
  );
}

bool _isAdminRole(String role) {
  return role == 'super_admin' ||
      role == 'admin' ||
      role == 'moderator' ||
      role == 'finance_admin' ||
      role == 'customer_service';
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour.$minute';
}

int _totalPrice(int monthlyPrice, String durationLabel) {
  final months = int.tryParse(durationLabel.split(' ').first) ?? 1;
  return monthlyPrice * months;
}

const List<String> _cancelReasons = [
  'Kamar penuh',
  'Pembayaran gagal',
  'Tidak sesuai aturan',
];

const List<String> _paymentStatuses = [
  'Lunas',
  'Pending',
  'Belum Bayar',
  'Overdue',
];

int _monthsFromDuration(String durationLabel) {
  return int.tryParse(durationLabel.split(' ').first) ?? 1;
}

DateTime _addMonths(DateTime date, int months) {
  final targetMonth = date.month + months;
  final year = date.year + ((targetMonth - 1) ~/ 12);
  final month = ((targetMonth - 1) % 12) + 1;
  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  final day = math.min(date.day, lastDayOfMonth);
  return DateTime(year, month, day);
}

String _formatLongDate(DateTime date) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

DateTime _parseStoredDate(
  Object? value, {
  String? fallbackLabel,
  DateTime? fallback,
}) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }
  if (fallbackLabel != null && fallbackLabel.isNotEmpty) {
    final parsed = _parseIndonesianDate(fallbackLabel);
    if (parsed != null) {
      return parsed;
    }
  }
  return fallback ?? DateTime.now();
}

DateTime? _parseIndonesianDate(String label) {
  final months = <String, int>{
    'januari': 1,
    'februari': 2,
    'maret': 3,
    'april': 4,
    'mei': 5,
    'juni': 6,
    'juli': 7,
    'agustus': 8,
    'september': 9,
    'oktober': 10,
    'november': 11,
    'desember': 12,
  };
  final parts = label.trim().split(' ');
  if (parts.length != 3) {
    return null;
  }
  final day = int.tryParse(parts[0]);
  final month = months[parts[1].toLowerCase()];
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) {
    return null;
  }
  return DateTime(year, month, day);
}

String _dayKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime _nextBillingDueDate(DateTime startDate, DateTime reference) {
  var dueDate = DateTime(reference.year, reference.month, startDate.day);
  final lastDay = DateTime(reference.year, reference.month + 1, 0).day;
  if (startDate.day > lastDay) {
    dueDate = DateTime(reference.year, reference.month, lastDay);
  }
  if (!dueDate.isAfter(reference)) {
    final nextMonth = DateTime(reference.year, reference.month + 1, 1);
    final nextLastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    final nextDay = math.min(startDate.day, nextLastDay);
    dueDate = DateTime(nextMonth.year, nextMonth.month, nextDay);
  }
  return dueDate;
}

String _checkInCountdownLabel(DateTime startDate) {
  final days = startDate.difference(DateTime.now()).inDays;
  if (days > 1) {
    return 'Check-in dalam $days hari';
  }
  if (days == 1) {
    return 'Check-in besok';
  }
  if (days == 0) {
    return 'Check-in hari ini';
  }
  return 'Tanggal check-in sudah lewat ${days.abs()} hari';
}

String _transactionFilterLabel(OwnerTransactionFilter filter) {
  switch (filter) {
    case OwnerTransactionFilter.all:
      return 'Semua';
    case OwnerTransactionFilter.thisMonth:
      return 'Bulan Ini';
    case OwnerTransactionFilter.unpaid:
      return 'Belum Bayar';
    case OwnerTransactionFilter.overdue:
      return 'Telat';
    case OwnerTransactionFilter.paid:
      return 'Lunas';
  }
}

extension _DemoKosOwner on Map<String, dynamic> {
  Map<String, dynamic> forOwner({
    required String ownerId,
    required String ownerName,
    required String ownerPhoto,
  }) {
    return {
      ...this,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'owner_status': 'Online',
      'owner_photo': ownerPhoto,
      'approval_mode': this['approval_mode'] ?? 'Manual Approval',
      'total_rooms': this['total_rooms'] ?? this['available_rooms'] ?? 0,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
