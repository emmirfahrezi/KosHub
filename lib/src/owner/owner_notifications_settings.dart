part of '../../main.dart';

class OwnerNotificationsPage extends StatefulWidget {
  const OwnerNotificationsPage({
    super.key,
    required this.bookings,
    required this.kos,
  });

  final List<BookingData> bookings;
  final KosData? kos;

  @override
  State<OwnerNotificationsPage> createState() => _OwnerNotificationsPageState();
}

class _OwnerNotificationsPageState extends State<OwnerNotificationsPage> {
  final Set<String> _locallyReadKeys = <String>{};

  @override
  Widget build(BuildContext context) {
    final user = SupabaseAuth.instance.currentUser!;

    return _OwnerNotificationFeed(
      userId: user.id,
      bookings: widget.bookings,
      locallyReadKeys: _locallyReadKeys,
      builder: (context, notifications) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Notifikasi'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              if (widget.kos != null)
                _OwnerSectionCard(
                  title: 'Kos aktif',
                  subtitle: '${widget.kos!.name} - ${widget.kos!.area}',
                  child: const Text(
                    'Semua notifikasi di bawah akan mengarahkan kamu ke halaman yang terkait.',
                  ),
                ),
              if (notifications.isNotEmpty) const SizedBox(height: 16),
              if (notifications.isEmpty)
                const _EmptyStateCard(
                  title: 'Belum ada notifikasi',
                  subtitle:
                      'Booking baru dan aktivitas penting penghuni akan muncul di sini.',
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
                      onTap: () => _openNotification(item),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEAF5F5),
                        child: Icon(item.icon, color: const Color(0xFF006A6A)),
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
      },
    );
  }

  Future<void> _openNotification(_OwnerNotificationData notification) async {
    setState(() => _locallyReadKeys.add(notification.key));
    try {
      await SupabaseService.instance.markNotificationRead(notification.key);
    } catch (_) {
      if (mounted) {
        setState(() => _locallyReadKeys.remove(notification.key));
      }
      return;
    }
    if (mounted) {
      await notification.open(context);
    }
  }
}

class _OwnerNotificationBadgeButton extends StatefulWidget {
  const _OwnerNotificationBadgeButton({
    required this.bookings,
    required this.kos,
  });

  final List<BookingData> bookings;
  final KosData? kos;

  @override
  State<_OwnerNotificationBadgeButton> createState() =>
      _OwnerNotificationBadgeButtonState();
}

class _OwnerNotificationBadgeButtonState
    extends State<_OwnerNotificationBadgeButton> {
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final user = SupabaseAuth.instance.currentUser!;
    return _OwnerNotificationFeed(
      key: ValueKey(_refreshKey),
      userId: user.id,
      bookings: widget.bookings,
      builder: (context, notifications) {
        final count = notifications.length;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Badge(
            isLabelVisible: count > 0,
            backgroundColor: const Color(0xFFD92D20),
            label: Text(count > 99 ? '99+' : '$count'),
            child: IconButton(
              tooltip: 'Notifikasi',
              onPressed: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => OwnerNotificationsPage(
                      bookings: widget.bookings,
                      kos: widget.kos,
                    ),
                  ),
                );
                if (mounted) {
                  setState(() => _refreshKey++);
                }
              },
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        );
      },
    );
  }
}

class _OwnerNotificationFeed extends StatelessWidget {
  const _OwnerNotificationFeed({
    super.key,
    required this.userId,
    required this.bookings,
    required this.builder,
    this.locallyReadKeys = const <String>{},
  });

  final String userId;
  final List<BookingData> bookings;
  final Set<String> locallyReadKeys;
  final Widget Function(
    BuildContext context,
    List<_OwnerNotificationData> notifications,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatPreviewData>>(
      stream: SupabaseService.instance.userChatsStream(userId),
      builder: (context, chatsSnapshot) {
        return StreamBuilder<Set<String>>(
          stream: SupabaseService.instance.notificationReadKeysStream(userId),
          builder: (context, readsSnapshot) {
            final readKeys = <String>{
              ...?readsSnapshot.data,
              ...locallyReadKeys,
            };
            final notifications =
                _ownerNotifications(
                  userId: userId,
                  chats: chatsSnapshot.data ?? const <ChatPreviewData>[],
                  bookings: bookings,
                )..removeWhere(
                  (notification) => readKeys.contains(notification.key),
                );
            notifications.sort((a, b) => b.sortKey.compareTo(a.sortKey));
            return builder(context, notifications);
          },
        );
      },
    );
  }
}

List<_OwnerNotificationData> _ownerNotifications({
  required String userId,
  required List<ChatPreviewData> chats,
  required List<BookingData> bookings,
}) {
  final notifications = <_OwnerNotificationData>[];

  for (final chat in chats.where(
    (chat) =>
        chat.lastMessage.isNotEmpty &&
        chat.lastSenderId.isNotEmpty &&
        chat.lastSenderId != userId,
  )) {
    notifications.add(
      _OwnerNotificationData(
        key: 'chat:${chat.id}:${chat.sortKey.microsecondsSinceEpoch}',
        title: 'Pesan terbaru dari ${chat.displayNameFor(userId)}',
        subtitle: chat.lastMessage,
        icon: Icons.chat_bubble_rounded,
        sortKey: chat.sortKey,
        open: (context) => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ChatDetailPage(kos: chat.kos, chatId: chat.id),
          ),
        ),
      ),
    );
  }

  for (final booking in bookings.where(
    (booking) => booking.status == 'Menunggu Konfirmasi',
  )) {
    notifications.add(
      _OwnerNotificationData(
        key: 'owner:booking:${booking.id}:${booking.status}',
        title: 'Ada booking baru',
        subtitle: '${booking.userName} booking ${booking.roomLabel}',
        icon: Icons.fact_check_rounded,
        sortKey: booking.sortKey,
        open: (context) => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => OwnerBookingDetailPage(booking: booking),
          ),
        ),
      ),
    );
  }

  for (final booking in bookings.where(
    (booking) =>
        booking.status == 'Sudah Check-in' && booking.note.trim().isNotEmpty,
  )) {
    notifications.add(
      _OwnerNotificationData(
        key: 'owner:resident-note:${booking.id}',
        title: 'Penghuni aktif perlu dicek',
        subtitle: '${booking.userName} punya catatan aktif untuk ditinjau',
        icon: Icons.person_rounded,
        sortKey: booking.sortKey,
        open: (context) => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ResidentDetailPage(booking: booking),
          ),
        ),
      ),
    );
  }
  return notifications;
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
                    photoUrl: profile?.photoUrl ?? user.photoURL ?? '',
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
                        _SummaryRow(
                          label: 'Nomor HP',
                          value:
                              profile?.phoneNumber.trim().isNotEmpty == true &&
                                  profile?.phoneNumber != '-'
                              ? profile!.phoneNumber
                              : 'Belum diisi',
                        ),
                        const SizedBox(height: 6),
                        _SummaryRow(
                          label: 'Rekening pembayaran',
                          value:
                              profile?.bankAccountLabel.trim().isNotEmpty ==
                                      true &&
                                  profile?.bankAccountLabel != 'Belum diisi'
                              ? profile!.bankAccountLabel
                              : 'Belum diisi',
                        ),
                        const SizedBox(height: 6),
                        const _SummaryRow(
                          label: 'Jam operasional',
                          value: '08.00 - 21.00',
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => TenantProfileEditPage(
                                    profile: profile,
                                    pageTitle: 'Edit Profil Owner',
                                    introText:
                                        'Ubah data akun owner seperti nama, nomor HP, dan foto profil. Password dipisah ke halaman khusus agar lebih aman.',
                                    passwordPageTitle: 'Ubah Password Owner',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Edit Profil Akun'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProfileMenuTile(
                    icon: Icons.edit_rounded,
                    title: 'Edit Profil Kos',
                    subtitle:
                        'Ubah nama kos, alamat, foto, dan fasilitas',
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
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Rekening Pembayaran',
                    subtitle:
                        'Isi nomor rekening, nama bank, dan atas nama untuk transfer booking',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              OwnerBankAccountPage(profile: profile),
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

class OwnerBankAccountPage extends StatefulWidget {
  const OwnerBankAccountPage({super.key, required this.profile});

  final AppUserData? profile;

  @override
  State<OwnerBankAccountPage> createState() => _OwnerBankAccountPageState();
}

class _OwnerBankAccountPageState extends State<OwnerBankAccountPage> {
  late final TextEditingController _bankAccountController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bankAccountController = TextEditingController(
      text: widget.profile?.bankAccountLabel == 'Belum diisi'
          ? ''
          : widget.profile?.bankAccountLabel ?? '',
    );
  }

  @override
  void dispose() {
    _bankAccountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Rekening Pembayaran'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'Masukkan rekening penerima yang akan ditampilkan ke penyewa saat transfer booking. Tulis lengkap nama bank, nomor rekening, dan atas nama.',
              style: TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
            ),
          ),
          const SizedBox(height: 20),
          _InputField(
            controller: _bankAccountController,
            label: 'Rekening penerima',
            hintText: 'Contoh: BCA 1234567890 a.n Nama Pemilik',
            maxLines: 2,
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF006A6A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Simpan Rekening'),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final user = SupabaseAuth.instance.currentUser;
    if (user == null) {
      _showLightDialog(
        context,
        title: 'Sesi tidak ditemukan',
        message: 'Silakan login ulang untuk menyimpan rekening pembayaran.',
      );
      return;
    }

    final bankAccount = _bankAccountController.text.trim();
    if (bankAccount.isEmpty) {
      _showLightDialog(
        context,
        title: 'Rekening belum diisi',
        message:
            'Masukkan nama bank, nomor rekening, dan atas nama penerima terlebih dulu.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await SupabaseService.instance.updateOwnerBankAccount(
        user: user,
        bankAccount: bankAccount,
      );
      if (!mounted) {
        return;
      }
      await _showLightDialog(
        context,
        title: 'Rekening diperbarui',
        message: 'Rekening pembayaran owner berhasil disimpan.',
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    } on SupabaseAppException catch (error) {
      if (!mounted) {
        return;
      }
      _showLightDialog(
        context,
        title: 'Rekening belum tersimpan',
        message: _supabaseMessage(error),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showLightDialog(
        context,
        title: 'Rekening belum tersimpan',
        message: 'Terjadi kendala saat menyimpan rekening. Coba lagi.',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sortKey,
    required this.open,
  });

  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final DateTime sortKey;
  final Future<void> Function(BuildContext context) open;
}
