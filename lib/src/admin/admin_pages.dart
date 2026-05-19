part of '../../main.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({
    super.key,
    required this.profile,
    required this.onOpenUsers,
    required this.onOpenOwners,
    required this.onOpenListings,
    required this.onOpenPayments,
    required this.onOpenControl,
  });

  final AppUserData profile;
  final VoidCallback onOpenUsers;
  final VoidCallback onOpenOwners;
  final VoidCallback onOpenListings;
  final VoidCallback onOpenPayments;
  final VoidCallback onOpenControl;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AdminDashboardData>(
      stream: FirestoreService.instance.adminDashboardStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(label: 'Memuat dashboard admin...');
        }
        if (snapshot.hasError) {
          return _AdminAccessErrorPage(
            message: _streamErrorMessage(snapshot.error),
          );
        }

        final data = snapshot.data ?? AdminDashboardData.empty();
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Dashboard Admin'),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminSettingsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const AdminBroadcastPage(),
                ),
              );
            },
            backgroundColor: const Color(0xFF182022),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.campaign_rounded),
            label: const Text('Broadcast'),
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF182022), Color(0xFF35589F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat datang, ${profile.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${profile.roleLabel} Koshub | pusat kontrol marketplace kos',
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatusBadge(
                              label: '${data.bookingsToday} booking hari ini',
                            ),
                            _StatusBadge(
                              label: '${data.activeComplaints} komplain aktif',
                            ),
                            _StatusBadge(
                              label: '${data.blockedUsers} user diblokir',
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
                      _AdminMetricCard(
                        label: 'Total Pengguna',
                        value: '${data.totalUsers}',
                        subtitle: 'Akun penyewa aktif',
                        icon: Icons.groups_rounded,
                        onTap: onOpenUsers,
                      ),
                      _AdminMetricCard(
                        label: 'Pemilik Kos',
                        value: '${data.totalOwners}',
                        subtitle: 'Verifikasi & suspend',
                        icon: Icons.verified_user_rounded,
                        onTap: onOpenOwners,
                      ),
                      _AdminMetricCard(
                        label: 'Listing Kos',
                        value: '${data.totalKos}',
                        subtitle: '${data.reportedKos} dilaporkan',
                        icon: Icons.apartment_rounded,
                        onTap: onOpenListings,
                      ),
                      _AdminMetricCard(
                        label: 'Pendapatan App',
                        value: _currency(data.platformRevenue),
                        subtitle: 'Fee bulan ini',
                        icon: Icons.payments_rounded,
                        onTap: onOpenPayments,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _AdminSectionCard(
                    title: 'Quick Control',
                    subtitle: 'Semua flow inti admin bisa dibuka dari sini.',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _AdminShortcutChip(
                          label: 'Kelola Pengguna',
                          icon: Icons.manage_accounts_rounded,
                          onTap: onOpenUsers,
                        ),
                        _AdminShortcutChip(
                          label: 'Verifikasi Pemilik',
                          icon: Icons.fact_check_rounded,
                          onTap: onOpenOwners,
                        ),
                        _AdminShortcutChip(
                          label: 'Moderasi Listing',
                          icon: Icons.approval_rounded,
                          onTap: onOpenListings,
                        ),
                        _AdminShortcutChip(
                          label: 'Monitor Pembayaran',
                          icon: Icons.account_balance_wallet_rounded,
                          onTap: onOpenPayments,
                        ),
                        _AdminShortcutChip(
                          label: 'Laporan & CMS',
                          icon: Icons.hub_rounded,
                          onTap: onOpenControl,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AdminSectionCard(
                    title: 'Aktivitas Realtime',
                    subtitle: 'Alur terbaru di seluruh sistem.',
                    child: Column(
                      children: data.recentActivities
                          .map(
                            (activity) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFEAF1FF),
                                child: Icon(
                                  activity.icon,
                                  color: const Color(0xFF35589F),
                                ),
                              ),
                              title: Text(activity.title),
                              subtitle: Text(activity.subtitle),
                              trailing: Text(activity.timeLabel),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AdminSectionCard(
                    title: 'Fokus Hari Ini',
                    subtitle: 'Area yang perlu perhatian admin paling dekat.',
                    child: Column(
                      children: [
                        _AdminActionTile(
                          title: 'Pemilik terbaru',
                          subtitle: data.latestOwnerSummary,
                          icon: Icons.badge_rounded,
                          onTap: onOpenOwners,
                        ),
                        _AdminActionTile(
                          title: 'Kos paling populer',
                          subtitle: data.topKosSummary,
                          icon: Icons.trending_up_rounded,
                          onTap: onOpenListings,
                        ),
                        _AdminActionTile(
                          title: 'Booking terbanyak',
                          subtitle: data.topBookingSummary,
                          icon: Icons.book_online_rounded,
                          onTap: onOpenPayments,
                        ),
                        _AdminActionTile(
                          title: 'Analytics global',
                          subtitle:
                              'Growth user, owner, revenue, okupansi, dan kota aktif.',
                          icon: Icons.analytics_rounded,
                          onTap: onOpenControl,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUserData>>(
      stream: FirestoreService.instance.allUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(label: 'Memuat pengguna...');
        }
        if (snapshot.hasError) {
          return _AdminAccessErrorPage(
            message: _streamErrorMessage(snapshot.error),
          );
        }

        final users = (snapshot.data ?? const <AppUserData>[]).where((user) {
          final query = _query.toLowerCase();
          if (query.isEmpty) {
            return true;
          }
          return user.name.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              user.role.toLowerCase().contains(query);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Kelola Pengguna'),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _SearchField(
                    hintText: 'Cari nama, email, atau role',
                    onChanged: (value) => setState(() => _query = value.trim()),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _AdminEntityTile(
                        title: user.name,
                        subtitle: '${user.email} | ${user.roleLabel}',
                        badge: user.accountStatus,
                        icon: Icons.person_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => AdminUserDetailPage(user: user),
                            ),
                          );
                        },
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemCount: users.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AdminOwnersPage extends StatefulWidget {
  const AdminOwnersPage({super.key});

  @override
  State<AdminOwnersPage> createState() => _AdminOwnersPageState();
}

class _AdminOwnersPageState extends State<AdminOwnersPage> {
  String _filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUserData>>(
      stream: FirestoreService.instance.ownerUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(label: 'Memuat data pemilik...');
        }
        if (snapshot.hasError) {
          return _AdminAccessErrorPage(
            message: _streamErrorMessage(snapshot.error),
          );
        }

        final owners = (snapshot.data ?? const <AppUserData>[]).where((owner) {
          if (_filter == 'Semua') {
            return true;
          }
          return owner.verificationStatus == _filter;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Verifikasi Pemilik'),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(
                  height: 52,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    scrollDirection: Axis.horizontal,
                    children:
                        [
                              'Semua',
                              'Pending',
                              'Terverifikasi',
                              'Ditolak',
                              'Suspended',
                            ]
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: ChoiceChip(
                                  label: Text(item),
                                  selected: _filter == item,
                                  onSelected: (_) =>
                                      setState(() => _filter = item),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    itemBuilder: (context, index) {
                      final owner = owners[index];
                      return _AdminEntityTile(
                        title: owner.name,
                        subtitle:
                            '${owner.email} | ${owner.bankAccountLabel} | ${owner.phoneNumber}',
                        badge: owner.verificationStatus,
                        icon: Icons.store_mall_directory_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  AdminOwnerDetailPage(owner: owner),
                            ),
                          );
                        },
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemCount: owners.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AdminListingsPage extends StatelessWidget {
  const AdminListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<KosData>>(
      stream: FirestoreService.instance.adminKosStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(label: 'Memuat listing kos...');
        }
        if (snapshot.hasError) {
          return _AdminAccessErrorPage(
            message: _streamErrorMessage(snapshot.error),
          );
        }

        final kosList = snapshot.data ?? const <KosData>[];
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Kelola Semua Kos'),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            itemBuilder: (context, index) {
              final kos = kosList[index];
              final status = kos.availableRooms == 0 ? 'Penuh' : 'Aktif';
              return _AdminEntityTile(
                title: kos.name,
                subtitle:
                    '${kos.area} | ${kos.availableRooms}/${kos.totalRooms} kamar | ${kos.ownerName}',
                badge: status,
                icon: Icons.apartment_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => AdminListingDetailPage(kos: kos),
                    ),
                  );
                },
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemCount: kosList.length,
          ),
        );
      },
    );
  }
}

class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  String _filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookingData>>(
      stream: FirestoreService.instance.allBookingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(label: 'Memuat transaksi aplikasi...');
        }
        if (snapshot.hasError) {
          return _AdminAccessErrorPage(
            message: _streamErrorMessage(snapshot.error),
          );
        }

        final bookings = (snapshot.data ?? const <BookingData>[]).where((
          booking,
        ) {
          switch (_filter) {
            case 'Pending':
              return booking.paymentStatus == 'Pending';
            case 'Failed':
              return booking.paymentStatus == 'Failed';
            case 'Refund':
              return booking.paymentStatus == 'Refund';
            case 'Lunas':
              return booking.paymentStatus == 'Lunas';
            default:
              return true;
          }
        }).toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Kelola Pembayaran'),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(
                  height: 52,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    scrollDirection: Axis.horizontal,
                    children: ['Semua', 'Pending', 'Lunas', 'Failed', 'Refund']
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text(item),
                              selected: _filter == item,
                              onSelected: (_) => setState(() => _filter = item),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return _AdminEntityTile(
                        title: booking.userName,
                        subtitle:
                            '${booking.kos.name} | ${booking.total} | ${booking.paymentMethod}',
                        badge: booking.paymentStatus,
                        icon: Icons.receipt_long_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  AdminPaymentDetailPage(booking: booking),
                            ),
                          );
                        },
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemCount: bookings.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AdminControlCenterPage extends StatelessWidget {
  const AdminControlCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Sistem & Moderasi'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            _AdminSectionCard(
              title: 'Moderasi & Laporan',
              subtitle: 'Komplain, mediasi, dan keputusan admin.',
              child: Column(
                children: [
                  _AdminActionTile(
                    title: 'Moderasi laporan',
                    subtitle:
                        'Penipuan, fasilitas bohong, toxic owner, dan spam booking.',
                    icon: Icons.gavel_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminReportsPage(),
                        ),
                      );
                    },
                  ),
                  _AdminActionTile(
                    title: 'Analytics global',
                    subtitle:
                        'Growth user, owner, revenue, kota aktif, dan okupansi.',
                    icon: Icons.analytics_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminAnalyticsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _AdminSectionCard(
              title: 'Konten & Notifikasi',
              subtitle: 'CMS, banner, FAQ, dan push notification center.',
              child: Column(
                children: [
                  _AdminActionTile(
                    title: 'CMS Koshub',
                    subtitle:
                        'Kelola banner homepage, promo, artikel, dan FAQ.',
                    icon: Icons.dashboard_customize_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminCmsPage(),
                        ),
                      );
                    },
                  ),
                  _AdminActionTile(
                    title: 'Push notification center',
                    subtitle:
                        'Broadcast promo, maintenance aplikasi, dan pengumuman global.',
                    icon: Icons.notifications_active_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminBroadcastPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _AdminSectionCard(
              title: 'Keamanan & Audit',
              subtitle: 'Session, activity, dan jejak perubahan sistem.',
              child: Column(
                children: [
                  _AdminActionTile(
                    title: 'Audit log',
                    subtitle:
                        'Track suspend owner, ubah harga, cancel booking, dan aksi admin.',
                    icon: Icons.history_edu_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminAuditLogPage(),
                        ),
                      );
                    },
                  ),
                  _AdminActionTile(
                    title: 'Pengaturan admin',
                    subtitle:
                        'Session timeout, login activity, dan emergency contact.',
                    icon: Icons.security_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminSettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
