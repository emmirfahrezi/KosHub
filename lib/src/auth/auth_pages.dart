part of '../../main.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF006A6A), Color(0xFF00A8A8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      right: -20,
                      top: -10,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'KosHub',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Cari kos, chat pemilik, booking kamar, dan pantau transaksi dalam satu aplikasi.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isLogin ? 'Masuk ke akunmu' : 'Buat akun baru',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Akses pencarian kos, chat real-time, dan booking digital.'
                    : 'Daftar sebagai penyewa untuk mulai eksplor kos yang cocok.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _AuthModeChip(
                        label: 'Login',
                        selected: _isLogin,
                        onTap: () => setState(() => _isLogin = true),
                      ),
                    ),
                    Expanded(
                      child: _AuthModeChip(
                        label: 'Daftar',
                        selected: !_isLogin,
                        onTap: () => setState(() => _isLogin = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!_isLogin) ...[
                _InputField(
                  controller: _nameController,
                  label: 'Nama lengkap',
                  hintText: 'Masukkan nama lengkap',
                ),
                const SizedBox(height: 14),
              ],
              _InputField(
                controller: _emailController,
                label: 'Email',
                hintText: 'contoh@email.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _InputField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'Masukkan password',
                obscureText: true,
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 14),
                _InputField(
                  controller: _confirmPasswordController,
                  label: 'Konfirmasi password',
                  hintText: 'Ulangi password',
                  obscureText: true,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006A6A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isLogin ? 'Masuk' : 'Daftar'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? 'Belum punya akun? Daftar sekarang'
                        : 'Sudah punya akun? Masuk di sini',
                  ),
                ),
              ),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AdminLoginPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings_rounded),
                  label: const Text('Masuk sebagai admin aplikasi'),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catatan setup Firebase',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Akun baru akan dibuat ke Firebase Auth dan profil user disimpan ke Firestore koleksi users.',
                      style: TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (!_isLogin && name.isEmpty) {
      _showMessage('Nama lengkap wajib diisi.');
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email dan password wajib diisi.');
      return;
    }
    if (!_isLogin && password != confirmPassword) {
      _showMessage('Konfirmasi password tidak cocok.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
        await FirestoreService.instance.ensureUserProfile(
          credential.user!,
          fallbackName: credential.user!.displayName ?? email.split('@').first,
        );
      } else {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        await credential.user!.updateDisplayName(name);
        await FirestoreService.instance.ensureUserProfile(
          credential.user!,
          fallbackName: name,
        );
        await FirebaseAuth.instance.signOut();
        if (!mounted) {
          return;
        }
        setState(() {
          _isLogin = true;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
        await _showLightDialog(
          context,
          title: 'Registrasi berhasil',
          message:
              'Selamat, akun anda sudah terdaftar. Silakan login untuk masuk ke aplikasi.',
        );
      }
    } on FirebaseAuthException catch (error) {
      _showMessage(_authMessage(error));
    } catch (_) {
      _showMessage('Terjadi kendala saat memproses akun.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _authMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'email-already-in-use':
        return 'Email sudah dipakai akun lain.';
      case 'weak-password':
        return 'Password terlalu lemah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      default:
        return error.message ?? 'Autentikasi gagal.';
    }
  }

  Future<void> _showMessage(String message) {
    return _showLightDialog(
      context,
      title: 'Perlu diperhatikan',
      message: message,
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Login Admin')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF182022), Color(0xFF35589F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Dashboard Admin Koshub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Akses khusus untuk super admin, moderator, finance admin, dan customer service.',
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Masuk ke panel admin',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Role user biasa akan otomatis ditolak dari area admin.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              _InputField(
                controller: _emailController,
                label: 'Email admin',
                hintText: 'admin@koshub.id',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _InputField(
                controller: _passwordController,
                label: 'Password',
                hintText: 'Masukkan password admin',
                obscureText: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock_open_rounded),
                  label: Text(
                    _isLoading ? 'Memeriksa akses...' : 'Masuk Admin',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF182022),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security baseline',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Panel admin dipisahkan dari login user biasa, cek role setelah autentikasi, dan bisa diperluas ke OTP, 2FA, session timeout, serta audit login.',
                      style: TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email dan password admin wajib diisi.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirestoreService.instance.signInAdmin(
        email: email,
        password: password,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (error) {
      _showMessage(error.message ?? 'Login admin gagal.');
    } on FirebaseException catch (error) {
      _showMessage(_firebaseMessage(error));
    } catch (_) {
      _showMessage('Terjadi kendala saat memproses login admin.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showMessage(String message) {
    return _showLightDialog(context, title: 'Login admin', message: message);
  }
}
