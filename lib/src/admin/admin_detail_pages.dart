part of '../../main.dart';

class AdminUserDetailPage extends StatefulWidget {
  const AdminUserDetailPage({super.key, required this.user});

  final AppUserData user;

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage> {
  late String _accountStatus;
  late final TextEditingController _notesController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _accountStatus = widget.user.accountStatus;
    _notesController = TextEditingController(text: widget.user.adminNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

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
            title: widget.user.name,
            subtitle: '${widget.user.roleLabel} | ${widget.user.email}',
            badge: _accountStatus,
          ),
          const SizedBox(height: 16),
          _AdminSectionCard(
            title: 'Informasi Akun',
            subtitle: 'Ringkasan identitas dan status pengguna.',
            child: Column(
              children: [
                _DetailRow(label: 'Nomor HP', value: widget.user.phoneNumber),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Kontak darurat',
                  value: widget.user.emergencyContact,
                ),
                const SizedBox(height: 10),
                _DetailRow(label: 'KTP', value: widget.user.ktpNumber),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Login activity',
                  value: widget.user.loginActivity,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AdminSectionCard(
            title: 'Moderasi Pengguna',
            subtitle:
                'Role sistem tidak diubah dari sini. Admin cukup beri peringatan atau blokir akun bila perlu.',
            child: Column(
              children: [
                _DetailRow(label: 'Role akun', value: widget.user.roleLabel),
                const SizedBox(height: 10),
                _SelectCard(
                  label: 'Status akun',
                  value: _accountStatus,
                  items: const ['Aktif', 'Peringatan', 'Suspended', 'Diblokir'],
                  onChanged: (value) => setState(() => _accountStatus = value),
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _notesController,
                  label: 'Catatan admin',
                  hintText: 'Opsional, misalnya alasan peringatan atau blokir',
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF182022),
                      foregroundColor: Colors.white,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Simpan Perubahan'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SupabaseService.instance.updateUserModerationStatus(
        user: widget.user,
        accountStatus: _accountStatus,
        adminNotes: _notesController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      await _showLightDialog(
        context,
        title: 'Perubahan disimpan',
        message: 'Status moderasi pengguna berhasil diperbarui.',
      );
    } on SupabaseAppException catch (error) {
      if (!mounted) {
        return;
      }
      await _showLightDialog(
        context,
        title: 'Gagal menyimpan',
        message: _supabaseMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class AdminOwnerDetailPage extends StatefulWidget {
  const AdminOwnerDetailPage({super.key, required this.owner});

  final AppUserData owner;

  @override
  State<AdminOwnerDetailPage> createState() => _AdminOwnerDetailPageState();
}

class _AdminOwnerDetailPageState extends State<AdminOwnerDetailPage> {
  late final TextEditingController _notesController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.owner.adminNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final owner = widget.owner;
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
            subtitle:
                'Checklist yang dipakai admin sebelum mengaktifkan owner.',
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
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Pembayaran aktivasi',
                  value: owner.activationPaymentStatus,
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Nominal bersih',
                  value: _currency(owner.ownerNetActivationFee),
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Voucher',
                  value: owner.ownerVoucherCode.isEmpty
                      ? '-'
                      : owner.ownerVoucherCode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AdminSectionCard(
            title: 'Bukti Pembayaran',
            subtitle: 'Admin cukup monitor aktivasi owner, bukan sewa kos.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (owner.activationPaymentProofUrl.isEmpty)
                  const Text(
                    'Belum ada bukti pembayaran.',
                    style: TextStyle(
                      color: Color(0xFF35589F),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  _ImageProofPreview(
                    title: 'Bukti pembayaran aktivasi',
                    imageUrl: owner.activationPaymentProofUrl,
                  ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _notesController,
                  label: 'Catatan admin',
                  hintText: 'Misalnya: bukti jelas, perlu revisi, atau reject',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AdminSectionCard(
            title: 'Aksi Verifikasi',
            subtitle:
                'Approve akan mengaktifkan akun owner dan publish listingnya.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  onPressed: _loading ? null : () => _applyDecision('approve'),
                  child: const Text('Approve & Aktifkan'),
                ),
                FilledButton.tonal(
                  onPressed: _loading ? null : () => _applyDecision('revision'),
                  child: const Text('Minta Revisi'),
                ),
                FilledButton.tonal(
                  onPressed: _loading ? null : () => _applyDecision('reject'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE4E0),
                    foregroundColor: const Color(0xFF9F4035),
                  ),
                  child: const Text('Reject'),
                ),
                FilledButton.tonal(
                  onPressed: _loading ? null : () => _applyDecision('suspend'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEAEAEA),
                    foregroundColor: const Color(0xFF182022),
                  ),
                  child: const Text('Suspend'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyDecision(String decision) async {
    setState(() => _loading = true);
    try {
      await SupabaseService.instance.reviewOwnerApplication(
        owner: widget.owner,
        decision: decision,
        adminNotes: _notesController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      await _showLightDialog(
        context,
        title: 'Aksi berhasil',
        message: 'Status owner berhasil diperbarui.',
      );
    } on SupabaseAppException catch (error) {
      if (!mounted) {
        return;
      }
      await _showLightDialog(
        context,
        title: 'Aksi gagal',
        message: _supabaseMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class AdminListingDetailPage extends StatefulWidget {
  const AdminListingDetailPage({super.key, required this.kos});

  final KosData kos;

  @override
  State<AdminListingDetailPage> createState() => _AdminListingDetailPageState();
}

class _AdminListingDetailPageState extends State<AdminListingDetailPage> {
  late String _listingStatus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _listingStatus = widget.kos.listingStatus;
  }

  @override
  Widget build(BuildContext context) {
    final kos = widget.kos;
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
            badge: kos.listingStatusLabel,
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
                _DetailRow(label: 'Approval booking', value: kos.approvalMode),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AdminSectionCard(
            title: 'Moderasi Listing',
            subtitle:
                'Admin hanya moderasi listing, bukan pembayaran sewa kos.',
            child: Column(
              children: [
                _SelectCard(
                  label: 'Status listing',
                  value: _listingStatus,
                  items: const [
                    'active',
                    'pending_review',
                    'needs_revision',
                    'hidden',
                    'suspended',
                  ],
                  onChanged: (value) => setState(() => _listingStatus = value),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Simpan Moderasi'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SupabaseService.instance.updateKosListingStatus(
        kosId: widget.kos.id,
        listingStatus: _listingStatus,
      );
      if (!mounted) {
        return;
      }
      await _showLightDialog(
        context,
        title: 'Moderasi disimpan',
        message: 'Status listing berhasil diperbarui.',
      );
    } on SupabaseAppException catch (error) {
      if (!mounted) {
        return;
      }
      await _showLightDialog(
        context,
        title: 'Gagal menyimpan',
        message: _supabaseMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class AdminPaymentDetailPage extends StatefulWidget {
  const AdminPaymentDetailPage({super.key, required this.owner});

  final AppUserData owner;

  @override
  State<AdminPaymentDetailPage> createState() => _AdminPaymentDetailPageState();
}

class _AdminPaymentDetailPageState extends State<AdminPaymentDetailPage> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final owner = widget.owner;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detail Pembayaran Aktivasi'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _AdminDetailHeader(
            title: owner.name,
            subtitle: '${owner.email} | ${owner.activationPaymentMethod}',
            badge: owner.activationPaymentStatus,
          ),
          const SizedBox(height: 16),
          _AdminSectionCard(
            title: 'Ringkasan Pembayaran',
            subtitle: 'Panel finance admin untuk aktivasi akun owner.',
            child: Column(
              children: [
                _DetailRow(
                  label: 'Tanggal pengajuan',
                  value: owner.ownerApplicationSubmittedAt == null
                      ? '-'
                      : _formatLongDate(owner.ownerApplicationSubmittedAt!),
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Biaya dasar',
                  value: _currency(owner.ownerActivationFee),
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Diskon voucher',
                  value: _currency(owner.ownerActivationDiscount),
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Nominal dibayar',
                  value: _currency(owner.ownerNetActivationFee),
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Status',
                  value: owner.activationPaymentStatus,
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Bukti transfer',
                  value: owner.activationPaymentProofUrl.isEmpty
                      ? 'Belum ada'
                      : owner.activationPaymentProofUrl,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AdminSectionCard(
            title: 'Aksi Finance',
            subtitle:
                'Setelah pembayaran valid, admin bisa lanjut approve owner.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  onPressed: _loading ? null : () => _setStatus('Lunas'),
                  child: const Text('Tandai Lunas'),
                ),
                FilledButton.tonal(
                  onPressed: _loading
                      ? null
                      : () => _setStatus('Menunggu Konfirmasi'),
                  child: const Text('Masih Dicek'),
                ),
                FilledButton.tonal(
                  onPressed: _loading ? null : () => _setStatus('Ditolak'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE4E0),
                    foregroundColor: const Color(0xFF9F4035),
                  ),
                  child: const Text('Tolak Bukti'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setStatus(String status) async {
    setState(() => _loading = true);
    try {
      await SupabaseService.instance.updateActivationPaymentStatus(
        userId: widget.owner.id,
        paymentStatus: status,
      );
      if (!mounted) {
        return;
      }
      await _showLightDialog(
        context,
        title: 'Status diperbarui',
        message: 'Pembayaran aktivasi owner berhasil diperbarui.',
      );
    } on SupabaseAppException catch (error) {
      if (!mounted) {
        return;
      }
      await _showLightDialog(
        context,
        title: 'Gagal memperbarui',
        message: _supabaseMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<KosData>>(
      stream: SupabaseService.instance.adminKosStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AdminAccessErrorPage(
            message: _streamErrorMessage(snapshot.error),
          );
        }
        final reports = (snapshot.data ?? const <KosData>[]).where((kos) {
          return kos.listingStatus != 'active';
        }).toList();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Moderasi Listing'),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemBuilder: (context, index) {
              final item = reports[index];
              return _AdminEntityTile(
                title: item.name,
                subtitle: '${item.ownerName} | ${item.area}',
                badge: item.listingStatusLabel,
                icon: Icons.report_problem_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => AdminListingDetailPage(kos: item),
                    ),
                  );
                },
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
      stream: SupabaseService.instance.adminDashboardStream(),
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
                      label: 'Total pengguna',
                      value: '${data.totalUsers} akun',
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Pemilik aktif',
                      value: '${data.totalOwners} owner',
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Revenue aplikasi',
                      value: _currency(data.platformRevenue),
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Pengajuan owner hari ini',
                      value: '${data.ownerRequestsToday}',
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Pembayaran menunggu cek',
                      value: '${data.pendingOwnerPayments}',
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: 'Listing perlu review',
                      value: '${data.pendingListings}',
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
        title: const Text('CMS Banner Home'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBannerEditor(context),
        backgroundColor: const Color(0xFF182022),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text('Tambah Banner'),
      ),
      body: StreamBuilder<List<HomeBannerData>>(
        stream: SupabaseService.instance.homeBannersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen(label: 'Memuat banner home...');
          }
          if (snapshot.hasError) {
            return _AdminAccessErrorPage(
              message: _streamErrorMessage(snapshot.error),
            );
          }
          final items = snapshot.data ?? const <HomeBannerData>[];
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Belum ada banner home',
                subtitle:
                    'Tambahkan banner hero atau promo agar homepage bisa dikelola admin.',
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            itemBuilder: (context, index) {
              final banner = items[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        banner.imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      banner.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      banner.subtitle,
                      style: const TextStyle(color: Color(0xFF5D6B6B)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatusBadge(
                          label:
                              '${banner.placement} | ${banner.isActive ? 'Aktif' : 'Nonaktif'}',
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              _openBannerEditor(context, existing: banner),
                          child: const Text('Edit'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await SupabaseService.instance.deleteHomeBanner(
                              banner.id,
                            );
                          },
                          child: const Text(
                            'Hapus',
                            style: TextStyle(color: Color(0xFF9F4035)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}

class AdminOwnerVoucherPage extends StatelessWidget {
  const AdminOwnerVoucherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Voucher Owner'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openVoucherEditor(context),
        backgroundColor: const Color(0xFF182022),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Voucher'),
      ),
      body: StreamBuilder<List<OwnerVoucherData>>(
        stream: SupabaseService.instance.ownerVouchersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen(label: 'Memuat voucher owner...');
          }
          if (snapshot.hasError) {
            return _AdminAccessErrorPage(
              message: _streamErrorMessage(snapshot.error),
            );
          }
          final items = snapshot.data ?? const <OwnerVoucherData>[];
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Belum ada voucher owner',
                subtitle:
                    'Tambahkan voucher untuk memberi potongan harga aktivasi owner.',
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            itemBuilder: (context, index) {
              final voucher = items[index];
              return _AdminEntityTile(
                title: '${voucher.code} • ${voucher.title}',
                subtitle:
                    '${voucher.description} | Diskon ${_currency(voucher.discountAmount)}',
                badge: voucher.isActive ? 'Aktif' : 'Nonaktif',
                icon: Icons.local_offer_rounded,
                onTap: () => _openVoucherEditor(context, existing: voucher),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}

class AdminAuditLogPage extends StatelessWidget {
  const AdminAuditLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUserData>>(
      stream: SupabaseService.instance.ownerUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _AdminAccessErrorPage(
            message: _streamErrorMessage(snapshot.error),
          );
        }
        final items = snapshot.data ?? const <AppUserData>[];
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Audit Log'),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemBuilder: (context, index) {
              final owner = items[index];
              final date = owner.ownerApplicationSubmittedAt ?? owner.createdAt;
              return _AdminEntityTile(
                title: owner.name,
                subtitle:
                    '${owner.activationPaymentStatus} | ${owner.verificationStatus} | ${owner.accountStatus}',
                badge: _formatLongDate(date),
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
    final user = SupabaseAuth.instance.currentUser;
    final email = user?.email ?? '-';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Pengaturan Admin'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _AdminSectionCard(
            title: 'Akun Admin',
            subtitle: 'Kelola sesi akun admin yang sedang aktif.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Login sebagai',
                  style: TextStyle(
                    color: const Color(0xFF5D6B6B),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFF182022),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gunakan tombol di bawah ini kalau mau keluar dari dashboard admin.',
                  style: TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async =>
                        _confirmAdminLogout(context, email: email),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text('Logout $email'),
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

Future<void> _openBannerEditor(
  BuildContext context, {
  HomeBannerData? existing,
}) async {
  final titleController = TextEditingController(text: existing?.title ?? '');
  final subtitleController = TextEditingController(
    text: existing?.subtitle ?? '',
  );
  final imageController = TextEditingController(text: existing?.imageUrl ?? '');
  var placement = existing?.placement ?? 'hero';
  var isActive = existing?.isActive ?? true;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(existing == null ? 'Tambah Banner' : 'Edit Banner'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _InputField(
                    controller: titleController,
                    label: 'Judul',
                    hintText: 'Judul banner',
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: subtitleController,
                    label: 'Subjudul',
                    hintText: 'Subjudul banner',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: imageController,
                    label: 'URL gambar',
                    hintText: 'Tempel URL gambar banner',
                  ),
                  const SizedBox(height: 12),
                  _SelectCard(
                    label: 'Placement',
                    value: placement,
                    items: const ['hero', 'promo'],
                    onChanged: (value) => setState(() => placement = value),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    title: const Text('Aktifkan banner'),
                    onChanged: (value) => setState(() => isActive = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () async {
                  if (titleController.text.trim().isEmpty ||
                      imageController.text.trim().isEmpty) {
                    await _showLightDialog(
                      context,
                      title: 'Data belum lengkap',
                      message: 'Judul dan URL gambar banner wajib diisi.',
                    );
                    return;
                  }
                  try {
                    await SupabaseService.instance.saveHomeBanner(
                      bannerId: existing?.id,
                      title: titleController.text.trim(),
                      subtitle: subtitleController.text.trim(),
                      imageUrl: imageController.text.trim(),
                      placement: placement,
                      isActive: isActive,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } on SupabaseAppException catch (error) {
                    if (!context.mounted) {
                      return;
                    }
                    await _showLightDialog(
                      context,
                      title: 'Banner gagal disimpan',
                      message: _supabaseMessage(error),
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _openVoucherEditor(
  BuildContext context, {
  OwnerVoucherData? existing,
}) async {
  final codeController = TextEditingController(text: existing?.code ?? '');
  final titleController = TextEditingController(text: existing?.title ?? '');
  final descriptionController = TextEditingController(
    text: existing?.description ?? '',
  );
  final discountController = TextEditingController(
    text: existing == null ? '' : existing.discountAmount.toString(),
  );
  var isActive = existing?.isActive ?? true;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(existing == null ? 'Tambah Voucher' : 'Edit Voucher'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _InputField(
                    controller: codeController,
                    label: 'Kode voucher',
                    hintText: 'Contoh: OWNERHEMAT',
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: titleController,
                    label: 'Judul voucher',
                    hintText: 'Contoh: Promo owner baru',
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: descriptionController,
                    label: 'Deskripsi',
                    hintText: 'Jelaskan syarat atau tujuan voucher',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _InputField(
                    controller: discountController,
                    label: 'Potongan harga',
                    hintText: 'Contoh: 50000',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    title: const Text('Voucher aktif'),
                    onChanged: (value) => setState(() => isActive = value),
                  ),
                ],
              ),
            ),
            actions: [
              if (existing != null)
                TextButton(
                  onPressed: () async {
                    await SupabaseService.instance.deleteOwnerVoucher(
                      existing.id,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Hapus',
                    style: TextStyle(color: Color(0xFF9F4035)),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () async {
                  if (codeController.text.trim().isEmpty ||
                      titleController.text.trim().isEmpty ||
                      discountController.text.trim().isEmpty) {
                    await _showLightDialog(
                      context,
                      title: 'Data belum lengkap',
                      message:
                          'Kode voucher, judul, dan potongan harga wajib diisi.',
                    );
                    return;
                  }
                  try {
                    await SupabaseService.instance.saveOwnerVoucher(
                      voucherId: existing?.id,
                      code: codeController.text.trim(),
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      discountAmount:
                          int.tryParse(discountController.text.trim()) ?? 0,
                      isActive: isActive,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } on SupabaseAppException catch (error) {
                    if (!context.mounted) {
                      return;
                    }
                    await _showLightDialog(
                      context,
                      title: 'Voucher gagal disimpan',
                      message: _supabaseMessage(error),
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );
    },
  );
}
