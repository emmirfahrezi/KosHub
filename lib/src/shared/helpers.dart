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

String _supabaseMessage(SupabaseAppException error) {
  switch (error.code) {
    case 'permission-denied':
      return error.message ??
          'Akses ditolak. Pastikan akun anda punya izin untuk tindakan ini.';
    case 'unavailable':
      return 'Supabase belum bisa dihubungi. Periksa koneksi internet.';
    case 'not-found':
      return 'Data terkait tidak ditemukan. Muat ulang lalu coba lagi.';
    case 'unauthenticated':
      return 'Sesi login tidak valid. Silakan masuk ulang.';
    default:
      return error.message ?? 'Supabase gagal memproses permintaan.';
  }
}

String _streamErrorMessage(Object? error) {
  if (error is SupabaseAppException) {
    return _supabaseMessage(error);
  }
  return 'Terjadi kendala saat mengambil data. Periksa koneksi lalu coba lagi.';
}

String _normalizeUiText(String value) {
  return value
      .replaceAll('ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢', ' - ')
      .replaceAll('ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢', ' - ')
      .replaceAll('Â·', ' - ')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
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
    await SupabaseService.instance.cancelBookingByTenant(booking);
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
  } on SupabaseAppException catch (error) {
    if (!context.mounted) {
      return;
    }
    _showLightDialog(
      context,
      title: 'Pembatalan gagal',
      message: _supabaseMessage(error),
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

Future<bool> _confirmFinishResident(
  BuildContext context,
  BookingData booking,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Keluarkan penghuni?'),
        content: Text(
          '${booking.userName} akan dipindahkan ke riwayat dan '
          '${booking.roomLabel} langsung tersedia untuk booking baru. '
          'Pastikan penghuni memang sudah keluar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF9F4035),
            ),
            child: const Text('Ya, Keluarkan'),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

Future<void> _showImagePreviewDialog(
  BuildContext context, {
  required String title,
  required String imageUrl,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InteractiveViewer(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Container(
                width: 260,
                height: 220,
                color: const Color(0xFFF7FBFB),
                alignment: Alignment.center,
                child: const Text(
                  'Gambar tidak bisa dimuat.',
                  style: TextStyle(color: Color(0xFF5D6B6B)),
                ),
              ),
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      );
    },
  );
}

Future<void> _confirmUserLogout(
  BuildContext context, {
  String title = 'Keluar dari akun?',
  String message =
      'Kamu akan keluar dari akun ini dan diarahkan ke halaman login.',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  try {
    await SupabaseAuth.instance.signOut();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthGate()),
      (_) => false,
    );
  } on SupabaseAuthException catch (error) {
    if (!context.mounted) {
      return;
    }
    await _showLightDialog(
      context,
      title: 'Logout gagal',
      message: error.message ?? 'Sesi akun belum berhasil diakhiri.',
    );
  }
}

Future<void> _confirmAdminLogout(
  BuildContext context, {
  required String email,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Keluar dari admin?'),
        content: Text(
          'Sesi admin ${email.isEmpty ? '' : 'untuk $email '}akan diakhiri dan kamu akan diarahkan ke halaman login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  try {
    await SupabaseAuth.instance.signOut();
    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Logout berhasil'),
          content: const Text(
            'Kamu sudah keluar dari panel admin. Tekan tombol di bawah untuk kembali ke halaman login.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const AuthGate()),
                  (_) => false,
                );
              },
              child: const Text('Masuk Lagi'),
            ),
          ],
        );
      },
    );
  } on SupabaseAuthException catch (error) {
    if (!context.mounted) {
      return;
    }
    await _showLightDialog(
      context,
      title: 'Logout gagal',
      message: error.message ?? 'Sesi admin belum berhasil diakhiri.',
    );
  }
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

const int _ownerActivationBaseFee = 250000;

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
  final parsedValue = _parseNullableStoredDate(value);
  if (parsedValue != null) {
    return parsedValue;
  }
  if (fallbackLabel != null && fallbackLabel.isNotEmpty) {
    final parsed = _parseIndonesianDate(fallbackLabel);
    if (parsed != null) {
      return parsed;
    }
  }
  return fallback ?? DateTime.now();
}

DateTime? _parseNullableStoredDate(Object? value) {
  if (value is StoredTimestamp) {
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
  return null;
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
      'total_rooms': this['total_rooms'] ?? this['available_rooms'] ?? 0,
      'updated_at': DatabaseValue.serverTimestamp(),
    };
  }
}
