part of '../../main.dart';

String _currency(int amount) {
  final digits = amount.toString();
  return 'Rp ${_groupDigits(digits)}';
}

String _groupDigits(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return buffer.toString();
}

String _formatNumericInput(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return '';
  }
  return _groupDigits(digits);
}

int? _parseNumericInput(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return null;
  }
  return int.tryParse(digits);
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

String _unknownSaveErrorMessage(Object error) {
  final text = error.toString();
  if (text.trim().isEmpty || text == 'Exception') {
    return 'Coba lagi.';
  }
  return text;
}

String _normalizeUiText(String value) {
  return value
      .replaceAll('ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢', ' - ')
      .replaceAll('ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢', ' - ')
      .replaceAll('Â·', ' - ')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
}

String? _normalizeIndonesianMobileNumber(String value) {
  final input = value.trim();
  if (input.isEmpty) {
    return null;
  }
  if (RegExp(r'[^0-9+\s().-]').hasMatch(input)) {
    return null;
  }

  var digits = input.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.startsWith('+')) {
    if (digits.indexOf('+', 1) != -1) {
      return null;
    }
    digits = digits.substring(1);
  } else if (digits.contains('+')) {
    return null;
  }

  if (digits.startsWith('62')) {
    digits = '0${digits.substring(2)}';
  }

  if (!digits.startsWith('08')) {
    return null;
  }
  if (digits.length < 10 || digits.length > 13) {
    return null;
  }
  if (!RegExp(r'^08\d+$').hasMatch(digits)) {
    return null;
  }
  return digits;
}

bool _hasValidIndonesianMobileNumber(String value) {
  final candidates = RegExp(r'(\+?62|0)8[\d\s().-]{7,15}')
      .allMatches(value)
      .map((match) => match.group(0) ?? '');
  return candidates.any((candidate) {
    return _normalizeIndonesianMobileNumber(candidate) != null;
  });
}

String _indonesianMobileNumberHint(String label) {
  return '$label harus nomor HP Indonesia valid. Gunakan format 08xxxxxxxxxx atau +628xxxxxxxxxx.';
}

bool _isGoogleMapsUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.trim().isEmpty) {
    return false;
  }

  final host = uri.host.toLowerCase();
  final path = uri.path.toLowerCase();

  if (host == 'maps.app.goo.gl') {
    return true;
  }

  if (host == 'goo.gl' && path.startsWith('/maps')) {
    return true;
  }

  if (host.startsWith('maps.google.')) {
    return true;
  }

  final isGoogleHost =
      host == 'google.com' ||
      host == 'www.google.com' ||
      host.endsWith('.google.com') ||
      RegExp(r'(^|\.)google\.[a-z.]+$').hasMatch(host);
  return isGoogleHost && path.startsWith('/maps');
}

bool _hasValidCoordinate(double latitude, double longitude) {
  return latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      (latitude != 0.0 || longitude != 0.0);
}

Uri? _kosMapsUri({
  required String mapsLink,
  required double latitude,
  required double longitude,
  required String address,
  required String name,
}) {
  final cleanMapsLink = mapsLink.trim();
  if (_isGoogleMapsUrl(cleanMapsLink)) {
    return Uri.parse(cleanMapsLink);
  }

  if (_hasValidCoordinate(latitude, longitude)) {
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$latitude,$longitude',
    });
  }

  final query = [name.trim(), address.trim()]
      .where((item) => item.isNotEmpty && item != '-')
      .join(', ');
  if (query.isEmpty) {
    return null;
  }

  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': query,
  });
}

Future<void> _openKosMaps(
  BuildContext context, {
  required KosData kos,
}) async {
  final url = _kosMapsUri(
    mapsLink: kos.googleMapsLink,
    latitude: kos.latitude,
    longitude: kos.longitude,
    address: kos.address,
    name: kos.name,
  );

  if (url == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lokasi kos belum tersedia.')),
    );
    return;
  }

  try {
    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (opened) {
      return;
    }

    final fallbackOpened = await launchUrl(
      url,
      mode: LaunchMode.platformDefault,
    );
    if (!fallbackOpened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka Google Maps.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka Google Maps.')),
      );
    }
  }
}

(double, double)? _parseLatLngFromUrl(String url) {
  if (url.trim().isEmpty) {
    return null;
  }

  final decodedUrl = _safeDecodeUrl(url);
  final number = r'(-?\d+(?:\.\d+)?)';
  final patterns = [
    RegExp('[?&](?:q|query|ll)=$number,$number'),
    RegExp('/@$number,$number'),
    RegExp('!3d$number!4d$number'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(decodedUrl);
    if (match == null) {
      continue;
    }

    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat != null && lng != null && _hasValidCoordinate(lat, lng)) {
      return (lat, lng);
    }
  }

  return null;
}

String _safeDecodeUrl(String value) {
  try {
    return Uri.decodeFull(value);
  } catch (_) {
    return value;
  }
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

const int _ownerActivationBaseFee = 250000;
const Set<String> _freeOwnerActivationVoucherCodes = {'KOSHUB99'};

bool _isFreeOwnerActivationVoucherCode(String code) {
  return _freeOwnerActivationVoucherCodes.contains(code.trim().toUpperCase());
}

int _ownerActivationDiscountFromVoucher(
  OwnerVoucherData? voucher, {
  int activationFee = _ownerActivationBaseFee,
}) {
  if (voucher == null) {
    return 0;
  }
  if (_isFreeOwnerActivationVoucherCode(voucher.code)) {
    return activationFee;
  }
  return math.min(voucher.discountAmount, activationFee);
}

OwnerVoucherData? _builtInOwnerActivationVoucherForCode(String code) {
  final normalizedCode = code.trim().toUpperCase();
  if (!_isFreeOwnerActivationVoucherCode(normalizedCode)) {
    return null;
  }
  return OwnerVoucherData(
    id: 'built-in-$normalizedCode',
    code: normalizedCode,
    title: 'Voucher Aktivasi Gratis',
    description: 'Voucher khusus aktivasi owner KosHub.',
    discountAmount: _ownerActivationBaseFee,
    isActive: true,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

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
