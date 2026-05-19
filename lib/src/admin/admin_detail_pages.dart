part of '../../main.dart';

class AdminUserDetailPage extends StatelessWidget {
  const AdminUserDetailPage({super.key, required this.user});

  final AppUserData user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detail Pengguna'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _AdminDetailHeader(
            title: user.name,
            subtitle: '${user.roleLabel} | ${user.email}',
            badge: user.accountStatus,
          ),
          const SizedBox(height: 16),
          _AdminSectionCard(
            title: 'Informasi Akun',
            subtitle: 'Ringkasan identitas dan keamanan akun.',
            child: Column(
              children: [
                _DetailRow(label: 'Nomor HP', value: user.phoneNumber),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Kontak darurat',
                  value: user.emergencyContact,
                ),
                const SizedBox(height: 10),
                _DetailRow(label: 'KTP', value: user.ktpNumber),
                const SizedBox(height: 10),
                _DetailRow(label: 'Login activity', value: user.loginActivity),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AdminSectionCard(
            title: 'Aksi Admin',
            subtitle: 'Tindakan umum untuk pengawasan akun.',
            child: Column(
              children: const [
                _StaticActionLine('Suspend akun sementara'),
                _StaticActionLine('Ban akun bila terindikasi scam'),
                _StaticActionLine('Reset status atau minta verifikasi ulang'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminOwnerDetailPage extends StatelessWidget {
  const AdminOwnerDetailPage({super.key, required this.owner});

  final AppUserData owner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detail Pemilik'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _AdminDetailHeader(
            title: owner.name,
            subtitle: owner.email,
            badge: owner.verificationStatus,
          ),
          const SizedBox(height: 16),
          _AdminSectionCard(
            title: 'Data Verifikasi',
            subtitle: 'Checklist yang bisa dipakai admin saat approve.',
            child: Column(
              children: [
                _DetailRow(label: 'Nomor HP', value: owner.phoneNumber),
                const SizedBox(height: 10),
                _DetailRow(label: 'Rekening', value: owner.bankAccountLabel),
                const SizedBox(height: 10),
                _DetailRow(label: 'KTP', value: owner.ktpNumber),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Kontak darurat',
                  value: owner.emergencyContact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AdminSectionCard(
            title: 'Aksi Verifikasi',
            subtitle: 'Approve, reject, suspend, atau minta revisi data.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _StaticBadgeChip('Approve'),
                _StaticBadgeChip('Reject'),
                _StaticBadgeChip('Suspend'),
                _StaticBadgeChip('Minta revisi'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminListingDetailPage extends StatelessWidget {
  const AdminListingDetailPage({super.key, required this.kos});

  final KosData kos;

  @override
  Widget build(BuildContext context) {
    final occupantCount = kos.totalRooms - kos.availableRooms;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detail Listing'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _AdminDetailHeader(
            title: kos.name,
            subtitle: '${kos.ownerName} | ${kos.area}',
            badge: kos.availableRooms == 0 ? 'Penuh' : 'Aktif',
          ),
          const SizedBox(height: 16),
          _AdminSectionCard(
            title: 'Detail Kos',
            subtitle: 'Status listing dan operasional kamar.',
            child: Column(
              children: [
                _DetailRow(label: 'Alamat', value: kos.address),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Harga',
                  value: '${_currency(kos.price)} / bulan',
                ),
                const SizedBox(height: 10),
                _DetailRow(label: 'Kamar terisi', value: '$occupantCount'),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Kamar tersedia',
                  value: '${kos.availableRooms}',
                ),
                const SizedBox(height: 10),
                _DetailRow(label: 'Approval', value: kos.approvalMode),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AdminSectionCard(
            title: 'Moderasi Listing',
            subtitle: 'Tindakan admin untuk kos aktif atau bermasalah.',
            child: Column(
              children: const [
                _StaticActionLine('Edit listing atau koreksi data'),
                _StaticActionLine('Hide kos atau suspend sementara'),
                _StaticActionLine('Tandai kos bermasalah atau hapus permanen'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminPaymentDetailPage extends StatelessWidget {
  const AdminPaymentDetailPage({super.key, required this.booking});

  final BookingData booking;

  @override
  Widget build(BuildContext context) {
    final appFee = (booking.totalPrice * 0.05).round();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detail Pembayaran'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _AdminDetailHeader(
            title: booking.userName,
            subtitle: '${booking.kos.name} | ${booking.paymentMethod}',
            badge: booking.paymentStatus,
          ),
          const SizedBox(height: 16),
          _AdminSectionCard(
            title: 'Ringkasan Transaksi',
            subtitle: 'Panel finance admin untuk approval dan reminder.',
            child: Column(
              children: [
                _DetailRow(
                  label: 'Tanggal booking',
                  value: _formatLongDate(booking.sortKey),
                ),
                const SizedBox(height: 10),
                _DetailRow(label: 'Nominal', value: booking.total),
                const SizedBox(height: 10),
                _DetailRow(label: 'Fee aplikasi', value: _currency(appFee)),
                const SizedBox(height: 10),
                _DetailRow(label: 'Status', value: booking.paymentStatus),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Bukti transfer',
                  value: booking.paymentProofUrl.isEmpty
                      ? 'Belum ada'
                      : booking.paymentProofUrl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookingData>>(
      stream: FirestoreService.instance.allBookingsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AdminAccessErrorPage(
            message: _streamErrorMessage(snapshot.error),
          );
        }
        final reports = (snapshot.data ?? const <BookingData>[]).where((
          booking,
        ) {
          return booking.note.isNotEmpty || booking.cancelReason.isNotEmpty;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Moderasi Laporan'),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemBuilder: (context, index) {
              final item = reports[index];
              return _AdminEntityTile(
                title: item.userName,
                subtitle: item.note.isNotEmpty ? item.note : item.cancelReason,
                badge: item.cancelReason.isEmpty ? 'Diproses' : 'Selesai',
                icon: Icons.report_problem_rounded,
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemCount: reports.length,
          ),
        );
      },
    );
  }
}

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AdminDashboardData>(
      stream: FirestoreService.instance.adminDashboardStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AdminAccessErrorPage(
            message: _streamErrorMessage(snapshot.error),
          );
        }
        final data = snapshot.data ?? AdminDashboardData.empty();
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Analytics Global'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _AdminSectionCard(
                title: 'KPI Global',
                subtitle: 'Snapshot bisnis aplikasi saat ini.',
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Growth user',
                      value: '${data.totalUsers} akun',
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Growth owner',
                      value: '${data.totalOwners} owner',
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Revenue',
                      value: _currency(data.platformRevenue),
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Booking hari ini',
                      value: '${data.bookingsToday}',
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Kamar aktif terisi',
                      value: '${data.activeRooms}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AdminCmsPage extends StatelessWidget {
  const AdminCmsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('CMS Koshub'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: const [
          _AdminSectionCard(
            title: 'Konten Utama',
            subtitle: 'Kelola materi yang tampil ke seluruh user.',
            child: Column(
              children: [
                _StaticActionLine('Banner homepage'),
                _StaticActionLine('Promo dan campaign'),
                _StaticActionLine('Artikel tips kos'),
                _StaticActionLine('FAQ dan notifikasi global'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminBroadcastPage extends StatelessWidget {
  const AdminBroadcastPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Push Notification Center'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: const [
          _AdminSectionCard(
            title: 'Broadcast',
            subtitle: 'Pusat pengumuman untuk promo, maintenance, dan event.',
            child: Column(
              children: [
                _StaticActionLine('Promo owner premium'),
                _StaticActionLine('Maintenance aplikasi'),
                _StaticActionLine('Event dan pengumuman umum'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminAuditLogPage extends StatelessWidget {
  const AdminAuditLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookingData>>(
      stream: FirestoreService.instance.allBookingsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AdminAccessErrorPage(
            message: _streamErrorMessage(snapshot.error),
          );
        }
        final items = snapshot.data ?? const <BookingData>[];
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Audit Log'),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemBuilder: (context, index) {
              final booking = items[index];
              return _AdminEntityTile(
                title: 'Booking ${booking.kos.name}',
                subtitle:
                    '${booking.userName} | ${booking.status} | ${booking.paymentStatus}',
                badge: _formatLongDate(booking.sortKey),
                icon: Icons.history_rounded,
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemCount: items.length,
          ),
        );
      },
    );
  }
}

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Pengaturan Admin'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _AdminSectionCard(
            title: 'Security',
            subtitle: 'Baseline untuk akun dengan akses tertinggi.',
            child: Column(
              children: [
                const _StaticActionLine(
                  'Password disimpan terenkripsi di Firebase Auth',
                ),
                const _StaticActionLine(
                  'Role gating untuk area admin aplikasi',
                ),
                const _StaticActionLine(
                  'Siapkan OTP, 2FA, session timeout 15-30 menit, dan device recognition',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async => FirebaseAuth.instance.signOut(),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text('Logout ${user?.email ?? ''}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF182022),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
