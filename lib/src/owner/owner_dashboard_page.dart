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
    final user = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<KosData?>(
      stream: FirestoreService.instance.ownerKosStream(user.uid),
      builder: (context, kosSnapshot) {
        if (kosSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(label: 'Menyiapkan dashboard pemilik...');
        }

        final kos = kosSnapshot.data;
        return StreamBuilder<List<BookingData>>(
          stream: FirestoreService.instance.ownerBookingsStream(user.uid),
          builder: (context, bookingsSnapshot) {
            if (bookingsSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen(label: 'Menghitung statistik kos...');
            }

            final bookings = bookingsSnapshot.data ?? const <BookingData>[];
            final now = DateTime.now();
            final activeResidents = bookings
                .where((booking) => booking.status == 'Sudah Check-in')
                .toList();
            final pendingBookings = bookings
                .where((booking) => booking.status == 'Menunggu Konfirmasi')
                .toList();
            final totalRooms = kos == null
                ? 0
                : math.max(kos.totalRooms, activeResidents.length);
            final availableRooms = kos == null
                ? 0
                : math.max(
                    kos.availableRooms,
                    totalRooms - activeResidents.length,
                  );
            final occupancyRatio = totalRooms == 0
                ? 0.0
                : activeResidents.length / totalRooms;
            final thisMonthBills = activeResidents.fold<int>(
              0,
              (runningTotal, booking) => runningTotal + booking.monthlyPrice,
            );
            final latePayments = activeResidents
                .where((booking) => booking.paymentStatus == 'Overdue')
                .length;
            final monthlyIncome = activeResidents
                .where((booking) => booking.paymentStatus == 'Lunas')
                .where(
                  (booking) =>
                      booking.paymentUpdatedAt != null &&
                      booking.paymentUpdatedAt!.month == now.month &&
                      booking.paymentUpdatedAt!.year == now.year,
                )
                .fold<int>(
                  0,
                  (runningTotal, booking) =>
                      runningTotal + booking.monthlyPrice,
                );
            final latestResidents = [...activeResidents]
              ..sort((a, b) => b.sortKey.compareTo(a.sortKey));
            final dueSoonResidents = [...activeResidents]
              ..sort(
                (a, b) => _nextBillingDueDate(
                  a.startDateValue,
                  now,
                ).compareTo(_nextBillingDueDate(b.startDateValue, now)),
              );
            final bookingToday = bookings
                .where((booking) => _isSameDay(booking.sortKey, now))
                .length;

            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                title: const Text('Dashboard Pemilik'),
                actions: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => OwnerNotificationsPage(
                            bookings: bookings,
                            kos: kos,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const OwnerTransactionsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_rounded),
                  ),
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
                                'Quick Action',
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
                                leading: const Icon(Icons.campaign_rounded),
                                title: const Text('Broadcast pesan'),
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
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Quick Action'),
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF006A6A), Color(0xFF00A8A8)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kos?.name ?? 'Kos belum dilengkapi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          kos == null
                              ? 'Lengkapi listing kos dulu supaya dashboard operasional mulai terisi.'
                              : '${kos.area} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Mode ${kos.approvalMode}',
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.45,
                          ),
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
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _OwnerMetricCard(
                        title: 'Total kamar',
                        value: '$totalRooms',
                        subtitle: 'Unit yang terdaftar',
                      ),
                      _OwnerMetricCard(
                        title: 'Kamar tersedia',
                        value: '$availableRooms',
                        subtitle: 'Siap ditempati',
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
                        title: 'Tagihan bulan ini',
                        value: _currency(thisMonthBills),
                        subtitle: 'Estimasi berjalan',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const OwnerTransactionsPage(
                                initialFilter: OwnerTransactionFilter.thisMonth,
                              ),
                            ),
                          );
                        },
                      ),
                      _OwnerMetricCard(
                        title: 'Pembayaran telat',
                        value: '$latePayments',
                        subtitle: 'Butuh follow up',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const OwnerTransactionsPage(
                                initialFilter: OwnerTransactionFilter.overdue,
                              ),
                            ),
                          );
                        },
                      ),
                      _OwnerMetricCard(
                        title: 'Pendapatan bulan ini',
                        value: _currency(monthlyIncome),
                        subtitle: 'Status lunas',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const OwnerTransactionsPage(
                                initialFilter: OwnerTransactionFilter.paid,
                              ),
                            ),
                          );
                        },
                      ),
                      _OwnerMetricCard(
                        title: 'Booking hari ini',
                        value: '$bookingToday',
                        subtitle: 'Masuk hari ini',
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
                  ),
                  const SizedBox(height: 20),
                  _OwnerSectionCard(
                    title: 'Shortcut Operasional',
                    subtitle:
                        'Semua ringkasan di dashboard ini bisa dibuka lebih detail tanpa bikin halaman terasa dobel.',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _DashboardShortcutChip(
                          label: 'Chat',
                          icon: Icons.chat_bubble_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const ChatListPage(),
                              ),
                            );
                          },
                        ),
                        _DashboardShortcutChip(
                          label: 'Transaksi',
                          icon: Icons.receipt_long_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const OwnerTransactionsPage(),
                              ),
                            );
                          },
                        ),
                        _DashboardShortcutChip(
                          label: 'Booking',
                          icon: Icons.fact_check_rounded,
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
                        _DashboardShortcutChip(
                          label: 'Pengaturan',
                          icon: Icons.settings_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const OwnerSettingsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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
                          '${(occupancyRatio * 100).round()}% terisi ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ${activeResidents.length} dari $totalRooms kamar',
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
                                    '${booking.roomLabel} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Masuk ${booking.startDate}',
                                trailing: booking.paymentStatus,
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
                  const SizedBox(height: 16),
                  _OwnerSectionCard(
                    title: 'Jatuh tempo terdekat',
                    subtitle:
                        'Daftar penghuni yang paling dekat dengan deadline pembayaran berikutnya.',
                    child: dueSoonResidents.isEmpty
                        ? const Text(
                            'Belum ada jatuh tempo aktif.',
                            style: TextStyle(color: Color(0xFF5D6B6B)),
                          )
                        : Column(
                            children: dueSoonResidents.take(3).map((booking) {
                              final dueDate = _nextBillingDueDate(
                                booking.startDateValue,
                                now,
                              );
                              return _OwnerListTile(
                                title: booking.userName,
                                subtitle:
                                    '${booking.roomLabel} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ Jatuh tempo ${_formatLongDate(dueDate)}',
                                trailing: booking.paymentStatus,
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
                  const SizedBox(height: 16),
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
                                    '${booking.kos.name} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ${_formatLongDate(booking.sortKey)}',
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
