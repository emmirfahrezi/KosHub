part of '../../main.dart';

class OwnerNotificationsPage extends StatelessWidget {
  const OwnerNotificationsPage({
    super.key,
    required this.bookings,
    required this.kos,
  });

  final List<BookingData> bookings;
  final KosData? kos;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final notifications = <_OwnerNotificationData>[
      ...bookings
          .where((booking) => booking.status == 'Menunggu Konfirmasi')
          .map(
            (booking) => _OwnerNotificationData(
              title: 'Ada booking baru',
              subtitle: '${booking.userName} booking ${booking.roomLabel}',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => OwnerBookingDetailPage(booking: booking),
                  ),
                );
              },
            ),
          ),
      ...bookings
          .where((booking) => booking.paymentStatus == 'Overdue')
          .map(
            (booking) => _OwnerNotificationData(
              title: 'Penghuni telat bayar',
              subtitle: '${booking.userName} belum membayar tagihan bulan ini',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ResidentDetailPage(booking: booking),
                  ),
                );
              },
            ),
          ),
      ...bookings
          .where((booking) => booking.status == 'Sudah Check-in')
          .where(
            (booking) =>
                _nextBillingDueDate(
                  booking.startDateValue,
                  now,
                ).difference(now).inDays <=
                3,
          )
          .map(
            (booking) => _OwnerNotificationData(
              title: 'Jatuh tempo pembayaran',
              subtitle: '${booking.userName} jatuh tempo dalam 3 hari',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ResidentDetailPage(booking: booking),
                  ),
                );
              },
            ),
          ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Notifikasi'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          if (kos != null)
            _OwnerSectionCard(
              title: 'Kos aktif',
              subtitle: '${kos!.name} - ${kos!.area}',
              child: const Text(
                'Semua notifikasi di bawah akan mengarahkan kamu ke halaman yang terkait.',
              ),
            ),
          if (notifications.isNotEmpty) const SizedBox(height: 16),
          if (notifications.isEmpty)
            const _EmptyStateCard(
              title: 'Belum ada notifikasi',
              subtitle:
                  'Booking baru, reminder bayar, dan aktivitas penting akan muncul di sini.',
            )
          else
            ...notifications.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: ListTile(
                  onTap: item.onTap,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEAF5F5),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFF006A6A),
                    ),
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.subtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class OwnerSettingsPage extends StatelessWidget {
  const OwnerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Pengaturan Akun'),
      ),
      body: StreamBuilder<AppUserData?>(
        stream: SupabaseService.instance.userProfileStream(user.id),
        builder: (context, userSnapshot) {
          final profile = userSnapshot.data;
          return StreamBuilder<KosData?>(
            stream: SupabaseService.instance.ownerKosStream(user.id),
            builder: (context, kosSnapshot) {
              final kos = kosSnapshot.data;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  _ProfileHeader(
                    name: profile?.name ?? user.displayName ?? 'Pemilik Kos',
                    email: profile?.email ?? user.email ?? '-',
                    role: profile?.role ?? 'pemilik',
                  ),
                  const SizedBox(height: 16),
                  _OwnerSectionCard(
                    title: 'Akun pemilik',
                    subtitle:
                        'Semua pengaturan penting owner dikumpulkan di satu halaman.',
                    child: Column(
                      children: [
                        _SummaryRow(
                          label: 'Nama kos',
                          value: kos?.name ?? 'Belum diisi',
                        ),
                        const SizedBox(height: 6),
                        _SummaryRow(
                          label: 'Alamat',
                          value: kos?.address ?? 'Belum diisi',
                        ),
                        const SizedBox(height: 6),
                        const _SummaryRow(
                          label: 'Nomor HP',
                          value: 'Kelola dari data penghuni / akun',
                        ),
                        const SizedBox(height: 6),
                        const _SummaryRow(
                          label: 'Rekening pembayaran',
                          value: 'Belum diisi',
                        ),
                        const SizedBox(height: 6),
                        const _SummaryRow(
                          label: 'Jam operasional',
                          value: '08.00 - 21.00',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProfileMenuTile(
                    icon: Icons.edit_rounded,
                    title: 'Edit Profil Kos',
                    subtitle:
                        'Ubah nama kos, alamat, foto, mode approval, dan fasilitas',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              OwnerRegistrationPage(existingKos: kos),
                        ),
                      );
                    },
                  ),
                  _ProfileMenuTile(
                    icon: Icons.lock_reset_rounded,
                    title: 'Ubah Password',
                    subtitle: 'Kelola keamanan akun owner',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Gunakan menu profil untuk memperbarui data akun dan password.',
                          ),
                        ),
                      );
                    },
                  ),
                  _ProfileMenuTile(
                    icon: Icons.devices_other_rounded,
                    title: 'Logout Semua Device',
                    subtitle: 'Aksi keamanan untuk semua sesi login',
                    onTap: () async {
                      await _confirmUserLogout(
                        context,
                        title: 'Logout semua device?',
                        message:
                            'Semua sesi owner akan diakhiri dan kamu akan diarahkan ke halaman login.',
                      );
                    },
                  ),
                  _ProfileMenuTile(
                    icon: Icons.history_toggle_off_rounded,
                    title: 'Aktivitas Login',
                    subtitle: 'Lihat histori login owner',
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        backgroundColor: Colors.white,
                        builder: (context) {
                          return const SafeArea(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Aktivitas Login',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text('Hari ini - Perangkat aktif saat ini'),
                                  SizedBox(height: 8),
                                  Text(
                                    'Riwayat login detail akan tersedia di pembaruan berikutnya.',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _OwnerDetailHeader extends StatelessWidget {
  const _OwnerDetailHeader({
    required this.title,
    required this.subtitle,
    required this.badge,
    this.photoUrl,
  });

  final String title;
  final String subtitle;
  final String badge;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFEAF5F5),
            backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                ? NetworkImage(photoUrl!)
                : null,
            child: photoUrl == null || photoUrl!.isEmpty
                ? const Icon(Icons.person, color: Color(0xFF006A6A), size: 28)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _normalizeUiText(title),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _normalizeUiText(subtitle),
                  style: const TextStyle(color: Color(0xFF5D6B6B)),
                ),
              ],
            ),
          ),
          _StatusBadge(label: badge),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF006A6A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF5D6B6B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerNotificationData {
  const _OwnerNotificationData({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
}
