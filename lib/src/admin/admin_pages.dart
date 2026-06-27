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
      stream: SupabaseService.instance.adminDashboardStream(),
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
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 156),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final contentWidth = constraints.maxWidth;
                  final isCompact = contentWidth < 360;
                  final metricColumns = contentWidth < 300
                      ? 1
                      : contentWidth >= 720
                      ? 4
                      : 2;
                  final metricWidth =
                      (contentWidth - (12 * (metricColumns - 1))) /
                      metricColumns;
                  final shortcutColumns = contentWidth < 320
                      ? 1
                      : contentWidth >= 720
                      ? 3
                      : 2;
                  final shortcutWidth =
                      (contentWidth - (10 * (shortcutColumns - 1))) /
                      shortcutColumns;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isCompact ? 18 : 22),
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
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isCompact ? 22 : 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${profile.roleLabel} Koshub | pusat aktivasi owner dan kontrol listing',
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
                                  label:
                                      '${data.ownerRequestsToday} pengajuan owner hari ini',
                                ),
                                _StatusBadge(
                                  label:
                                      '${data.pendingOwnerPayments} pembayaran menunggu cek',
                                ),
                                _StatusBadge(
                                  label:
                                      '${data.pendingListings} listing perlu review',
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
                          SizedBox(
                            width: metricWidth,
                            child: _AdminMetricCard(
                              label: 'Total Pengguna',
                              value: '${data.totalUsers}',
                              subtitle: 'Semua akun non-admin',
                              icon: Icons.groups_rounded,
                              onTap: onOpenUsers,
                            ),
                          ),
                          SizedBox(
                            width: metricWidth,
                            child: _AdminMetricCard(
                              label: 'Pemilik Aktif',
                              value: '${data.totalOwners}',
                              subtitle: 'Sudah diverifikasi admin',
                              icon: Icons.verified_user_rounded,
                              onTap: onOpenOwners,
                            ),
                          ),
                          SizedBox(
                            width: metricWidth,
                            child: _AdminMetricCard(
                              label: 'Listing Kos',
                              value: '${data.totalKos}',
                              subtitle:
                                  '${data.pendingListings} perlu moderasi',
                              icon: Icons.apartment_rounded,
                              onTap: onOpenListings,
                            ),
                          ),
                          SizedBox(
                            width: metricWidth,
                            child: _AdminMetricCard(
                              label: 'Pendapatan App',
                              value: _currency(data.platformRevenue),
                              subtitle: 'Dari aktivasi owner',
                              icon: Icons.payments_rounded,
                              onTap: onOpenPayments,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _AdminSectionCard(
                        title: 'Quick Control',
                        subtitle:
                            'Kelola pengguna, aktivasi pemilik, listing kos, banner, dan voucher.',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: shortcutWidth,
                              child: _AdminShortcutChip(
                                label: 'Kelola Pengguna',
                                icon: Icons.manage_accounts_rounded,
                                onTap: onOpenUsers,
                              ),
                            ),
                            SizedBox(
                              width: shortcutWidth,
                              child: _AdminShortcutChip(
                                label: 'Verifikasi Pemilik',
                                icon: Icons.fact_check_rounded,
                                onTap: onOpenOwners,
                              ),
                            ),
                            SizedBox(
                              width: shortcutWidth,
                              child: _AdminShortcutChip(
                                label: 'Moderasi Listing',
                                icon: Icons.approval_rounded,
                                onTap: onOpenListings,
                              ),
                            ),
                            SizedBox(
                              width: shortcutWidth,
                              child: _AdminShortcutChip(
                                label: 'Pembayaran Aktivasi',
                                icon: Icons.account_balance_wallet_rounded,
                                onTap: onOpenPayments,
                              ),
                            ),
                            SizedBox(
                              width: shortcutWidth,
                              child: _AdminShortcutChip(
                                label: 'CMS & Voucher',
                                icon: Icons.hub_rounded,
                                onTap: onOpenControl,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _AdminSectionCard(
                        title: 'Aktivitas Realtime',
                        subtitle: 'Alur terbaru pengajuan owner dan listing.',
                        child: data.recentActivities.isEmpty
                            ? const Text(
                                'Belum ada aktivitas terbaru.',
                                style: TextStyle(color: Color(0xFF5D6B6B)),
                              )
                            : Column(
                                children: data.recentActivities
                                    .map(
                                      (activity) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          backgroundColor: const Color(
                                            0xFFEAF1FF,
                                          ),
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
                        subtitle:
                            'Area yang paling sering perlu keputusan admin aplikasi.',
                        child: Column(
                          children: [
                            _AdminActionTile(
                              title: 'Owner terbaru',
                              subtitle: data.latestOwnerSummary,
                              icon: Icons.badge_rounded,
                              onTap: onOpenOwners,
                            ),
                            _AdminActionTile(
                              title: 'Listing teratas',
                              subtitle: data.topListingSummary,
                              icon: Icons.trending_up_rounded,
                              onTap: onOpenListings,
                            ),
                            _AdminActionTile(
                              title: 'Pembayaran aktivasi',
                              subtitle: data.latestPaymentSummary,
                              icon: Icons.receipt_long_rounded,
                              onTap: onOpenPayments,
                            ),
                            _AdminActionTile(
                              title: 'Analytics global',
                              subtitle:
                                  'User, owner aktif, listing, pending review, dan revenue owner activation.',
                              icon: Icons.analytics_rounded,
                              onTap: onOpenControl,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
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
  late final Stream<List<AppUserData>> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream = SupabaseService.instance.allUsersStream();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUserData>>(
      stream: _usersStream,
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
              user.roleLabel.toLowerCase().contains(query);
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 156),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final badge = user.hasOwnerRequest
                          ? user.verificationStatus
                          : user.accountStatus;
                      return _AdminEntityTile(
                        title: user.name,
                        subtitle: '${user.email} | ${user.roleLabel}',
                        badge: badge,
                        icon: Icons.person_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => user.hasOwnerRequest
                                  ? AdminOwnerDetailPage(owner: user)
                                  : AdminUserDetailPage(user: user),
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
      stream: SupabaseService.instance.ownerUsersStream(),
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
                              'Menunggu Pembayaran',
                              'Menunggu Verifikasi',
                              'Terverifikasi',
                              'Perlu Revisi',
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 156),
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

class AdminListingsPage extends StatefulWidget {
  const AdminListingsPage({super.key});

  @override
  State<AdminListingsPage> createState() => _AdminListingsPageState();
}

class _AdminListingsPageState extends State<AdminListingsPage> {
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<KosData>>(
      key: ValueKey(_refreshKey),
      stream: SupabaseService.instance.adminKosStream(),
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
            title: const Text('Moderasi Listing Kos'),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 156),
            itemBuilder: (context, index) {
              final kos = kosList[index];
              return _AdminEntityTile(
                title: kos.name,
                subtitle:
                    '${kos.area} | ${kos.availableRooms}/${kos.totalRooms} kamar | ${kos.ownerName}',
                badge: kos.listingStatusLabel,
                icon: Icons.apartment_rounded,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => AdminListingDetailPage(kos: kos),
                    ),
                  );
                  if (mounted) {
                    setState(() {
                      _refreshKey++;
                    });
                  }
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
    return StreamBuilder<List<AppUserData>>(
      stream: SupabaseService.instance.ownerUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(
            label: 'Memuat pembayaran aktivasi owner...',
          );
        }
        if (snapshot.hasError) {
          return _AdminAccessErrorPage(
            message: _streamErrorMessage(snapshot.error),
          );
        }

        final owners = (snapshot.data ?? const <AppUserData>[]).where((owner) {
          switch (_filter) {
            case 'Menunggu Konfirmasi':
              return owner.activationPaymentStatus == 'Menunggu Konfirmasi';
            case 'Lunas':
              return owner.activationPaymentStatus == 'Lunas';
            case 'Ditolak':
              return owner.activationPaymentStatus == 'Ditolak';
            case 'Belum Bayar':
              return owner.activationPaymentStatus == 'Belum Bayar';
            default:
              return true;
          }
        }).toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Pembayaran Aktivasi Owner'),
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
                              'Menunggu Konfirmasi',
                              'Lunas',
                              'Ditolak',
                              'Belum Bayar',
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 156),
                    itemBuilder: (context, index) {
                      final owner = owners[index];
                      return _AdminEntityTile(
                        title: owner.name,
                        subtitle:
                            '${owner.email} | ${_currency(owner.ownerNetActivationFee)} | ${owner.activationPaymentMethod}',
                        badge: owner.activationPaymentStatus,
                        icon: Icons.receipt_long_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  AdminPaymentDetailPage(owner: owner),
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

class AdminControlCenterPage extends StatelessWidget {
  const AdminControlCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Sistem & CMS Admin'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 156),
          children: [
            _AdminSectionCard(
              title: 'Moderasi & Review',
              subtitle:
                  'Fokus admin adalah validasi owner, listing, dan laporan aplikasi.',
              child: Column(
                children: [
                  _AdminActionTile(
                    title: 'Moderasi listing',
                    subtitle:
                        'Approve, hide, suspend, atau minta revisi listing kos.',
                    icon: Icons.approval_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminListingsPage(),
                        ),
                      );
                    },
                  ),
                  _AdminActionTile(
                    title: 'Analytics global',
                    subtitle:
                        'User, owner aktif, listing review, dan revenue aktivasi owner.',
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
              title: 'Konten & Promo',
              subtitle: 'Banner home dan voucher owner bisa dikelola langsung.',
              child: Column(
                children: [
                  _AdminActionTile(
                    title: 'CMS banner home',
                    subtitle:
                        'CRUD gambar hero dan promo yang tampil di halaman utama.',
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
                    title: 'Voucher owner',
                    subtitle:
                        'Atur kode voucher dan potongan harga aktivasi owner.',
                    icon: Icons.local_offer_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminOwnerVoucherPage(),
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
              subtitle: 'Pantau status akun, owner, dan perubahan penting.',
              child: Column(
                children: [
                  _AdminActionTile(
                    title: 'Audit log',
                    subtitle:
                        'Track status owner, pembayaran aktivasi, dan review akun.',
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
