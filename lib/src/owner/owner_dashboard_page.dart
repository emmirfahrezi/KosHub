part of '../../main.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({
    super.key,
    required this.onOpenBookings,
    required this.onOpenResidents,
  });

  final VoidCallback onOpenBookings;
  final VoidCallback onOpenResidents;

  @override
  Widget build(BuildContext context) {
    final user = SupabaseAuth.instance.currentUser!;

    return StreamBuilder<KosData?>(
      stream: SupabaseService.instance.ownerKosStream(user.id),
      builder: (context, kosSnapshot) {
        if (kosSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(label: 'Menyiapkan dashboard pemilik...');
        }

        final kos = kosSnapshot.data;
        return StreamBuilder<List<BookingData>>(
          stream: SupabaseService.instance.ownerBookingsStream(user.id),
          builder: (context, bookingsSnapshot) {
            if (bookingsSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen(label: 'Menghitung statistik kos...');
            }

            final ownerBookings =
                bookingsSnapshot.data ?? const <BookingData>[];
            final bookings = kos == null
                ? const <BookingData>[]
                : ownerBookings
                      .where((booking) => booking.kos.id == kos.id)
                      .toList();
            final now = DateTime.now();
            final activeResidents = bookings
                .where((booking) => booking.status == 'Sudah Check-in')
                .toList();
            final pendingBookings = bookings
                .where((booking) => booking.status == 'Menunggu Konfirmasi')
                .toList();
            final roomBlockingBookings = bookings
                .where((booking) => _roomBlocksAvailability(booking.status))
                .toList();
            final totalRooms = kos == null
                ? 0
                : math.max(kos.totalRooms, roomBlockingBookings.length);
            final availableRooms = kos == null
                ? 0
                : math.max(totalRooms - roomBlockingBookings.length, 0);
            final occupancyRatio = totalRooms == 0
                ? 0.0
                : activeResidents.length / totalRooms;
            final occupancyPercent = (occupancyRatio * 100).round();
            final latestResidents = [...activeResidents]
              ..sort((a, b) => b.sortKey.compareTo(a.sortKey));
            final bookingToday = bookings
                .where((booking) => _isSameDay(booking.sortKey, now))
                .length;
            final approvalModeLabel = kos == null
                ? ''
                : _ownerApprovalModeLabel(kos.approvalMode);

            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                title: const Text('Dashboard Pemilik'),
                actions: [
                  _OwnerNotificationBadgeButton(bookings: bookings, kos: kos),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    builder: (context) {
                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Aksi Cepat',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.add_business_rounded),
                                title: const Text(
                                  'Tambah kamar / edit listing',
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => OwnerRegistrationPage(
                                        existingKos: kos,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.person_add_alt_rounded,
                                ),
                                title: const Text('Tambah / review penghuni'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => const OwnerResidentsPage(
                                        initialTab: 0,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.chat_rounded),
                                title: const Text('Chat Penyewa'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => const ChatListPage(),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.star_rounded),
                                title: const Text('Ulasan Penyewa'),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => const OwnerReviewsPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Aksi Cepat'),
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF045D5D), Color(0xFF10B3B3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22006A6A),
                          blurRadius: 24,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _OwnerHeroChip(
                              icon: Icons.place_outlined,
                              label: kos?.area ?? 'Listing belum lengkap',
                            ),
                            _OwnerHeroChip(
                              icon: Icons.rule_rounded,
                              label: kos == null
                                  ? 'Perlu dilengkapi'
                                  : 'Mode $approvalModeLabel',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          kos?.name ?? 'Kos belum dilengkapi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          kos == null
                              ? 'Lengkapi listing kos dulu supaya dashboard operasional mulai terisi.'
                              : 'Pantau booking, penghuni, dan pembayaran kos dari satu dashboard yang lebih ringkas.',
                          style: const TextStyle(
                            color: Color(0xFFE2FFFF),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _OwnerHeroStat(
                                label: 'Okupansi',
                                value: '$occupancyPercent%',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _OwnerHeroStat(
                                label: 'Penghuni aktif',
                                value: '${activeResidents.length} orang',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: onOpenBookings,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF006A6A),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text('Lihat Booking'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: onOpenResidents,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white38),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text('Lihat Penghuni'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _OwnerDashboardHeading(
                    title: 'Ringkasan Operasional',
                    subtitle:
                        'Angka paling penting untuk booking, kamar, penghuni, dan arus pembayaran.',
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width >= 980
                          ? 4
                          : width >= 720
                          ? 3
                          : 2;
                      final childAspectRatio = width >= 720 ? 1.22 : 1.05;

                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: childAspectRatio,
                        children: [
                          _OwnerMetricCard(
                            title: 'Total kamar',
                            value: '$totalRooms',
                            subtitle: 'Unit yang terdaftar',
                            icon: Icons.meeting_room_rounded,
                            accentColor: const Color(0xFF35589F),
                          ),
                          _OwnerMetricCard(
                            title: 'Kamar tersedia',
                            value: '$availableRooms',
                            subtitle: 'Siap ditempati',
                            icon: Icons.door_front_door_rounded,
                            accentColor: const Color(0xFF006A6A),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const OwnerRoomsPage(),
                                ),
                              );
                            },
                          ),
                          _OwnerMetricCard(
                            title: 'Booking pending',
                            value: '${pendingBookings.length}',
                            subtitle: 'Menunggu review',
                            icon: Icons.schedule_rounded,
                            accentColor: const Color(0xFFB78103),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const OwnerBookingPage(initialTab: 0),
                                ),
                              );
                            },
                          ),
                          _OwnerMetricCard(
                            title: 'Penghuni aktif',
                            value: '${activeResidents.length}',
                            subtitle: 'Sudah check-in',
                            icon: Icons.groups_rounded,
                            accentColor: const Color(0xFF35589F),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const OwnerResidentsPage(initialTab: 0),
                                ),
                              );
                            },
                          ),
                          _OwnerMetricCard(
                            title: 'Kamar tersedia',
                            value: '$availableRooms',
                            subtitle: 'Siap dibooking',
                            icon: Icons.meeting_room_rounded,
                            accentColor: const Color(0xFF1D7A46),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const OwnerResidentsPage(initialTab: 0),
                                ),
                              );
                            },
                          ),
                          _OwnerMetricCard(
                            title: 'Booking hari ini',
                            value: '$bookingToday',
                            subtitle: 'Masuk hari ini',
                            icon: Icons.today_rounded,
                            accentColor: const Color(0xFF5A4FCF),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const OwnerBookingPage(initialTab: 0),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Grafik okupansi kos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: occupancyRatio.clamp(0.0, 1.0),
                            minHeight: 14,
                            backgroundColor: const Color(0xFFE8EFEF),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF006A6A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$occupancyPercent% terisi - ${activeResidents.length} dari $totalRooms kamar',
                          style: const TextStyle(
                            color: Color(0xFF5D6B6B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _OwnerSectionCard(
                    title: 'Penghuni terbaru',
                    subtitle:
                        'Pantau penghuni yang baru check-in dan mulai butuh onboarding.',
                    child: latestResidents.isEmpty
                        ? const Text(
                            'Belum ada penghuni aktif.',
                            style: TextStyle(color: Color(0xFF5D6B6B)),
                          )
                        : Column(
                            children: latestResidents.take(3).map((booking) {
                              return _OwnerListTile(
                                title: booking.userName,
                                subtitle:
                                    '${booking.roomLabel} - Masuk ${booking.startDate}',
                                trailing: booking.status,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          ResidentDetailPage(booking: booking),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                  ),
                  _OwnerSectionCard(
                    title: 'Aktivitas Terbaru',
                    subtitle:
                        'Semua aktivitas penting bisa dibuka langsung ke halaman yang relevan.',
                    child: bookings.isEmpty
                        ? const Text(
                            'Belum ada aktivitas terbaru.',
                            style: TextStyle(color: Color(0xFF5D6B6B)),
                          )
                        : Column(
                            children: bookings.take(4).map((booking) {
                              final activityLabel =
                                  booking.status == 'Menunggu Konfirmasi'
                                  ? '${booking.userName} booking ${booking.roomLabel}'
                                  : booking.status == 'Sudah Check-in'
                                  ? '${booking.userName} check-in ke ${booking.roomLabel}'
                                  : '${booking.userName} status ${booking.status.toLowerCase()}';
                              return _OwnerListTile(
                                title: activityLabel,
                                subtitle:
                                    '${booking.kos.name} - ${_formatLongDate(booking.sortKey)}',
                                trailing: booking.status,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => OwnerBookingDetailPage(
                                        booking: booking,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

String _ownerApprovalModeLabel(String mode) {
  switch (mode) {
    case 'Auto Approval':
      return 'Otomatis';
    case 'Manual Approval':
      return 'Manual';
    default:
      return mode;
  }
}

class _OwnerDashboardHeading extends StatelessWidget {
  const _OwnerDashboardHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF182022),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
        ),
      ],
    );
  }
}

class _OwnerHeroChip extends StatelessWidget {
  const _OwnerHeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerHeroStat extends StatelessWidget {
  const _OwnerHeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x16FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE2FFFF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
