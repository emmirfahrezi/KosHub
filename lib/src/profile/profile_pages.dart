part of '../../main.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<AppUserData?>(
        stream: FirestoreService.instance.userProfileStream(user.uid),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final isOwner = profile?.role == 'pemilik';
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              _ProfileHeader(
                name: profile?.name ?? user.displayName ?? 'Pengguna KosHub',
                email: profile?.email ?? user.email ?? '-',
                role: profile?.role ?? 'penyewa',
              ),
              if (!isOwner) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: 'Nomor HP',
                        value:
                            profile?.phoneNumber == null ||
                                profile!.phoneNumber == '-' ||
                                profile.phoneNumber.isEmpty
                            ? 'Belum diisi'
                            : profile.phoneNumber,
                      ),
                      const SizedBox(height: 10),
                      _SummaryRow(
                        label: 'Role akun',
                        value: profile?.roleLabel ?? 'Penyewa',
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    TenantProfileEditPage(profile: profile),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit Profil'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _ProfileMenuTile(
                icon: Icons.person_outline_rounded,
                title: 'Data Diri',
                subtitle: isOwner
                    ? 'Buka pengaturan akun pemilik dan profil kos'
                    : 'Lihat dan ubah profil penyewa',
                onTap: isOwner
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const OwnerSettingsPage(),
                          ),
                        );
                      }
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                TenantProfileEditPage(profile: profile),
                          ),
                        );
                      },
              ),
              _ProfileMenuTile(
                icon: Icons.receipt_long_rounded,
                title: 'Riwayat Transaksi',
                subtitle: 'Pantau status pembayaran dan booking',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => isOwner
                          ? const OwnerTransactionsPage()
                          : const BookingHistoryPage(),
                    ),
                  );
                },
              ),
              _ProfileMenuTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Chat Aktif',
                subtitle: 'Semua percakapan realtime tersimpan di Firestore',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ChatListPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              if (isOwner)
                StreamBuilder<KosData?>(
                  stream: FirestoreService.instance.ownerKosStream(user.uid),
                  builder: (context, ownerKosSnapshot) {
                    if (ownerKosSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const _ProfileMenuTile(
                        icon: Icons.storefront_rounded,
                        title: 'Akun Pemilik Aktif',
                        subtitle: 'Memuat data listing kos...',
                      );
                    }

                    final ownerKos = ownerKosSnapshot.data;

                    return Column(
                      children: [
                        _ProfileMenuTile(
                          icon: Icons.storefront_rounded,
                          title: 'Akun Pemilik Aktif',
                          subtitle: ownerKos == null
                              ? 'Akunmu sudah jadi pemilik. Lengkapi listing pertama agar tampil di halaman utama.'
                              : 'Akun pemilik aktif. Booking sudah dinonaktifkan dan listing bisa kamu edit kapan saja.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const OwnerSettingsPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => OwnerRegistrationPage(
                                  existingKos: ownerKos,
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            ownerKos == null
                                ? Icons.add_business_rounded
                                : Icons.edit_rounded,
                          ),
                          label: Text(
                            ownerKos == null
                                ? 'Lengkapi Listing Kos'
                                : 'Edit Listing Kos',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF006A6A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    );
                  },
                )
              else
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const OwnerRegistrationPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.store_mall_directory_rounded),
                  label: const Text('Daftar Menjadi Pemilik Kos'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006A6A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              Container(
                margin: const EdgeInsets.only(top: 12),
                child: FilledButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Keluar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF9F4035),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class TenantProfileEditPage extends StatefulWidget {
  const TenantProfileEditPage({super.key, required this.profile});

  final AppUserData? profile;

  @override
  State<TenantProfileEditPage> createState() => _TenantProfileEditPageState();
}

class _TenantProfileEditPageState extends State<TenantProfileEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _photoController;
  final _passwordController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(
      text: widget.profile?.name ?? user?.displayName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.profile?.phoneNumber == '-'
          ? ''
          : widget.profile?.phoneNumber ?? '',
    );
    _photoController = TextEditingController(
      text: widget.profile?.photoUrl ?? user?.photoURL ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _photoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: Colors.white,
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
              'Ubah data profil penyewa tanpa mengubah gaya halaman utama. Password bersifat opsional.',
              style: TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
            ),
          ),
          const SizedBox(height: 20),
          _InputField(
            controller: _nameController,
            label: 'Nama pengguna',
            hintText: 'Masukkan nama lengkap',
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _phoneController,
            label: 'Nomor HP',
            hintText: 'Contoh: 081234567890',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _photoController,
            label: 'URL foto profil',
            hintText: 'Tempel link foto profil',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _passwordController,
            label: 'Password baru',
            hintText: 'Kosongkan jika tidak ingin mengubah password',
            obscureText: true,
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
              : const Text('Simpan Perubahan'),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLightDialog(
        context,
        title: 'Sesi tidak ditemukan',
        message: 'Silakan login ulang untuk mengubah profil.',
      );
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      _showLightDialog(
        context,
        title: 'Data belum lengkap',
        message: 'Nama dan nomor HP wajib diisi.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirestoreService.instance.updateTenantProfile(
        user: user,
        name: name,
        phoneNumber: phone,
        photoUrl: _photoController.text.trim(),
        newPassword: _passwordController.text.trim().isEmpty
            ? null
            : _passwordController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      await _showLightDialog(
        context,
        title: 'Profil diperbarui',
        message: 'Data profil anda berhasil disimpan.',
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      _showLightDialog(
        context,
        title: 'Password belum bisa diubah',
        message: error.message ?? 'Silakan login ulang lalu coba lagi.',
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      _showLightDialog(
        context,
        title: 'Profil gagal disimpan',
        message: _firebaseMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
