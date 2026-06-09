part of '../../main.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<AppUserData?>(
        stream: SupabaseService.instance.userProfileStream(user.id),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final isOwner = profile?.canAccessOwnerShell == true;
          final hasOwnerRequest = profile?.hasOwnerRequest == true;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              _ProfileHeader(
                name: profile?.name ?? user.displayName ?? 'Pengguna KosHub',
                email: profile?.email ?? user.email ?? '-',
                role: profile?.roleLabel ?? 'Penyewa',
                photoUrl: profile?.photoUrl ?? user.photoURL ?? '',
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
              if (hasOwnerRequest && !isOwner) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Pengajuan Pemilik Kos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _StatusBadge(
                            label: profile?.verificationStatus ?? '-',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: 'Status akun',
                        value: profile?.accountStatus ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: 'Status pembayaran',
                        value: profile?.activationPaymentStatus ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: 'Biaya aktivasi',
                        value: _currency(profile?.ownerNetActivationFee ?? 0),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile?.adminNotes.trim().isNotEmpty == true
                            ? profile!.adminNotes
                            : 'Admin akan mengaktifkan akun owner setelah bukti pembayaran dan data listing kamu valid.',
                        style: const TextStyle(
                          color: Color(0xFF5D6B6B),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _ProfileMenuTile(
                icon: Icons.receipt_long_rounded,
                title: isOwner ? 'Daftar Booking' : 'Riwayat Transaksi',
                subtitle: isOwner
                    ? 'Lihat booking masuk dan statusnya'
                    : 'Pantau status pembayaran dan booking',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => isOwner
                          ? const OwnerBookingPage(initialTab: 0)
                          : const BookingHistoryPage(),
                    ),
                  );
                },
              ),
              _ProfileMenuTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Chat Aktif',
                subtitle: 'Lihat dan lanjutkan percakapan dengan pemilik kos',
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
                  stream: SupabaseService.instance.ownerManagedKosStream(
                    user.id,
                  ),
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
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const OwnerSettingsPage(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(Icons.manage_accounts_rounded),
                            label: const Text('Edit Profil Owner'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => OwnerRegistrationPage(
                                    existingKos: ownerKos,
                                    profile: profile,
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
                        ),
                      ],
                    );
                  },
                )
              else
                StreamBuilder<KosData?>(
                  stream: SupabaseService.instance.ownerManagedKosStream(
                    user.id,
                  ),
                  builder: (context, ownerKosSnapshot) {
                    final ownerKos = ownerKosSnapshot.data;
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => OwnerRegistrationPage(
                                existingKos: ownerKos,
                                profile: profile,
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          hasOwnerRequest
                              ? Icons.edit_note_rounded
                              : Icons.store_mall_directory_rounded,
                        ),
                        label: Text(
                          hasOwnerRequest
                              ? 'Lanjutkan / Edit Pengajuan Owner'
                              : 'Daftar Menjadi Pemilik Kos',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF006A6A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    );
                  },
                ),
              Container(
                margin: const EdgeInsets.only(top: 12),
                child: FilledButton.icon(
                  onPressed: () async {
                    await _confirmUserLogout(context);
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
  const TenantProfileEditPage({
    super.key,
    required this.profile,
    this.pageTitle = 'Edit Profil',
    this.introText =
        'Ubah data profil penyewa tanpa mengubah gaya halaman utama. Password sekarang dipisah ke halaman khusus agar lebih aman.',
    this.passwordPageTitle = 'Ubah Password',
  });

  final AppUserData? profile;
  final String pageTitle;
  final String introText;
  final String passwordPageTitle;

  @override
  State<TenantProfileEditPage> createState() => _TenantProfileEditPageState();
}

class _TenantProfileEditPageState extends State<TenantProfileEditPage> {
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _photoController;
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = SupabaseAuth.instance.currentUser;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageTitle),
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
            child: Text(
              widget.introText,
              style: const TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
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
          _UploadImageCard(
            label: 'Foto profil',
            hint:
                'Upload foto profil dari galeri, tidak perlu tempel URL lagi.',
            imageUrl: _photoController.text.trim(),
            imageBytes: _selectedPhotoBytes,
            fileName: _selectedPhotoName,
            onPick: _pickProfilePhoto,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TenantPasswordChangePage(
                      pageTitle: widget.passwordPageTitle,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFB8D7D7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.lock_reset_rounded),
              label: const Text('Ubah Password'),
            ),
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
                : const Text('Simpan Perubahan'),
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

    var photoUrl = _photoController.text.trim();
    setState(() => _saving = true);
    try {
      if (_selectedPhotoBytes != null && _selectedPhotoName != null) {
        photoUrl = await SupabaseService.instance.uploadPublicImage(
          user: user,
          bytes: _selectedPhotoBytes!,
          fileName: _selectedPhotoName!,
          folder: 'profile-images',
        );
        _photoController.text = photoUrl;
      }
      await SupabaseService.instance.updateTenantProfile(
        user: user,
        name: name,
        phoneNumber: phone,
        photoUrl: photoUrl,
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
    } on SupabaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      _showLightDialog(
        context,
        title: 'Password belum bisa diubah',
        message: error.message ?? 'Silakan login ulang lalu coba lagi.',
      );
    } on SupabaseAppException catch (error) {
      if (!mounted) {
        return;
      }
      _showLightDialog(
        context,
        title: 'Profil gagal disimpan',
        message: _supabaseMessage(error),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickProfilePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (file == null) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedPhotoBytes = bytes;
      _selectedPhotoName = file.name;
    });
  }
}

class TenantPasswordChangePage extends StatefulWidget {
  const TenantPasswordChangePage({super.key, this.pageTitle = 'Ubah Password'});

  final String pageTitle;

  @override
  State<TenantPasswordChangePage> createState() =>
      _TenantPasswordChangePageState();
}

class _TenantPasswordChangePageState extends State<TenantPasswordChangePage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageTitle),
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
              'Masukkan password baru lalu konfirmasi ulang agar perubahan password lebih aman.',
              style: TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
            ),
          ),
          const SizedBox(height: 20),
          _InputField(
            controller: _newPasswordController,
            label: 'Password baru',
            hintText: 'Masukkan password baru',
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _confirmPasswordController,
            label: 'Konfirmasi password',
            hintText: 'Ulangi password baru',
            obscureText: true,
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _savePassword,
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
                : const Text('Simpan Password Baru'),
          ),
        ),
      ),
    );
  }

  Future<void> _savePassword() async {
    final user = SupabaseAuth.instance.currentUser;
    if (user == null) {
      _showLightDialog(
        context,
        title: 'Sesi tidak ditemukan',
        message: 'Silakan login ulang untuk mengubah password.',
      );
      return;
    }

    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showLightDialog(
        context,
        title: 'Password belum lengkap',
        message: 'Password baru dan konfirmasi password wajib diisi.',
      );
      return;
    }

    if (newPassword.length < 6) {
      _showLightDialog(
        context,
        title: 'Password terlalu pendek',
        message: 'Gunakan minimal 6 karakter untuk password baru.',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      _showLightDialog(
        context,
        title: 'Konfirmasi tidak cocok',
        message: 'Konfirmasi password harus sama dengan password baru.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await user.updatePassword(newPassword);
      if (!mounted) {
        return;
      }
      await _showLightDialog(
        context,
        title: 'Password diperbarui',
        message: 'Password baru berhasil disimpan.',
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    } on SupabaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      _showLightDialog(
        context,
        title: 'Password belum bisa diubah',
        message: error.message ?? 'Silakan login ulang lalu coba lagi.',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
