import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

const List<String> _adminSeedEmails = ['emmir.fahrezi1@gmail.com'];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<FirebaseApp> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _LoadingScreen(
              label: 'Firebase gagal dimuat. Coba periksa koneksi atau config.',
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _LoadingScreen(label: 'Menyiapkan aplikasi...'),
          );
        }

        return const KosHubApp();
      },
    );
  }
}

class KosHubApp extends StatelessWidget {
  const KosHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KosHub',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FB),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF006A6A),
          onPrimary: Colors.white,
          secondary: Color(0xFF9F4035),
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF182022),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(label: 'Menyiapkan sesi...');
        }

        final user = snapshot.data;
        if (user == null) {
          return const AuthPage();
        }

        return const MainShell();
      },
    );
  }
}

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
    return _showLightDialog(
      context,
      title: 'Login admin',
      message: message,
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<AppUserData?>(
      stream: FirestoreService.instance.userProfileStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(label: 'Menyiapkan tampilan akun...');
        }

        final profile = snapshot.data;
        if (profile?.isAdmin == true) {
          return AdminShell(profile: profile!);
        }

        final isOwner = profile?.role == 'pemilik';
        final pages = isOwner
            ? [
                OwnerDashboardPage(
                  onOpenBookings: () => setState(() => _currentIndex = 1),
                  onOpenResidents: () => setState(() => _currentIndex = 2),
                ),
                const OwnerBookingPage(),
                const OwnerResidentsPage(),
                const OwnerRoomsPage(),
                const ProfilePage(),
              ]
            : [
                HomePage(
                  onOpenChat: () => setState(() => _currentIndex = 1),
                  onOpenBookings: () => setState(() => _currentIndex = 2),
                ),
                const ChatListPage(),
                const BookingHistoryPage(),
                const ProfilePage(),
              ];
        final destinations = isOwner
            ? const [
                _ShellDestination(
                  label: 'Dashboard',
                  icon: Icons.dashboard_rounded,
                ),
                _ShellDestination(
                  label: 'Booking',
                  icon: Icons.fact_check_rounded,
                ),
                _ShellDestination(
                  label: 'Penghuni',
                  icon: Icons.groups_rounded,
                ),
                _ShellDestination(
                  label: 'Kamar',
                  icon: Icons.meeting_room_rounded,
                ),
                _ShellDestination(label: 'Profil', icon: Icons.person_rounded),
              ]
            : const [
                _ShellDestination(label: 'Home', icon: Icons.home_rounded),
                _ShellDestination(
                  label: 'Chat',
                  icon: Icons.chat_bubble_rounded,
                ),
                _ShellDestination(
                  label: 'Booking',
                  icon: Icons.bookmark_rounded,
                ),
                _ShellDestination(label: 'Profil', icon: Icons.person_rounded),
              ];

        final safeIndex = _currentIndex.clamp(0, pages.length - 1);
        if (safeIndex != _currentIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _currentIndex = safeIndex);
            }
          });
        }

        return Scaffold(
          body: pages[safeIndex],
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 18,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(destinations.length, (index) {
                    final item = destinations[index];
                    return Expanded(
                      child: _NavItem(
                        label: item.label,
                        icon: item.icon,
                        selected: safeIndex == index,
                        onTap: () => setState(() => _currentIndex = index),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShellDestination {
  const _ShellDestination({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.profile});

  final AppUserData profile;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminDashboardPage(
        profile: widget.profile,
        onOpenUsers: () => setState(() => _currentIndex = 1),
        onOpenOwners: () => setState(() => _currentIndex = 2),
        onOpenListings: () => setState(() => _currentIndex = 3),
        onOpenPayments: () => setState(() => _currentIndex = 4),
        onOpenControl: () => setState(() => _currentIndex = 5),
      ),
      const AdminUsersPage(),
      const AdminOwnersPage(),
      const AdminListingsPage(),
      const AdminPaymentsPage(),
      const AdminControlCenterPage(),
    ];
    const destinations = [
      _ShellDestination(
        label: 'Dashboard',
        icon: Icons.space_dashboard_rounded,
      ),
      _ShellDestination(label: 'Pengguna', icon: Icons.groups_rounded),
      _ShellDestination(label: 'Pemilik', icon: Icons.verified_user_rounded),
      _ShellDestination(label: 'Listing', icon: Icons.apartment_rounded),
      _ShellDestination(
        label: 'Bayar',
        icon: Icons.account_balance_wallet_rounded,
      ),
      _ShellDestination(
        label: 'Sistem',
        icon: Icons.admin_panel_settings_rounded,
      ),
    ];

    final safeIndex = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: pages[safeIndex],
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: List.generate(destinations.length, (index) {
                final item = destinations[index];
                return Expanded(
                  child: _NavItem(
                    label: item.label,
                    icon: item.icon,
                    selected: safeIndex == index,
                    onTap: () => setState(() => _currentIndex = index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

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

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.onOpenChat,
    required this.onOpenBookings,
  });

  final VoidCallback onOpenChat;
  final VoidCallback onOpenBookings;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        titleSpacing: 20,
        title: Row(
          children: [
            const Icon(Icons.location_on_rounded, color: Color(0xFF006A6A)),
            const SizedBox(width: 6),
            Text(
              'KosHub',
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xFF006A6A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: widget.onOpenChat,
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<KosData>>(
        stream: FirestoreService.instance.kosStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen(label: 'Memuat data kos...');
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Gagal memuat daftar kos',
                subtitle: _streamErrorMessage(snapshot.error),
              ),
            );
          }

          final items = snapshot.data ?? const <KosData>[];
          final filtered = items.where((kos) {
            if (_searchQuery.isEmpty) {
              return true;
            }
            final query = _searchQuery.toLowerCase();
            return kos.name.toLowerCase().contains(query) ||
                kos.area.toLowerCase().contains(query) ||
                kos.address.toLowerCase().contains(query);
          }).toList();

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeHero(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    onSubmitted: (_) {},
                  ),
                  const SizedBox(height: 24),
                  const _CategorySection(),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Kos Tersedia',
                    actionLabel: 'Seed Data Demo',
                    onTap: _seedDemoData,
                  ),
                  const SizedBox(height: 14),
                  if (filtered.isEmpty)
                    _EmptyStateCard(
                      title: items.isEmpty
                          ? 'Belum ada data kos di Firestore'
                          : 'Tidak ada hasil yang cocok',
                      subtitle: items.isEmpty
                          ? 'Tekan "Seed Data Demo" untuk membuat contoh data kos, pemilik, dan chat awal.'
                          : 'Coba ubah kata kunci pencarianmu.',
                      buttonLabel: items.isEmpty ? 'Buat Data Demo' : null,
                      onPressed: items.isEmpty ? _seedDemoData : null,
                    )
                  else
                    ListView.separated(
                      itemCount: filtered.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final kos = filtered[index];
                        return _KosCard(
                          kos: kos,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => KosDetailPage(kos: kos),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 28),
                  Text(
                    'Promo Menarik',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _PromoBanner(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _seedDemoData() async {
    try {
      await FirestoreService.instance.seedSampleData();
      if (mounted) {
        _showLightDialog(
          context,
          title: 'Data demo siap',
          message: 'Contoh data kos berhasil dimuat ke aplikasi.',
        );
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        _showLightDialog(
          context,
          title: 'Data demo gagal dimuat',
          message: _firebaseMessage(error),
        );
      }
    } catch (_) {
      if (mounted) {
        _showLightDialog(
          context,
          title: 'Data demo gagal',
          message: 'Coba lagi dalam beberapa saat.',
        );
      }
    }
  }
}

class KosDetailPage extends StatelessWidget {
  const KosDetailPage({super.key, required this.kos});

  final KosData kos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnKos = currentUser?.uid == kos.ownerId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: PageView(
                children: kos.gallery
                    .map((image) => Image.network(image, fit: BoxFit.cover))
                    .toList(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TagChip(
                        label: kos.category,
                        color: kos.category == 'Eksklusif'
                            ? const Color(0xFF006A6A)
                            : const Color(0xFF9F4035),
                      ),
                      _StatusPill(
                        label: '${kos.availableRooms} kamar tersedia',
                        color: const Color(0xFFB78103),
                        background: const Color(0xFFFFF5DD),
                      ),
                      _StatusPill(
                        label: kos.approvalMode,
                        color: const Color(0xFF35589F),
                        background: const Color(0xFFEAF1FF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    kos.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF5D6B6B),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          kos.address,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF4B400),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${kos.rating.toStringAsFixed(1)} (${kos.reviewCount} ulasan)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '${_currency(kos.price)} / bulan',
                        style: const TextStyle(
                          color: Color(0xFF006A6A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _InfoBlock(
                    title: 'Deskripsi',
                    child: Text(
                      kos.description,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _InfoBlock(
                    title: 'Fasilitas',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kos.facilities
                          .map((facility) => _FacilityChip(label: facility))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _InfoBlock(
                    title: 'Pemilik Kos',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E7E7)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundImage: kos.ownerPhoto.isNotEmpty
                                ? NetworkImage(kos.ownerPhoto)
                                : null,
                            child: kos.ownerPhoto.isEmpty
                                ? const Icon(Icons.person_rounded)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kos.ownerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  kos.ownerStatus,
                                  style: const TextStyle(
                                    color: Color(0xFF5D6B6B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _InfoBlock(
                    title: 'Lokasi',
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDDF5EF), Color(0xFFF8F8FB)],
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map_rounded,
                              size: 42,
                              color: Color(0xFF006A6A),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Mini map siap diintegrasikan',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: StreamBuilder<AppUserData?>(
        stream: currentUser == null
            ? null
            : FirestoreService.instance.userProfileStream(currentUser.uid),
        builder: (context, snapshot) {
          final isOwner = snapshot.data?.role == 'pemilik';

          return SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x15000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final chatId = await FirestoreService.instance
                              .createOrGetChat(kos);
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ChatDetailPage(kos: kos, chatId: chatId),
                            ),
                          );
                        } on FirebaseException catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          _showLightDialog(
                            context,
                            title: 'Chat belum bisa dibuka',
                            message: _firebaseMessage(error),
                          );
                        } catch (_) {
                          if (!context.mounted) {
                            return;
                          }
                          _showLightDialog(
                            context,
                            title: 'Chat gagal dibuat',
                            message: 'Coba lagi dalam beberapa saat.',
                          );
                        }
                      },
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text('Chat Pemilik'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: isOwnKos
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      OwnerRegistrationPage(existingKos: kos),
                                ),
                              );
                            }
                          : isOwner
                          ? null
                          : () {
                              if (kos.availableRooms <= 0) {
                                _showLightDialog(
                                  context,
                                  title: 'Kamar penuh',
                                  message:
                                      'Saat ini kamar di kos ini sedang penuh.',
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => BookingFormPage(kos: kos),
                                ),
                              );
                            },
                      child: Text(
                        isOwnKos
                            ? 'Edit Listing'
                            : isOwner
                            ? 'Akun Pemilik'
                            : kos.availableRooms <= 0
                            ? 'Kamar Penuh'
                            : 'Booking Sekarang',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Pemilik Kos'),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ChatPreviewData>>(
        stream: FirestoreService.instance.userChatsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen(label: 'Memuat percakapan...');
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Chat gagal dimuat',
                subtitle: _streamErrorMessage(snapshot.error),
              ),
            );
          }

          final chats = snapshot.data ?? const <ChatPreviewData>[];
          if (chats.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Belum ada chat',
                subtitle:
                    'Buka detail kos lalu tekan tombol chat agar percakapan pertama dibuat di Firestore.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            itemCount: chats.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ChatDetailPage(kos: chat.kos, chatId: chat.id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Ink(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE7ECEC)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(chat.kos.ownerPhoto),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chat.kos.ownerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chat.kos.name,
                              style: const TextStyle(
                                color: Color(0xFF006A6A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              chat.lastMessage.isEmpty
                                  ? 'Belum ada pesan'
                                  : chat.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF5D6B6B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        chat.timeLabel,
                        style: const TextStyle(
                          color: Color(0xFF5D6B6B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({super.key, required this.kos, required this.chatId});

  final KosData kos;
  final String chatId;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.kos.ownerPhoto),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.kos.ownerName,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  widget.kos.ownerStatus,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5D6B6B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    widget.kos.gallery.first,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.kos.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_currency(widget.kos.price)} / bulan',
                        style: const TextStyle(
                          color: Color(0xFF006A6A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatMessageData>>(
              stream: FirestoreService.instance.messagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingScreen(label: 'Memuat pesan...');
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _EmptyStateCard(
                        title: 'Pesan gagal dimuat',
                        subtitle: _streamErrorMessage(snapshot.error),
                      ),
                    ),
                  );
                }

                final messages = snapshot.data ?? const <ChatMessageData>[];
                if (messages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: _EmptyStateCard(
                        title: 'Mulai percakapan pertama',
                        subtitle:
                            'Tanyakan kamar, jadwal survei, atau aturan kos langsung ke pemilik.',
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == currentUserId;
                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isMine
                              ? const Color(0xFF006A6A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(
                                color: isMine
                                    ? Colors.white
                                    : const Color(0xFF182022),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              message.timeLabel,
                              style: TextStyle(
                                color: isMine
                                    ? Colors.white70
                                    : const Color(0xFF5D6B6B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _sending ? null : _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF006A6A),
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: _sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() => _sending = true);
    try {
      await FirestoreService.instance.sendMessage(widget.chatId, text);
      _controller.clear();
    } on FirebaseException catch (error) {
      if (mounted) {
        _showLightDialog(
          context,
          title: 'Pesan belum terkirim',
          message: _firebaseMessage(error),
        );
      }
    } catch (_) {
      if (mounted) {
        _showLightDialog(
          context,
          title: 'Pesan gagal dikirim',
          message: 'Coba lagi dalam beberapa saat.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }
}

class BookingFormPage extends StatefulWidget {
  const BookingFormPage({super.key, required this.kos});

  final KosData kos;

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  late final TextEditingController _startDateController;
  final _phoneController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _roomController = TextEditingController(text: 'Kamar 01');
  final _noteController = TextEditingController();
  final _proofController = TextEditingController();
  String _selectedDuration = '6 bulan';
  String _selectedPayment = 'Transfer Bank';
  late DateTime _selectedStartDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = DateTime.now().add(const Duration(days: 3));
    _startDateController = TextEditingController(
      text: _formatLongDate(_selectedStartDate),
    );
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _phoneController.dispose();
    _emergencyController.dispose();
    _roomController.dispose();
    _noteController.dispose();
    _proofController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Kamar'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    widget.kos.gallery.isNotEmpty
                        ? widget.kos.gallery.first
                        : '',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.kos.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Kamar Demo',
                        style: TextStyle(color: Color(0xFF5D6B6B)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_currency(widget.kos.price)} / bulan',
                        style: const TextStyle(
                          color: Color(0xFF006A6A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _InputField(
            controller: _startDateController,
            label: 'Tanggal mulai sewa',
            hintText: 'Pilih tanggal masuk',
            readOnly: true,
            onTap: _pickStartDate,
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
            controller: _emergencyController,
            label: 'Nomor emergency',
            hintText: 'Contoh: 081298765432',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _roomController,
            label: 'Kamar dipilih',
            hintText: 'Contoh: Kamar 01',
          ),
          const SizedBox(height: 16),
          _SelectCard(
            label: 'Durasi sewa',
            value: _selectedDuration,
            items: const ['1 bulan', '3 bulan', '6 bulan', '12 bulan'],
            onChanged: (value) => setState(() => _selectedDuration = value),
          ),
          const SizedBox(height: 16),
          _SelectCard(
            label: 'Metode pembayaran',
            value: _selectedPayment,
            items: const ['Transfer Bank', 'E-Wallet', 'Virtual Account'],
            onChanged: (value) => setState(() => _selectedPayment = value),
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _noteController,
            label: 'Catatan untuk pemilik',
            hintText: 'Contoh: Saya ingin survei dulu sebelum masuk',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _proofController,
            label: 'URL bukti pembayaran DP',
            hintText: 'Tempel link bukti transfer DP',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5DD),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Info Booking',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.kos.approvalMode == 'Auto Approval'
                      ? 'Kos ini memakai Auto Approval. Booking otomatis dikonfirmasi kalau bukti DP sudah diisi.'
                      : 'Kos ini memakai Manual Approval. Pemilik akan review booking dan bukti DP lebih dulu.',
                  style: const TextStyle(
                    color: Color(0xFF735B00),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5F5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Pembayaran',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                _SummaryRow(
                  label: 'Harga sewa',
                  value:
                      '${_currency(widget.kos.price)} x ${_selectedDuration.split(' ').first}',
                ),
                const SizedBox(height: 8),
                const _SummaryRow(label: 'Biaya layanan', value: 'Rp 0'),
                const Divider(height: 24),
                _SummaryRow(
                  label: 'Total',
                  value: _currency(
                    _totalPrice(widget.kos.price, _selectedDuration),
                  ),
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton(
          onPressed: _saving ? null : _createBooking,
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
              : const Text('Konfirmasi Booking'),
        ),
      ),
    );
  }

  Future<void> _createBooking() async {
    final phone = _phoneController.text.trim();
    final emergency = _emergencyController.text.trim();
    final roomLabel = _roomController.text.trim();
    final proof = _proofController.text.trim();

    if (widget.kos.availableRooms <= 0) {
      _showLightDialog(
        context,
        title: 'Kamar tidak tersedia',
        message: 'Kos ini sedang penuh dan belum bisa dibooking.',
      );
      return;
    }
    if (phone.isEmpty || emergency.isEmpty || roomLabel.isEmpty || proof.isEmpty) {
      _showLightDialog(
        context,
        title: 'Data belum lengkap',
        message:
            'Tanggal masuk, nomor HP, kontak darurat, kamar, dan bukti DP wajib diisi.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await FirestoreService.instance.createBooking(
        kos: widget.kos,
        durationLabel: _selectedDuration,
        paymentMethod: _selectedPayment,
        startDate: _selectedStartDate,
        startDateLabel: _startDateController.text.trim(),
        phoneNumber: phone,
        emergencyContact: emergency,
        roomLabel: roomLabel,
        note: _noteController.text.trim(),
        paymentProofUrl: proof,
      );
      if (!mounted) {
        return;
      }
      await _showLightDialog(
        context,
        title: 'Booking berhasil',
        message:
            'Permintaan booking sudah dikirim. Silakan cek statusnya di menu Booking.',
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      _showLightDialog(
        context,
        title: 'Booking belum berhasil',
        message: _firebaseMessage(error),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showLightDialog(
        context,
        title: 'Booking gagal dibuat',
        message: 'Coba lagi dalam beberapa saat.',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (selectedDate == null) {
      return;
    }

    setState(() {
      _selectedStartDate = selectedDate;
      _startDateController.text = _formatLongDate(selectedDate);
    });
  }
}

class BookingHistoryPage extends StatelessWidget {
  const BookingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Booking'),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<List<BookingData>>(
        stream: FirestoreService.instance.userBookingsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen(label: 'Memuat booking...');
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Booking gagal dimuat',
                subtitle: _streamErrorMessage(snapshot.error),
              ),
            );
          }

          final bookings = snapshot.data ?? const <BookingData>[];
          if (bookings.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Belum ada booking',
                subtitle:
                    'Saat kamu melakukan booking dari detail kos, data akan masuk ke Firestore dan muncul di sini.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            itemCount: bookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => BookingDetailPage(booking: booking),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.kos.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _StatusBadge(label: booking.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(label: 'Kamar', value: booking.roomLabel),
                      const SizedBox(height: 6),
                      _SummaryRow(label: 'Mulai sewa', value: booking.startDate),
                      const SizedBox(height: 6),
                      _SummaryRow(label: 'Durasi', value: booking.durationLabel),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Status pembayaran',
                        value: booking.paymentStatus,
                      ),
                      const Divider(height: 24),
                      _SummaryRow(
                        label: 'Total',
                        value: booking.total,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BookingDetailPage extends StatelessWidget {
  const BookingDetailPage({super.key, required this.booking});

  final BookingData booking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Booking'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    booking.kos.gallery.first,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.kos.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        booking.kos.address,
                        style: const TextStyle(color: Color(0xFF5D6B6B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Informasi booking',
            subtitle: 'Ringkasan kamar, durasi, dan pembayaran.',
            child: Column(
              children: [
                _SummaryRow(label: 'Kamar', value: booking.roomLabel),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Tanggal masuk', value: booking.startDate),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Durasi sewa', value: booking.durationLabel),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Tanggal selesai', value: booking.endDate),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Status booking', value: booking.status),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Status pembayaran',
                  value: booking.paymentStatus,
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Metode pembayaran',
                  value: booking.paymentMethod,
                ),
                const Divider(height: 24),
                _SummaryRow(label: 'Total harga', value: booking.total, bold: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Catatan & bukti',
            subtitle: 'Informasi tambahan dari penyewa dan pemilik.',
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Catatan penyewa',
                  value: booking.note.isEmpty ? '-' : booking.note,
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Bukti DP',
                  value: booking.paymentProofUrl.isEmpty
                      ? 'Belum ada'
                      : booking.paymentProofUrl,
                ),
                if (booking.cancelReason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _SummaryRow(
                    label: 'Alasan pembatalan',
                    value: booking.cancelReason,
                  ),
                ],
                if (booking.ownerNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: booking.ownerNotes
                          .map(
                            (note) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '• $note',
                                style: const TextStyle(
                                  color: Color(0xFF5D6B6B),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () async {
                try {
                  final chatId = await FirestoreService.instance.createOrGetChat(
                    booking.kos,
                  );
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ChatDetailPage(kos: booking.kos, chatId: chatId),
                    ),
                  );
                } on FirebaseException catch (error) {
                  if (!context.mounted) {
                    return;
                  }
                  _showLightDialog(
                    context,
                    title: 'Chat belum bisa dibuka',
                    message: _firebaseMessage(error),
                  );
                }
              },
              child: const Text('Chat Pemilik'),
            ),
            OutlinedButton(
              onPressed: booking.paymentProofUrl.isEmpty
                  ? null
                  : () {
                      _showLightDialog(
                        context,
                        title: 'Bukti Pembayaran',
                        message: booking.paymentProofUrl,
                      );
                    },
              child: const Text('Lihat Bukti'),
            ),
            FilledButton(
              onPressed: booking.status == 'Menunggu Konfirmasi'
                  ? () => _confirmCancelBooking(context, booking)
                  : null,
              child: const Text('Batalkan Booking'),
            ),
          ],
        ),
      ),
    );
  }
}

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
                              : '${kos.area} • Mode ${kos.approvalMode}',
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
                          '${(occupancyRatio * 100).round()}% terisi • ${activeResidents.length} dari $totalRooms kamar',
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
                                    '${booking.roomLabel} • Masuk ${booking.startDate}',
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
                                    '${booking.roomLabel} • Jatuh tempo ${_formatLongDate(dueDate)}',
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
                                    '${booking.kos.name} • ${_formatLongDate(booking.sortKey)}',
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

class OwnerBookingPage extends StatefulWidget {
  const OwnerBookingPage({
    super.key,
    this.initialTab = 0,
    this.initialQuery = '',
  });

  final int initialTab;
  final String initialQuery;

  @override
  State<OwnerBookingPage> createState() => _OwnerBookingPageState();
}

class _OwnerBookingPageState extends State<OwnerBookingPage> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTab.clamp(0, 3),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Daftar Booking'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Menunggu Konfirmasi'),
              Tab(text: 'Sudah Dikonfirmasi'),
              Tab(text: 'Sudah Check-in'),
              Tab(text: 'Dibatalkan'),
            ],
          ),
        ),
        body: StreamBuilder<List<BookingData>>(
          stream: FirestoreService.instance.ownerBookingsStream(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen(label: 'Memuat booking owner...');
            }

            final bookings = (snapshot.data ?? const <BookingData>[])
                .where(_matchesBookingQuery)
                .toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildSearchCard(
                    hintText: 'Cari nama penghuni, kamar, atau status bayar...',
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildBookingTab(
                        bookings
                            .where((b) => b.status == 'Menunggu Konfirmasi')
                            .toList(),
                      ),
                      _buildBookingTab(
                        bookings
                            .where((b) => b.status == 'Sudah Dikonfirmasi')
                            .toList(),
                      ),
                      _buildBookingTab(
                        bookings
                            .where((b) => b.status == 'Sudah Check-in')
                            .toList(),
                      ),
                      _buildBookingTab(
                        bookings
                            .where((b) => b.status == 'Dibatalkan')
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingTab(List<BookingData> bookings) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
      children: [
        if (bookings.isEmpty)
          const _EmptyStateCard(
            title: 'Belum ada data di status ini',
            subtitle:
                'Saat booking baru masuk atau status diubah, datanya akan tampil di sini.',
          )
        else
          ...List.generate(bookings.length, (index) {
            final booking = bookings[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == bookings.length - 1 ? 0 : 14,
              ),
              child: InkWell(
                onTap: () => _openBookingDetail(booking),
                borderRadius: BorderRadius.circular(24),
                child: Container(
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
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFEAF5F5),
                            backgroundImage: booking.userPhoto.isNotEmpty
                                ? NetworkImage(booking.userPhoto)
                                : null,
                            child: booking.userPhoto.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    color: Color(0xFF006A6A),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.userName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${booking.kos.name} • ${booking.roomLabel}',
                                  style: const TextStyle(
                                    color: Color(0xFF5D6B6B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _StatusBadge(label: booking.status),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SummaryRow(label: 'Nomor HP', value: booking.userPhone),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Tanggal masuk',
                        value: booking.startDate,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Durasi',
                        value: booking.durationLabel,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Pembayaran',
                        value: booking.paymentMethod,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Status bayar',
                        value: booking.paymentStatus,
                      ),
                      if (booking.note.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Catatan penyewa: ${booking.note}',
                          style: const TextStyle(
                            color: Color(0xFF5D6B6B),
                            height: 1.45,
                          ),
                        ),
                      ],
                      if (booking.paymentProofUrl.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Bukti DP: ${booking.paymentProofUrl}',
                          style: const TextStyle(
                            color: Color(0xFF006A6A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (booking.status == 'Sudah Dikonfirmasi') ...[
                        const SizedBox(height: 12),
                        Text(
                          _checkInCountdownLabel(booking.startDateValue),
                          style: const TextStyle(
                            color: Color(0xFFB78103),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (booking.status == 'Dibatalkan' &&
                          booking.cancelReason.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Alasan pembatalan: ${booking.cancelReason}',
                            style: const TextStyle(
                              color: Color(0xFF9F4035),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Divider(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _buildActions(context, booking),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSearchCard({required String hintText}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) =>
            setState(() => _query = value.trim().toLowerCase()),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: hintText,
          border: InputBorder.none,
        ),
      ),
    );
  }

  bool _matchesBookingQuery(BookingData booking) {
    if (_query.isEmpty) {
      return true;
    }
    return booking.userName.toLowerCase().contains(_query) ||
        booking.roomLabel.toLowerCase().contains(_query) ||
        booking.userPhone.toLowerCase().contains(_query) ||
        booking.paymentStatus.toLowerCase().contains(_query);
  }

  void _openBookingDetail(BookingData booking) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OwnerBookingDetailPage(booking: booking),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, BookingData booking) {
    final actions = <Widget>[
      OutlinedButton.icon(
        onPressed: () => _openChat(booking),
        icon: const Icon(Icons.chat_rounded),
        label: const Text('Chat Penyewa'),
      ),
    ];

    if (booking.status == 'Menunggu Konfirmasi') {
      actions.addAll([
        FilledButton(
          onPressed: () => _updateBookingStatus(booking, 'Sudah Dikonfirmasi'),
          child: const Text('Terima'),
        ),
        FilledButton.tonal(
          onPressed: () => _rejectBooking(booking),
          child: const Text('Tolak'),
        ),
      ]);
    } else if (booking.status == 'Sudah Dikonfirmasi') {
      actions.addAll([
        FilledButton(
          onPressed: () => _updateBookingStatus(booking, 'Sudah Check-in'),
          child: const Text('Tandai Check-in'),
        ),
        FilledButton.tonal(
          onPressed: () => _rejectBooking(booking),
          child: const Text('Batalkan'),
        ),
      ]);
    } else if (booking.status == 'Sudah Check-in') {
      actions.add(
        FilledButton(
          onPressed: () => _updateBookingStatus(booking, 'Selesai'),
          child: const Text('Pindah ke Riwayat'),
        ),
      );
    }

    return actions;
  }

  Future<void> _openChat(BookingData booking) async {
    try {
      final chatId = await FirestoreService.instance.createOrGetOwnerChat(
        booking,
      );
      if (!mounted) {
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ChatDetailPage(kos: booking.kos, chatId: chatId),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    }
  }

  Future<void> _updateBookingStatus(BookingData booking, String status) async {
    try {
      await FirestoreService.instance.updateBookingStatus(
        booking: booking,
        status: status,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status booking diubah menjadi $status.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    }
  }

  Future<void> _rejectBooking(BookingData booking) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  'Pilih alasan pembatalan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                ..._cancelReasons.map((reason) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(reason),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.pop(context, reason),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (reason == null) {
      return;
    }

    try {
      await FirestoreService.instance.updateBookingStatus(
        booking: booking,
        status: 'Dibatalkan',
        cancelReason: reason,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Booking dibatalkan: $reason')));
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    }
  }
}

class OwnerResidentsPage extends StatefulWidget {
  const OwnerResidentsPage({
    super.key,
    this.initialTab = 0,
    this.initialQuery = '',
  });

  final int initialTab;
  final String initialQuery;

  @override
  State<OwnerResidentsPage> createState() => _OwnerResidentsPageState();
}

class _OwnerResidentsPageState extends State<OwnerResidentsPage> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTab.clamp(0, 3),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Penghuni'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Akan Keluar'),
              Tab(text: 'Riwayat'),
              Tab(text: 'Blacklist'),
            ],
          ),
        ),
        body: StreamBuilder<List<BookingData>>(
          stream: FirestoreService.instance.ownerBookingsStream(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen(label: 'Memuat data penghuni...');
            }

            final bookings = snapshot.data ?? const <BookingData>[];
            final active = bookings
                .where((booking) => booking.status == 'Sudah Check-in')
                .toList();
            final leavingSoon = active
                .where(
                  (booking) =>
                      booking.endDateValue.difference(DateTime.now()).inDays <=
                      30,
                )
                .toList();
            final history = bookings
                .where(
                  (booking) =>
                      booking.status == 'Selesai' ||
                      booking.status == 'Dibatalkan',
                )
                .toList();
            final blacklist = bookings
                .where(
                  (booking) => booking.cancelReason == 'Tidak sesuai aturan',
                )
                .toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _query = value.trim().toLowerCase()),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText:
                            'Cari nama penghuni, kamar, atau status bayar...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildResidents(
                        _filterResidents(active),
                        showActions: true,
                      ),
                      _buildResidents(_filterResidents(leavingSoon)),
                      _buildResidents(_filterResidents(history)),
                      _buildResidents(_filterResidents(blacklist)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResidents(
    List<BookingData> bookings, {
    bool showActions = false,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
      children: [
        if (bookings.isEmpty)
          const _EmptyStateCard(
            title: 'Belum ada data penghuni',
            subtitle:
                'Saat ada penghuni aktif, akan keluar, atau riwayat sewa, datanya muncul di sini.',
          )
        else
          ...List.generate(bookings.length, (index) {
            final booking = bookings[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == bookings.length - 1 ? 0 : 14,
              ),
              child: InkWell(
                onTap: () => _openResidentDetail(booking),
                borderRadius: BorderRadius.circular(24),
                child: Container(
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
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFEAF5F5),
                            backgroundImage: booking.userPhoto.isNotEmpty
                                ? NetworkImage(booking.userPhoto)
                                : null,
                            child: booking.userPhoto.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    color: Color(0xFF006A6A),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.userName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${booking.roomLabel} • ${booking.kos.name}',
                                  style: const TextStyle(
                                    color: Color(0xFF5D6B6B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _StatusBadge(label: booking.paymentStatus),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SummaryRow(
                        label: 'Tanggal masuk',
                        value: booking.startDate,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Tanggal keluar',
                        value: booking.endDate,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'No emergency',
                        value: booking.emergencyContact,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Status booking',
                        value: booking.status,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Pembayaran',
                        value: booking.paymentMethod,
                      ),
                      if (booking.note.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Catatan pemilik/penghuni: ${booking.note}',
                          style: const TextStyle(
                            color: Color(0xFF5D6B6B),
                            height: 1.45,
                          ),
                        ),
                      ],
                      if (showActions) ...[
                        const Divider(height: 24),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (value) =>
                                  _updatePaymentStatus(booking, value),
                              itemBuilder: (context) {
                                return _paymentStatuses
                                    .map(
                                      (status) => PopupMenuItem<String>(
                                        value: status,
                                        child: Text(status),
                                      ),
                                    )
                                    .toList();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF5F5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Ubah Status Bayar',
                                  style: const TextStyle(
                                    color: Color(0xFF006A6A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            FilledButton(
                              onPressed: () => _finishResident(booking),
                              child: const Text('Pindah ke Riwayat'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _updatePaymentStatus(
    BookingData booking,
    String paymentStatus,
  ) async {
    try {
      await FirestoreService.instance.updateBookingPaymentStatus(
        bookingId: booking.id,
        paymentStatus: paymentStatus,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status pembayaran diubah ke $paymentStatus.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    }
  }

  Future<void> _finishResident(BookingData booking) async {
    try {
      await FirestoreService.instance.updateBookingStatus(
        booking: booking,
        status: 'Selesai',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penghuni dipindahkan ke riwayat.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    }
  }

  List<BookingData> _filterResidents(List<BookingData> bookings) {
    if (_query.isEmpty) {
      return bookings;
    }
    return bookings.where((booking) {
      return booking.userName.toLowerCase().contains(_query) ||
          booking.roomLabel.toLowerCase().contains(_query) ||
          booking.paymentStatus.toLowerCase().contains(_query) ||
          booking.status.toLowerCase().contains(_query);
    }).toList();
  }

  void _openResidentDetail(BookingData booking) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ResidentDetailPage(booking: booking),
      ),
    );
  }
}

class OwnerRoomsPage extends StatelessWidget {
  const OwnerRoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<KosData?>(
      stream: FirestoreService.instance.ownerKosStream(user.uid),
      builder: (context, kosSnapshot) {
        if (kosSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(label: 'Memuat data kamar...');
        }

        final kos = kosSnapshot.data;
        if (kos == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: const Text('Kamar'),
            ),
            body: const Padding(
              padding: EdgeInsets.all(20),
              child: _EmptyStateCard(
                title: 'Listing kos belum tersedia',
                subtitle:
                    'Lengkapi data listing dulu dari profil supaya kamar dan pengaturan owner bisa dikelola.',
              ),
            ),
          );
        }

        return StreamBuilder<List<BookingData>>(
          stream: FirestoreService.instance.ownerBookingsStream(user.uid),
          builder: (context, bookingsSnapshot) {
            if (bookingsSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen(label: 'Menghitung kondisi kamar...');
            }

            final bookings = bookingsSnapshot.data ?? const <BookingData>[];
            final activeResidents = bookings
                .where((booking) => booking.status == 'Sudah Check-in')
                .toList();
            final totalRooms = math.max(kos.totalRooms, activeResidents.length);
            final generatedRooms = List.generate(totalRooms, (index) {
              final roomLabel =
                  'Kamar ${(index + 1).toString().padLeft(2, '0')}';
              final resident = activeResidents.firstWhere(
                (booking) => booking.roomLabel == roomLabel,
                orElse: () => BookingData.empty(roomLabel, kos),
              );
              return resident;
            });

            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.white,
                title: const Text('Kamar'),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kos.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${kos.area} • ${kos.address}',
                          style: const TextStyle(
                            color: Color(0xFF5D6B6B),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SmallPill(label: 'Mode ${kos.approvalMode}'),
                            _SmallPill(label: '${kos.availableRooms} tersedia'),
                            _SmallPill(
                              label: '${activeResidents.length} terisi',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    OwnerRegistrationPage(existingKos: kos),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit Listing Kos'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Status Kamar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ...generatedRooms.map((resident) {
                    final occupied = resident.id.isNotEmpty;
                    final roomHistory =
                        bookings
                            .where(
                              (booking) =>
                                  booking.roomLabel == resident.roomLabel,
                            )
                            .toList()
                          ..sort((a, b) => b.sortKey.compareTo(a.sortKey));
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => RoomDetailPage(
                              kos: kos,
                              roomLabel: resident.roomLabel,
                              currentResident: occupied ? resident : null,
                              history: roomHistory,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: occupied
                                    ? const Color(0xFFEAF5F5)
                                    : const Color(0xFFFFF5DD),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                occupied
                                    ? Icons.person_rounded
                                    : Icons.meeting_room_outlined,
                                color: occupied
                                    ? const Color(0xFF006A6A)
                                    : const Color(0xFFB78103),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resident.roomLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    occupied
                                        ? '${resident.userName} • sampai ${resident.endDate}'
                                        : 'Kamar kosong dan siap diisi',
                                    style: const TextStyle(
                                      color: Color(0xFF5D6B6B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StatusBadge(
                              label: occupied ? 'Terisi' : 'Tersedia',
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

enum OwnerTransactionFilter { all, thisMonth, unpaid, overdue, paid }

class OwnerTransactionsPage extends StatefulWidget {
  const OwnerTransactionsPage({
    super.key,
    this.initialFilter = OwnerTransactionFilter.all,
    this.initialQuery = '',
  });

  final OwnerTransactionFilter initialFilter;
  final String initialQuery;

  @override
  State<OwnerTransactionsPage> createState() => _OwnerTransactionsPageState();
}

class _OwnerTransactionsPageState extends State<OwnerTransactionsPage> {
  late final TextEditingController _searchController;
  late OwnerTransactionFilter _selectedFilter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _query = widget.initialQuery;
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Riwayat Transaksi'),
      ),
      body: StreamBuilder<List<BookingData>>(
        stream: FirestoreService.instance.ownerBookingsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen(label: 'Memuat transaksi...');
          }

          final transactions = _filterTransactions(
            snapshot.data ?? const <BookingData>[],
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Cari nama penghuni, kamar, atau metode bayar...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: OwnerTransactionFilter.values.map((filter) {
                    final selected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_transactionFilterLabel(filter)),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedFilter = filter),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              if (transactions.isEmpty)
                const _EmptyStateCard(
                  title: 'Belum ada transaksi yang cocok',
                  subtitle:
                      'Coba ubah filter atau tunggu pembayaran/booking berikutnya masuk.',
                )
              else
                ...List.generate(transactions.length, (index) {
                  final booking = transactions[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == transactions.length - 1 ? 0 : 14,
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                TransactionDetailPage(booking: booking),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
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
                                Expanded(
                                  child: Text(
                                    booking.userName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                _StatusBadge(label: booking.paymentStatus),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _SummaryRow(
                              label: 'Tanggal pembayaran',
                              value: booking.paymentUpdatedAt == null
                                  ? 'Belum ada'
                                  : _formatLongDate(booking.paymentUpdatedAt!),
                            ),
                            const SizedBox(height: 6),
                            _SummaryRow(
                              label: 'Metode',
                              value: booking.paymentMethod,
                            ),
                            const SizedBox(height: 6),
                            _SummaryRow(
                              label: 'Nominal',
                              value: booking.total,
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  List<BookingData> _filterTransactions(List<BookingData> bookings) {
    final now = DateTime.now();
    return bookings.where((booking) {
      final matchesFilter = switch (_selectedFilter) {
        OwnerTransactionFilter.all => true,
        OwnerTransactionFilter.thisMonth =>
          booking.sortKey.month == now.month &&
              booking.sortKey.year == now.year,
        OwnerTransactionFilter.unpaid =>
          booking.paymentStatus == 'Belum Bayar' ||
              booking.paymentStatus == 'Pending',
        OwnerTransactionFilter.overdue => booking.paymentStatus == 'Overdue',
        OwnerTransactionFilter.paid => booking.paymentStatus == 'Lunas',
      };
      final matchesQuery =
          _query.isEmpty ||
          booking.userName.toLowerCase().contains(_query) ||
          booking.roomLabel.toLowerCase().contains(_query) ||
          booking.paymentMethod.toLowerCase().contains(_query);
      return matchesFilter && matchesQuery;
    }).toList()..sort((a, b) => b.sortKey.compareTo(a.sortKey));
  }
}

class OwnerBookingDetailPage extends StatelessWidget {
  const OwnerBookingDetailPage({super.key, required this.booking});

  final BookingData booking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detail Booking'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _OwnerDetailHeader(
            title: booking.userName,
            subtitle: '${booking.kos.name} • ${booking.roomLabel}',
            badge: booking.status,
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Data calon penghuni',
            subtitle: 'Informasi dasar sebelum pemilik memutuskan booking.',
            child: Column(
              children: [
                _SummaryRow(label: 'Nomor HP', value: booking.userPhone),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Email', value: booking.userEmail),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Kontak darurat',
                  value: booking.emergencyContact,
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Tanggal booking',
                  value: _formatLongDate(booking.sortKey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Informasi booking',
            subtitle: 'Rangkuman booking, pembayaran, dan bukti DP.',
            child: Column(
              children: [
                _SummaryRow(label: 'Tanggal masuk', value: booking.startDate),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Durasi sewa', value: booking.durationLabel),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Status bayar',
                  value: booking.paymentStatus,
                ),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Metode', value: booking.paymentMethod),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Total', value: booking.total, bold: true),
                if (booking.note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Catatan user: ${booking.note}',
                      style: const TextStyle(
                        color: Color(0xFF5D6B6B),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
                if (booking.paymentProofUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bukti pembayaran: ${booking.paymentProofUrl}',
                      style: const TextStyle(
                        color: Color(0xFF006A6A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _buildActions(context),
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[
      OutlinedButton.icon(
        onPressed: () async {
          final chatId = await FirestoreService.instance.createOrGetOwnerChat(
            booking,
          );
          if (!context.mounted) {
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ChatDetailPage(kos: booking.kos, chatId: chatId),
            ),
          );
        },
        icon: const Icon(Icons.chat_rounded),
        label: const Text('Chat User'),
      ),
    ];

    if (booking.status == 'Menunggu Konfirmasi') {
      actions.add(
        FilledButton(
          onPressed: () => _updateBookingStatus(context, 'Sudah Dikonfirmasi'),
          child: const Text('Terima'),
        ),
      );
      actions.add(
        FilledButton.tonal(
          onPressed: () => _rejectBooking(context),
          child: const Text('Tolak'),
        ),
      );
    } else if (booking.status == 'Sudah Dikonfirmasi') {
      actions.add(
        FilledButton(
          onPressed: () => _updateBookingStatus(context, 'Sudah Check-in'),
          child: const Text('Tandai Check-in'),
        ),
      );
    } else if (booking.status == 'Sudah Check-in') {
      actions.add(
        FilledButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ResidentDetailPage(booking: booking),
              ),
            );
          },
          child: const Text('Lihat Penghuni'),
        ),
      );
    }

    return actions;
  }

  Future<void> _updateBookingStatus(BuildContext context, String status) async {
    try {
      await FirestoreService.instance.updateBookingStatus(
        booking: booking,
        status: status,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status booking diubah menjadi $status.')),
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    }
  }

  Future<void> _rejectBooking(BuildContext context) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih alasan pembatalan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                ..._cancelReasons.map((reason) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(reason),
                    onTap: () => Navigator.pop(context, reason),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (reason == null) {
      return;
    }

    try {
      await FirestoreService.instance.updateBookingStatus(
        booking: booking,
        status: 'Dibatalkan',
        cancelReason: reason,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Booking dibatalkan: $reason')));
    } on FirebaseException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    }
  }
}

class ResidentDetailPage extends StatelessWidget {
  const ResidentDetailPage({super.key, required this.booking});

  final BookingData booking;

  @override
  Widget build(BuildContext context) {
    final dueDate = _nextBillingDueDate(booking.startDateValue, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detail Penghuni'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _OwnerDetailHeader(
            title: booking.userName,
            subtitle: '${booking.kos.name} • ${booking.roomLabel}',
            badge: booking.paymentStatus,
            photoUrl: booking.userPhoto,
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Informasi pribadi',
            subtitle:
                'Ringkasan data penghuni yang bisa dipakai owner untuk operasional harian.',
            child: Column(
              children: [
                _SummaryRow(label: 'Gender', value: '-'),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Nomor HP', value: booking.userPhone),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Email', value: booking.userEmail),
                const SizedBox(height: 6),
                _SummaryRow(label: 'KTP', value: '-'),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Kontak darurat',
                  value: booking.emergencyContact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Informasi sewa',
            subtitle:
                'Semua status aktif dan tanggal penting dalam satu tempat.',
            child: Column(
              children: [
                _SummaryRow(label: 'Nomor kamar', value: booking.roomLabel),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Tanggal masuk', value: booking.startDate),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Durasi sewa', value: booking.durationLabel),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Tanggal jatuh tempo',
                  value: _formatLongDate(dueDate),
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Status pembayaran',
                  value: booking.paymentStatus,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Catatan penghuni',
            subtitle:
                'Catatan dari penyewa dan owner tersimpan agar histori penghuni tetap kebaca.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.note.isEmpty
                      ? 'Belum ada catatan dari penyewa.'
                      : booking.note,
                  style: const TextStyle(
                    color: Color(0xFF5D6B6B),
                    height: 1.45,
                  ),
                ),
                if (booking.ownerNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...booking.ownerNotes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('• $note'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Timeline penghuni',
            subtitle:
                'Riwayat singkat biar semua interaksi penghuni tetap ter-track.',
            child: Column(
              children: [
                _TimelineTile(
                  title: 'Booking kamar',
                  subtitle: _formatLongDate(booking.sortKey),
                ),
                _TimelineTile(
                  title: 'Check-in terjadwal',
                  subtitle: booking.startDate,
                ),
                _TimelineTile(
                  title: 'Jatuh tempo berikutnya',
                  subtitle: _formatLongDate(dueDate),
                ),
                if (booking.paymentUpdatedAt != null)
                  _TimelineTile(
                    title: 'Update pembayaran',
                    subtitle: _formatLongDate(booking.paymentUpdatedAt!),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final chatId = await FirestoreService.instance
                      .createOrGetOwnerChat(booking);
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ChatDetailPage(kos: booking.kos, chatId: chatId),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_rounded),
                label: const Text('Chat'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          OwnerTransactionsPage(initialQuery: booking.userName),
                    ),
                  );
                },
                child: const Text('Lihat Transaksi'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => _showAddNoteSheet(context),
                child: const Text('Tambah Catatan'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _showExtendSheet(context),
                child: const Text('Perpanjang'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _finishResident(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9F4035),
                ),
                child: const Text('Keluarkan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddNoteSheet(BuildContext context) async {
    final controller = TextEditingController();
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah catatan owner',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Sering telat bayar',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, controller.text.trim()),
                  child: const Text('Simpan Catatan'),
                ),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();

    if (note == null || note.isEmpty) {
      return;
    }

    try {
      await FirestoreService.instance.addOwnerNote(
        bookingId: booking.id,
        note: note,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Catatan owner disimpan.')));
    } on FirebaseException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    }
  }

  Future<void> _showExtendSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perpanjang sewa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                ...const [1, 3, 6].map((months) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Tambah $months bulan'),
                    onTap: () => Navigator.pop(context, months),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    try {
      await FirestoreService.instance.extendBooking(
        booking: booking,
        additionalMonths: selected,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sewa diperpanjang $selected bulan.')),
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    }
  }

  Future<void> _finishResident(BuildContext context) async {
    try {
      await FirestoreService.instance.updateBookingStatus(
        booking: booking,
        status: 'Selesai',
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Penghuni dikeluarkan.')));
    } on FirebaseException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
    }
  }
}

class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({super.key, required this.booking});

  final BookingData booking;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detail Transaksi'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _OwnerDetailHeader(
            title: booking.userName,
            subtitle: '${booking.kos.name} • ${booking.roomLabel}',
            badge: booking.paymentStatus,
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Rincian transaksi',
            subtitle:
                'Data pembayaran yang bisa dipakai owner untuk approval dan follow up.',
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Tanggal pembayaran',
                  value: booking.paymentUpdatedAt == null
                      ? 'Belum ada'
                      : _formatLongDate(booking.paymentUpdatedAt!),
                ),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Nominal', value: booking.total, bold: true),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Metode pembayaran',
                  value: booking.paymentMethod,
                ),
                const SizedBox(height: 6),
                _SummaryRow(label: 'Status', value: booking.paymentStatus),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Jenis pembayaran',
                  value: booking.paymentProofUrl.isEmpty
                      ? 'Belum ada DP'
                      : 'DP / verifikasi manual',
                ),
                const SizedBox(height: 6),
                const _SummaryRow(label: 'Admin fee', value: 'Rp 0'),
                if (booking.paymentProofUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Bukti transfer: ${booking.paymentProofUrl}',
                      style: const TextStyle(
                        color: Color(0xFF006A6A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () async {
                final chatId = await FirestoreService.instance
                    .createOrGetOwnerChat(booking);
                if (!context.mounted) {
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ChatDetailPage(kos: booking.kos, chatId: chatId),
                  ),
                );
              },
              child: const Text('Kirim Reminder'),
            ),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Invoice demo siap diunduh pada versi berikutnya.',
                    ),
                  ),
                );
              },
              child: const Text('Download Invoice'),
            ),
            FilledButton(
              onPressed: booking.paymentStatus == 'Lunas'
                  ? null
                  : () async {
                      try {
                        await FirestoreService.instance
                            .updateBookingPaymentStatus(
                              bookingId: booking.id,
                              paymentStatus: 'Lunas',
                            );
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pembayaran berhasil di-approve.'),
                          ),
                        );
                      } on FirebaseException catch (error) {
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_firebaseMessage(error))),
                        );
                      }
                    },
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomDetailPage extends StatelessWidget {
  const RoomDetailPage({
    super.key,
    required this.kos,
    required this.roomLabel,
    required this.currentResident,
    required this.history,
  });

  final KosData kos;
  final String roomLabel;
  final BookingData? currentResident;
  final List<BookingData> history;

  @override
  Widget build(BuildContext context) {
    final occupied = currentResident != null && currentResident!.id.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detail Kamar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.network(
              kos.gallery.isNotEmpty ? kos.gallery.first : '',
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          _OwnerDetailHeader(
            title: roomLabel,
            subtitle: kos.name,
            badge: occupied ? 'Terisi' : 'Tersedia',
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Informasi kamar',
            subtitle: 'Status ruang, penghuni sekarang, dan fasilitas utama.',
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Penghuni sekarang',
                  value: occupied ? currentResident!.userName : 'Belum ada',
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Harga sewa',
                  value: '${_currency(kos.price)} / bulan',
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: 'Status kamar',
                  value: occupied ? 'Aktif ditempati' : 'Siap dipasarkan',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kos.facilities
                        .map((facility) => _SmallPill(label: facility))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _OwnerSectionCard(
            title: 'Riwayat penghuni',
            subtitle: 'Semua penghuni yang pernah menempati kamar ini.',
            child: history.isEmpty
                ? const Text(
                    'Belum ada riwayat penghuni untuk kamar ini.',
                    style: TextStyle(color: Color(0xFF5D6B6B)),
                  )
                : Column(
                    children: history.map((booking) {
                      return _OwnerListTile(
                        title: booking.userName,
                        subtitle:
                            '${booking.startDate} sampai ${booking.endDate}',
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
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => OwnerRegistrationPage(existingKos: kos),
                  ),
                );
              },
              child: const Text('Edit Kamar'),
            ),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Mode nonaktifkan kamar bisa disambung ke backend berikutnya.',
                    ),
                  ),
                );
              },
              child: const Text('Nonaktifkan'),
            ),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kamar ditandai maintenance secara lokal.'),
                  ),
                );
              },
              child: const Text('Maintenance'),
            ),
          ],
        ),
      ),
    );
  }
}

class OwnerNotificationsPage extends StatelessWidget {
  const OwnerNotificationsPage({
    super.key,
    required this.bookings,
    required this.kos,
  });

  final List<BookingData> bookings;
  final KosData? kos;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final notifications = <_OwnerNotificationData>[
      ...bookings
          .where((booking) => booking.status == 'Menunggu Konfirmasi')
          .map(
            (booking) => _OwnerNotificationData(
              title: 'Ada booking baru',
              subtitle: '${booking.userName} booking ${booking.roomLabel}',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => OwnerBookingDetailPage(booking: booking),
                  ),
                );
              },
            ),
          ),
      ...bookings
          .where((booking) => booking.paymentStatus == 'Overdue')
          .map(
            (booking) => _OwnerNotificationData(
              title: 'Penghuni telat bayar',
              subtitle: '${booking.userName} belum membayar tagihan bulan ini',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ResidentDetailPage(booking: booking),
                  ),
                );
              },
            ),
          ),
      ...bookings
          .where((booking) => booking.status == 'Sudah Check-in')
          .where(
            (booking) =>
                _nextBillingDueDate(
                  booking.startDateValue,
                  now,
                ).difference(now).inDays <=
                3,
          )
          .map(
            (booking) => _OwnerNotificationData(
              title: 'Jatuh tempo pembayaran',
              subtitle: '${booking.userName} jatuh tempo dalam 3 hari',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ResidentDetailPage(booking: booking),
                  ),
                );
              },
            ),
          ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Notifikasi'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          if (kos != null)
            _OwnerSectionCard(
              title: 'Kos aktif',
              subtitle: '${kos!.name} • ${kos!.area}',
              child: const Text(
                'Semua notifikasi di bawah akan mengarahkan kamu ke halaman yang terkait.',
              ),
            ),
          if (notifications.isNotEmpty) const SizedBox(height: 16),
          if (notifications.isEmpty)
            const _EmptyStateCard(
              title: 'Belum ada notifikasi',
              subtitle:
                  'Booking baru, reminder bayar, dan aktivitas penting akan muncul di sini.',
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
                  onTap: item.onTap,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEAF5F5),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: Color(0xFF006A6A),
                    ),
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
  }
}

class OwnerSettingsPage extends StatelessWidget {
  const OwnerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Pengaturan Akun'),
      ),
      body: StreamBuilder<AppUserData?>(
        stream: FirestoreService.instance.userProfileStream(user.uid),
        builder: (context, userSnapshot) {
          final profile = userSnapshot.data;
          return StreamBuilder<KosData?>(
            stream: FirestoreService.instance.ownerKosStream(user.uid),
            builder: (context, kosSnapshot) {
              final kos = kosSnapshot.data;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  _ProfileHeader(
                    name: profile?.name ?? user.displayName ?? 'Pemilik Kos',
                    email: profile?.email ?? user.email ?? '-',
                    role: profile?.role ?? 'pemilik',
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
                        const _SummaryRow(
                          label: 'Nomor HP',
                          value: 'Kelola dari data penghuni / akun',
                        ),
                        const SizedBox(height: 6),
                        const _SummaryRow(
                          label: 'Rekening pembayaran',
                          value: 'Belum diisi',
                        ),
                        const SizedBox(height: 6),
                        const _SummaryRow(
                          label: 'Jam operasional',
                          value: '08.00 - 21.00',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProfileMenuTile(
                    icon: Icons.edit_rounded,
                    title: 'Edit Profil Kos',
                    subtitle:
                        'Ubah nama kos, alamat, foto, mode approval, dan fasilitas',
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
                    icon: Icons.lock_reset_rounded,
                    title: 'Ubah Password',
                    subtitle: 'Kelola keamanan akun owner',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Reset password bisa disambung ke Firebase Auth berikutnya.',
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
                      await FirebaseAuth.instance.signOut();
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
                                  Text('Hari ini • Perangkat aktif saat ini'),
                                  SizedBox(height: 8),
                                  Text(
                                    'Riwayat login detail bisa disambung setelah backend audit disiapkan.',
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
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class OwnerRegistrationPage extends StatefulWidget {
  const OwnerRegistrationPage({super.key, this.existingKos});

  final KosData? existingKos;

  @override
  State<OwnerRegistrationPage> createState() => _OwnerRegistrationPageState();
}

class _OwnerRegistrationPageState extends State<OwnerRegistrationPage> {
  final _ownerNameController = TextEditingController();
  final _kosNameController = TextEditingController();
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _roomController = TextEditingController(text: '1');
  final _facilityController = TextEditingController();
  final _photoController = TextEditingController();

  String _selectedCategory = 'Campur';
  String _selectedApprovalMode = 'Manual Approval';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final existingKos = widget.existingKos;
    _ownerNameController.text =
        existingKos?.ownerName ?? user?.displayName ?? '';
    _kosNameController.text = existingKos?.name ?? '';
    _areaController.text = existingKos?.area ?? '';
    _addressController.text = existingKos?.address ?? '';
    _descriptionController.text = existingKos?.description ?? '';
    _priceController.text = existingKos == null
        ? ''
        : existingKos.price.toString();
    _roomController.text = existingKos == null
        ? '1'
        : existingKos.availableRooms.toString();
    _facilityController.text = existingKos?.facilities.join(', ') ?? '';
    _photoController.text =
        existingKos != null && existingKos.gallery.isNotEmpty
        ? existingKos.gallery.first
        : _sampleKosMap1['foto_urls'][0] as String;
    _selectedCategory = existingKos?.category ?? 'Campur';
    _selectedApprovalMode = existingKos?.approvalMode ?? 'Manual Approval';
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _kosNameController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _roomController.dispose();
    _facilityController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingKos != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Listing Kos' : 'Daftar Pemilik Kos'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? 'Perbarui data listing kosmu'
                      : 'Lengkapi data kos pertamamu',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isEditing
                      ? 'Nama kos, harga, fasilitas, dan detail lainnya bisa kamu ubah kapan saja dari sini.'
                      : 'Setelah dikirim, akunmu akan berubah menjadi pemilik dan listing kos langsung tampil di halaman utama.',
                  style: const TextStyle(
                    color: Color(0xFF5D6B6B),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _InputField(
            controller: _ownerNameController,
            label: 'Nama pemilik',
            hintText: 'Nama lengkap pemilik kos',
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _kosNameController,
            label: 'Nama kos',
            hintText: 'Contoh: Kos Melati Harmoni',
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _areaController,
            label: 'Area',
            hintText: 'Contoh: Jakarta Selatan',
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _addressController,
            label: 'Alamat lengkap',
            hintText: 'Masukkan alamat kos',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _descriptionController,
            label: 'Deskripsi kos',
            hintText: 'Jelaskan fasilitas dan keunggulan kos',
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _priceController,
            label: 'Harga per bulan',
            hintText: 'Contoh: 1500000',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _roomController,
            label: 'Jumlah kamar tersedia',
            hintText: 'Contoh: 3',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _SelectCard(
            label: 'Kategori kos',
            value: _selectedCategory,
            items: const ['Campur', 'Putra', 'Putri', 'Eksklusif'],
            onChanged: (value) => setState(() => _selectedCategory = value),
          ),
          const SizedBox(height: 16),
          _SelectCard(
            label: 'Persetujuan booking',
            value: _selectedApprovalMode,
            items: const ['Manual Approval', 'Auto Approval'],
            onChanged: (value) => setState(() => _selectedApprovalMode = value),
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _facilityController,
            label: 'Fasilitas',
            hintText: 'Pisahkan dengan koma, contoh: WiFi, AC, CCTV',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: _photoController,
            label: 'URL foto kos',
            hintText: 'Tempel link foto utama kos',
            keyboardType: TextInputType.url,
          ),
        ],
      ),
      bottomSheet: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton(
          onPressed: _saving ? null : _submit,
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
              : Text(isEditing ? 'Simpan Perubahan' : 'Kirim Pendaftaran'),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final ownerName = _ownerNameController.text.trim();
    final kosName = _kosNameController.text.trim();
    final area = _areaController.text.trim();
    final address = _addressController.text.trim();
    final description = _descriptionController.text.trim();
    final monthlyPrice = int.tryParse(_priceController.text.trim());
    final availableRooms = int.tryParse(_roomController.text.trim());
    final photoUrl = _photoController.text.trim();
    final facilities = _facilityController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (ownerName.isEmpty ||
        kosName.isEmpty ||
        area.isEmpty ||
        address.isEmpty ||
        description.isEmpty ||
        monthlyPrice == null ||
        availableRooms == null ||
        photoUrl.isEmpty) {
      _showMessage('Semua data wajib diisi dengan benar.');
      return;
    }

    if (facilities.isEmpty) {
      _showMessage('Isi minimal satu fasilitas kos.');
      return;
    }

    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      if (widget.existingKos == null) {
        await FirestoreService.instance.registerOwnerKos(
          user: user,
          ownerName: ownerName,
          kosName: kosName,
          area: area,
          address: address,
          description: description,
          monthlyPrice: monthlyPrice,
          availableRooms: availableRooms,
          category: _selectedCategory,
          approvalMode: _selectedApprovalMode,
          facilities: facilities,
          photoUrl: photoUrl,
        );
      } else {
        await FirestoreService.instance.updateOwnerKos(
          user: user,
          kosId: widget.existingKos!.id,
          ownerName: ownerName,
          kosName: kosName,
          area: area,
          address: address,
          description: description,
          monthlyPrice: monthlyPrice,
          availableRooms: availableRooms,
          category: _selectedCategory,
          approvalMode: _selectedApprovalMode,
          facilities: facilities,
          photoUrl: photoUrl,
        );
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingKos == null
                ? 'Pendaftaran pemilik berhasil. Listing kos kamu sudah aktif.'
                : 'Perubahan listing kos berhasil disimpan.',
          ),
        ),
      );
      Navigator.pop(context);
    } on FirebaseException catch (error) {
      _showMessage(_firebaseMessage(error));
    } catch (_) {
      _showMessage('Pendaftaran pemilik gagal diproses. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

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
                        value: profile?.phoneNumber == null ||
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
                                builder: (_) => TenantProfileEditPage(
                                  profile: profile,
                                ),
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
                            builder: (_) => TenantProfileEditPage(
                              profile: profile,
                            ),
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

class FirestoreService {
  FirestoreService._();

  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _kos => _db.collection('kos');
  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    final userRef = _users.doc(user.uid);
    final snapshot = await userRef.get();
    final existing = snapshot.data() ?? const <String, dynamic>{};
    final existingRole = existing['role'] as String? ?? 'penyewa';
    final canSeedAdmin = _adminSeedEmails.contains(email.toLowerCase());

    if (!_isAdminRole(existingRole) && canSeedAdmin) {
      await userRef.set({
        'name':
            existing['name'] as String? ?? user.displayName ?? 'Admin Koshub',
        'email': user.email,
        'role': 'super_admin',
        'is_active': true,
        'account_status': 'Aktif',
        'verification_status': 'Terverifikasi',
        'login_activity': 'Login ${_formatLongDate(DateTime.now())}',
        'updated_at': FieldValue.serverTimestamp(),
        'created_at': existing['created_at'] ?? FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    if (!_isAdminRole(existingRole)) {
      await FirebaseAuth.instance.signOut();
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Akun ini bukan admin aplikasi Koshub.',
      );
    }

    await userRef.set({
      'login_activity': 'Login ${_formatLongDate(DateTime.now())}',
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> ensureUserProfile(
    User user, {
    required String fallbackName,
  }) async {
    final userRef = _users.doc(user.uid);
    final existingSnapshot = await userRef.get();
    final existingData = existingSnapshot.data();

    await userRef.set({
      'name': user.displayName ?? fallbackName,
      'email': user.email,
      'role': existingData?['role'] as String? ?? 'penyewa',
      'is_active': true,
      'photo_url': user.photoURL,
      'phone_number': existingData?['phone_number'] as String? ?? '',
      'created_at': existingData == null
          ? FieldValue.serverTimestamp()
          : existingData['created_at'],
    }, SetOptions(merge: true));
  }

  Future<void> updateTenantProfile({
    required User user,
    required String name,
    required String phoneNumber,
    required String photoUrl,
    String? newPassword,
  }) async {
    if (name.trim().isNotEmpty) {
      await user.updateDisplayName(name.trim());
    }
    if (newPassword != null && newPassword.trim().isNotEmpty) {
      await user.updatePassword(newPassword.trim());
    }

    await _users.doc(user.uid).set({
      'name': name.trim(),
      'email': user.email,
      'phone_number': phoneNumber.trim(),
      'photo_url': photoUrl.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> registerOwnerKos({
    required User user,
    required String ownerName,
    required String kosName,
    required String area,
    required String address,
    required String description,
    required int monthlyPrice,
    required int availableRooms,
    required String category,
    required String approvalMode,
    required List<String> facilities,
    required String photoUrl,
  }) async {
    await user.updateDisplayName(ownerName);
    final batch = _db.batch();
    final userRef = _users.doc(user.uid);
    final kosRef = _kos.doc();

    batch.set(userRef, {
      'name': ownerName,
      'email': user.email,
      'role': 'pemilik',
      'is_active': true,
      'photo_url': user.photoURL ?? photoUrl,
      'owner_status': 'Online',
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(kosRef, {
      'owner_id': user.uid,
      'owner_name': ownerName,
      'owner_status': 'Online',
      'owner_photo': user.photoURL ?? photoUrl,
      'nama_kos': kosName,
      'area': area,
      'alamat': address,
      'deskripsi': description,
      'harga_mulai': monthlyPrice,
      'fasilitas': facilities,
      'gender': category,
      'approval_mode': approvalMode,
      'foto_urls': [photoUrl],
      'rating': 0,
      'total_review': 0,
      'total_rooms': availableRooms,
      'available_rooms': availableRooms,
      'status': 'active',
      'created_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> updateOwnerKos({
    required User user,
    required String kosId,
    required String ownerName,
    required String kosName,
    required String area,
    required String address,
    required String description,
    required int monthlyPrice,
    required int availableRooms,
    required String category,
    required String approvalMode,
    required List<String> facilities,
    required String photoUrl,
  }) async {
    await user.updateDisplayName(ownerName);
    final batch = _db.batch();
    final userRef = _users.doc(user.uid);
    final kosRef = _kos.doc(kosId);

    batch.set(userRef, {
      'name': ownerName,
      'email': user.email,
      'role': 'pemilik',
      'is_active': true,
      'photo_url': user.photoURL ?? photoUrl,
      'owner_status': 'Online',
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(kosRef, {
      'owner_id': user.uid,
      'owner_name': ownerName,
      'owner_status': 'Online',
      'owner_photo': user.photoURL ?? photoUrl,
      'nama_kos': kosName,
      'area': area,
      'alamat': address,
      'deskripsi': description,
      'harga_mulai': monthlyPrice,
      'fasilitas': facilities,
      'gender': category,
      'approval_mode': approvalMode,
      'foto_urls': [photoUrl],
      'total_rooms': availableRooms,
      'available_rooms': availableRooms,
      'status': 'active',
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<AppUserData?> userProfileStream(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return null;
      }
      return AppUserData.fromMap(uid, data);
    });
  }

  Stream<KosData?> ownerKosStream(String ownerId) {
    return _kos
        .where('owner_id', isEqualTo: ownerId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => KosData.fromMap(doc.id, doc.data()))
              .toList();
          items.sort((a, b) => a.name.compareTo(b.name));
          return items.isEmpty ? null : items.first;
        });
  }

  Stream<List<KosData>> kosStream() {
    return _kos.where('status', isEqualTo: 'active').snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs
          .map((doc) => KosData.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => a.name.compareTo(b.name));
      return items;
    });
  }

  Future<void> seedSampleData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unauthenticated',
        message: 'Login dulu untuk membuat data demo.',
      );
    }

    final ownerName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email?.split('@').first ?? 'Pemilik Kos Demo';
    final ownerPhoto =
        user.photoURL ??
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80';
    final userRef = _users.doc(user.uid);
    final kosMenteng = _kos.doc('demo-${user.uid}-menteng');
    final kosKemang = _kos.doc('demo-${user.uid}-kemang');

    await Future.wait([
      userRef.set({
        'name': ownerName,
        'email': user.email,
        'role': 'pemilik',
        'is_active': true,
        'photo_url': ownerPhoto,
        'owner_status': 'Online',
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
      kosMenteng.set(
        _sampleKosMap1.forOwner(
          ownerId: user.uid,
          ownerName: ownerName,
          ownerPhoto: ownerPhoto,
        ),
      ),
      kosKemang.set(
        _sampleKosMap2.forOwner(
          ownerId: user.uid,
          ownerName: ownerName,
          ownerPhoto: ownerPhoto,
        ),
      ),
    ]);
  }

  Future<String> createOrGetChat(KosData kos) async {
    final user = FirebaseAuth.instance.currentUser!;
    final existing = await _chats
        .where('kos_id', isEqualTo: kos.id)
        .where('penyewa_id', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final chatRef = _chats.doc();
    await chatRef.set({
      'kos_id': kos.id,
      'kos_name': kos.name,
      'owner_name': kos.ownerName,
      'owner_photo': kos.ownerPhoto,
      'owner_id': kos.ownerId,
      'kos_snapshot': kos.toMap(),
      'penyewa_id': user.uid,
      'participant_ids': [user.uid, kos.ownerId],
      'last_message': 'Halo, saya tertarik dengan kos ini.',
      'last_message_time': FieldValue.serverTimestamp(),
    });

    await chatRef.collection('messages').add({
      'sender_id': user.uid,
      'text': 'Halo, saya tertarik dengan kos ini.',
      'timestamp': FieldValue.serverTimestamp(),
    });

    return chatRef.id;
  }

  Stream<List<ChatPreviewData>> userChatsStream(String userId) {
    return _chats
        .where('participant_ids', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final items = await Future.wait(
            snapshot.docs.map((doc) async {
              final data = doc.data();
              final kos = await _resolveKosData(
                kosId: data['kos_id'] as String? ?? '',
                fallbackMap: _asStringMap(data['kos_snapshot']),
              );
              if (kos == null) {
                return null;
              }
              return ChatPreviewData.fromMap(id: doc.id, data: data, kos: kos);
            }),
          );
          final resolved = items.whereType<ChatPreviewData>().toList();
          resolved.sort((a, b) => b.sortKey.compareTo(a.sortKey));
          return resolved;
        });
  }

  Stream<List<ChatMessageData>> messagesStream(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessageData.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> sendMessage(String chatId, String text) async {
    final user = FirebaseAuth.instance.currentUser!;
    await _chats.doc(chatId).collection('messages').add({
      'sender_id': user.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await _chats.doc(chatId).set({
      'last_message': text,
      'last_message_time': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<BookingData>> userBookingsStream(String userId) {
    return _bookings.where('user_id', isEqualTo: userId).snapshots().asyncMap((
      snapshot,
    ) async {
      final items = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data();
          final kos = await _resolveKosData(
            kosId: data['kos_id'] as String? ?? '',
            fallbackMap: _asStringMap(data['kos_snapshot']),
          );
          if (kos == null) {
            return null;
          }
          return BookingData.fromMap(id: doc.id, map: data, kos: kos);
        }),
      );
      final resolved = items.whereType<BookingData>().toList();
      resolved.sort((a, b) => b.sortKey.compareTo(a.sortKey));
      return resolved;
    });
  }

  Stream<List<BookingData>> ownerBookingsStream(String ownerId) {
    return _bookings.where('owner_id', isEqualTo: ownerId).snapshots().asyncMap(
      (snapshot) async {
        final items = await Future.wait(
          snapshot.docs.map((doc) async {
            final data = doc.data();
            final kos = await _resolveKosData(
              kosId: data['kos_id'] as String? ?? '',
              fallbackMap: _asStringMap(data['kos_snapshot']),
            );
            if (kos == null) {
              return null;
            }
            return BookingData.fromMap(id: doc.id, map: data, kos: kos);
          }),
        );
        final resolved = items.whereType<BookingData>().toList();
        resolved.sort((a, b) => b.sortKey.compareTo(a.sortKey));
        return resolved;
      },
    );
  }

  Stream<List<AppUserData>> allUsersStream() {
    return _users.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => AppUserData.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => b.sortKey.compareTo(a.sortKey));
      return items;
    });
  }

  Stream<List<AppUserData>> ownerUsersStream() {
    return allUsersStream().map(
      (items) => items.where((user) => user.role == 'pemilik').toList(),
    );
  }

  Stream<List<KosData>> adminKosStream() {
    return _kos.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => KosData.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) => a.name.compareTo(b.name));
      return items;
    });
  }

  Stream<List<BookingData>> allBookingsStream() {
    return _bookings.snapshots().asyncMap((snapshot) async {
      final items = await Future.wait(
        snapshot.docs.map((doc) async {
          final data = doc.data();
          final kos = await _resolveKosData(
            kosId: data['kos_id'] as String? ?? '',
            fallbackMap: _asStringMap(data['kos_snapshot']),
          );
          if (kos == null) {
            return null;
          }
          return BookingData.fromMap(id: doc.id, map: data, kos: kos);
        }),
      );
      final resolved = items.whereType<BookingData>().toList();
      resolved.sort((a, b) => b.sortKey.compareTo(a.sortKey));
      return resolved;
    });
  }

  Stream<AdminDashboardData> adminDashboardStream() {
    return _users.snapshots().asyncMap((userSnapshot) async {
      final kosSnapshot = await _kos.get();
      final bookingSnapshot = await _bookings.get();

      final users = userSnapshot.docs
          .map((doc) => AppUserData.fromMap(doc.id, doc.data()))
          .toList();
      final kosList = kosSnapshot.docs
          .map((doc) => KosData.fromMap(doc.id, doc.data()))
          .toList();
      final bookings = await Future.wait(
        bookingSnapshot.docs.map((doc) async {
          final data = doc.data();
          final kos = await _resolveKosData(
            kosId: data['kos_id'] as String? ?? '',
            fallbackMap: _asStringMap(data['kos_snapshot']),
          );
          if (kos == null) {
            return null;
          }
          return BookingData.fromMap(id: doc.id, map: data, kos: kos);
        }),
      );

      return AdminDashboardData.fromCollections(
        users: users,
        kosList: kosList,
        bookings: bookings.whereType<BookingData>().toList(),
      );
    });
  }

  Future<void> createBooking({
    required KosData kos,
    required String durationLabel,
    required String paymentMethod,
    required DateTime startDate,
    required String startDateLabel,
    required String phoneNumber,
    required String emergencyContact,
    required String roomLabel,
    required String note,
    required String paymentProofUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userProfile = await _users.doc(user.uid).get();
    final profileData = userProfile.data() ?? const <String, dynamic>{};
    final role = profileData['role'] as String? ?? 'penyewa';

    if (role == 'pemilik' || kos.ownerId == user.uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Akun pemilik kos tidak bisa melakukan booking.',
      );
    }

    final bookingStatus =
        kos.approvalMode == 'Auto Approval' && paymentProofUrl.isNotEmpty
        ? 'Sudah Dikonfirmasi'
        : 'Menunggu Konfirmasi';
    final paymentStatus = paymentProofUrl.isNotEmpty
        ? 'Pending'
        : 'Belum Bayar';
    final durationInMonths = _monthsFromDuration(durationLabel);
    final endDate = _addMonths(startDate, durationInMonths);

    await _bookings.add({
      'user_id': user.uid,
      'user_name':
          profileData['name'] as String? ??
          user.displayName ??
          user.email?.split('@').first ??
          'Penyewa',
      'user_email': user.email,
      'user_phone': phoneNumber,
      'user_photo': user.photoURL,
      'emergency_contact': emergencyContact,
      'owner_id': kos.ownerId,
      'kos_id': kos.id,
      'kos_snapshot': kos.toMap(),
      'room_label': roomLabel,
      'note': note,
      'payment_proof_url': paymentProofUrl,
      'start_date': Timestamp.fromDate(startDate),
      'start_date_label': startDateLabel,
      'end_date': Timestamp.fromDate(endDate),
      'end_date_label': _formatLongDate(endDate),
      'duration_label': durationLabel,
      'monthly_price': kos.price,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'status': bookingStatus,
      'approval_mode': kos.approvalMode,
      'total_price': _totalPrice(kos.price, durationLabel),
      'created_day_key': _dayKey(DateTime.now()),
      'created_at': FieldValue.serverTimestamp(),
      'status_updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<String> createOrGetOwnerChat(BookingData booking) async {
    final existing = await _chats
        .where('kos_id', isEqualTo: booking.kos.id)
        .where('penyewa_id', isEqualTo: booking.userId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final user = FirebaseAuth.instance.currentUser!;
    final chatRef = _chats.doc();
    await chatRef.set({
      'kos_id': booking.kos.id,
      'kos_name': booking.kos.name,
      'owner_name': booking.kos.ownerName,
      'owner_photo': booking.kos.ownerPhoto,
      'owner_id': booking.kos.ownerId,
      'kos_snapshot': booking.kos.toMap(),
      'penyewa_id': booking.userId,
      'participant_ids': [user.uid, booking.userId],
      'last_message':
          'Halo ${booking.userName}, booking kamu sedang kami review.',
      'last_message_time': FieldValue.serverTimestamp(),
    });

    await chatRef.collection('messages').add({
      'sender_id': user.uid,
      'text': 'Halo ${booking.userName}, booking kamu sedang kami review.',
      'timestamp': FieldValue.serverTimestamp(),
    });

    return chatRef.id;
  }

  Future<void> updateBookingStatus({
    required BookingData booking,
    required String status,
    String? cancelReason,
  }) async {
    final bookingRef = _bookings.doc(booking.id);
    final kosRef = _kos.doc(booking.kos.id);

    await _db.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);
      final kosSnapshot = await transaction.get(kosRef);
      final bookingData = bookingSnapshot.data();
      final kosData = kosSnapshot.data();

      if (bookingData == null || kosData == null) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Data booking atau kos tidak ditemukan.',
        );
      }

      final previousStatus = bookingData['status'] as String? ?? '';
      var availableRooms = (kosData['available_rooms'] as num?)?.toInt() ?? 0;
      final wasCheckedIn = previousStatus == 'Sudah Check-in';
      final willCheckIn = status == 'Sudah Check-in';

      if (!wasCheckedIn && willCheckIn) {
        availableRooms = math.max(0, availableRooms - 1);
      } else if (wasCheckedIn && !willCheckIn) {
        availableRooms += 1;
      }

      final updateData = <String, dynamic>{
        'status': status,
        'cancel_reason': cancelReason,
        'status_updated_at': FieldValue.serverTimestamp(),
      };
      if (status == 'Sudah Dikonfirmasi') {
        updateData['confirmed_at'] = FieldValue.serverTimestamp();
      }
      if (status == 'Sudah Check-in') {
        updateData['check_in_at'] = FieldValue.serverTimestamp();
      }
      if (status == 'Selesai') {
        updateData['completed_at'] = FieldValue.serverTimestamp();
      }
      if (status == 'Dibatalkan') {
        updateData['cancelled_at'] = FieldValue.serverTimestamp();
      }

      transaction.update(bookingRef, updateData);
      transaction.update(kosRef, {
        'available_rooms': availableRooms,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateBookingPaymentStatus({
    required String bookingId,
    required String paymentStatus,
  }) async {
    await _bookings.doc(bookingId).set({
      'payment_status': paymentStatus,
      'payment_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> cancelBookingByTenant(BookingData booking) async {
    await _bookings.doc(booking.id).set({
      'status': 'Dibatalkan',
      'cancel_reason': 'Dibatalkan oleh penyewa',
      'status_updated_at': FieldValue.serverTimestamp(),
      'cancelled_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addOwnerNote({
    required String bookingId,
    required String note,
  }) async {
    await _bookings.doc(bookingId).set({
      'owner_notes': FieldValue.arrayUnion([note]),
      'owner_note_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> extendBooking({
    required BookingData booking,
    required int additionalMonths,
  }) async {
    final newEndDate = _addMonths(booking.endDateValue, additionalMonths);
    final currentMonths = _monthsFromDuration(booking.durationLabel);
    final updatedMonths = currentMonths + additionalMonths;
    await _bookings.doc(booking.id).set({
      'duration_label': '$updatedMonths bulan',
      'end_date': Timestamp.fromDate(newEndDate),
      'end_date_label': _formatLongDate(newEndDate),
      'total_price':
          booking.totalPrice + (booking.monthlyPrice * additionalMonths),
      'status_updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<KosData?> _resolveKosData({
    required String kosId,
    required Map<String, dynamic>? fallbackMap,
  }) async {
    if (fallbackMap != null) {
      return KosData.fromMap(kosId, fallbackMap);
    }

    final kosDoc = await _kos.doc(kosId).get();
    if (!kosDoc.exists || kosDoc.data() == null) {
      return null;
    }

    return KosData.fromMap(kosDoc.id, kosDoc.data()!);
  }

  Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, entryValue) => MapEntry(key.toString(), entryValue),
      );
    }
    return null;
  }
}

class KosData {
  const KosData({
    required this.id,
    required this.name,
    required this.area,
    required this.address,
    required this.price,
    required this.rating,
    required this.reviewCount,
    required this.category,
    required this.totalRooms,
    required this.availableRooms,
    required this.description,
    required this.facilities,
    required this.gallery,
    required this.approvalMode,
    required this.ownerId,
    required this.ownerName,
    required this.ownerStatus,
    required this.ownerPhoto,
  });

  final String id;
  final String name;
  final String area;
  final String address;
  final int price;
  final double rating;
  final int reviewCount;
  final String category;
  final int totalRooms;
  final int availableRooms;
  final String description;
  final List<String> facilities;
  final List<String> gallery;
  final String approvalMode;
  final String ownerId;
  final String ownerName;
  final String ownerStatus;
  final String ownerPhoto;

  factory KosData.fromMap(String id, Map<String, dynamic> map) {
    return KosData(
      id: id,
      name: map['nama_kos'] as String? ?? '-',
      area: map['area'] as String? ?? '-',
      address: map['alamat'] as String? ?? '-',
      price: (map['harga_mulai'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['total_review'] as num?)?.toInt() ?? 0,
      category: map['gender'] as String? ?? '-',
      totalRooms:
          (map['total_rooms'] as num?)?.toInt() ??
          (map['available_rooms'] as num?)?.toInt() ??
          0,
      availableRooms: (map['available_rooms'] as num?)?.toInt() ?? 0,
      description: map['deskripsi'] as String? ?? '-',
      facilities: (map['fasilitas'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      gallery: (map['foto_urls'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      approvalMode: map['approval_mode'] as String? ?? 'Manual Approval',
      ownerId: map['owner_id'] as String? ?? '',
      ownerName: map['owner_name'] as String? ?? 'Pemilik Kos',
      ownerStatus: map['owner_status'] as String? ?? 'Online',
      ownerPhoto: map['owner_photo'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'owner_id': ownerId,
      'owner_name': ownerName,
      'owner_status': ownerStatus,
      'owner_photo': ownerPhoto,
      'nama_kos': name,
      'area': area,
      'alamat': address,
      'deskripsi': description,
      'harga_mulai': price,
      'fasilitas': facilities,
      'gender': category,
      'approval_mode': approvalMode,
      'foto_urls': gallery,
      'rating': rating,
      'total_review': reviewCount,
      'total_rooms': totalRooms,
      'available_rooms': availableRooms,
      'status': 'active',
    };
  }
}

class AppUserData {
  const AppUserData({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.photoUrl,
    required this.phoneNumber,
    required this.ktpNumber,
    required this.emergencyContact,
    required this.accountStatus,
    required this.verificationStatus,
    required this.bankAccountLabel,
    required this.loginActivity,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String photoUrl;
  final String phoneNumber;
  final String ktpNumber;
  final String emergencyContact;
  final String accountStatus;
  final String verificationStatus;
  final String bankAccountLabel;
  final String loginActivity;
  final DateTime createdAt;

  bool get isAdmin => _isAdminRole(role);

  String get roleLabel {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'moderator':
        return 'Moderator';
      case 'finance_admin':
        return 'Finance Admin';
      case 'customer_service':
        return 'Customer Service';
      case 'pemilik':
        return 'Pemilik Kos';
      default:
        return 'Penyewa';
    }
  }

  DateTime get sortKey => createdAt;

  factory AppUserData.fromMap(String id, Map<String, dynamic> map) {
    return AppUserData(
      id: id,
      name: map['name'] as String? ?? '-',
      email: map['email'] as String? ?? '-',
      role: map['role'] as String? ?? 'penyewa',
      photoUrl: map['photo_url'] as String? ?? '',
      phoneNumber: map['phone_number'] as String? ?? '-',
      ktpNumber: map['ktp_number'] as String? ?? '-',
      emergencyContact: map['emergency_contact'] as String? ?? '-',
      accountStatus: map['account_status'] as String? ?? 'Aktif',
      verificationStatus: map['verification_status'] as String? ?? 'Pending',
      bankAccountLabel: map['bank_account'] as String? ?? 'Belum diisi',
      loginActivity:
          map['login_activity'] as String? ?? 'Belum ada login tercatat',
      createdAt:
          (map['created_at'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.totalUsers,
    required this.totalOwners,
    required this.totalKos,
    required this.activeRooms,
    required this.bookingsToday,
    required this.platformRevenue,
    required this.activeComplaints,
    required this.blockedUsers,
    required this.reportedKos,
    required this.recentActivities,
    required this.latestOwnerSummary,
    required this.topKosSummary,
    required this.topBookingSummary,
  });

  final int totalUsers;
  final int totalOwners;
  final int totalKos;
  final int activeRooms;
  final int bookingsToday;
  final int platformRevenue;
  final int activeComplaints;
  final int blockedUsers;
  final int reportedKos;
  final List<AdminActivityItem> recentActivities;
  final String latestOwnerSummary;
  final String topKosSummary;
  final String topBookingSummary;

  factory AdminDashboardData.empty() {
    return const AdminDashboardData(
      totalUsers: 0,
      totalOwners: 0,
      totalKos: 0,
      activeRooms: 0,
      bookingsToday: 0,
      platformRevenue: 0,
      activeComplaints: 0,
      blockedUsers: 0,
      reportedKos: 0,
      recentActivities: [],
      latestOwnerSummary: 'Belum ada data pemilik terbaru.',
      topKosSummary: 'Belum ada listing aktif.',
      topBookingSummary: 'Belum ada booking masuk.',
    );
  }

  factory AdminDashboardData.fromCollections({
    required List<AppUserData> users,
    required List<KosData> kosList,
    required List<BookingData> bookings,
  }) {
    final today = _dayKey(DateTime.now());
    final owners = users.where((user) => user.role == 'pemilik').toList();
    owners.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    final activeRooms = kosList.fold<int>(
      0,
      (total, kos) => total + (kos.totalRooms - kos.availableRooms),
    );
    final bookingsToday = bookings.where((booking) {
      return _dayKey(booking.sortKey) == today;
    }).length;
    final platformRevenue = bookings
        .where((booking) => booking.paymentStatus == 'Lunas')
        .fold<int>(
          0,
          (total, booking) => total + (booking.totalPrice * 0.05).round(),
        );
    final activeComplaints = bookings.where((booking) {
      return booking.note.toLowerCase().contains('komplain') ||
          booking.note.toLowerCase().contains('lapor');
    }).length;
    final blockedUsers = users
        .where((user) => user.accountStatus == 'Diblokir')
        .length;
    final reportedKos = kosList
        .where((kos) => kos.description.toLowerCase().contains('laporan'))
        .length;

    final bookingCounts = <String, int>{};
    for (final booking in bookings) {
      bookingCounts.update(
        booking.kos.name,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    String topKosSummary = 'Belum ada listing aktif.';
    if (bookingCounts.isNotEmpty) {
      final top = bookingCounts.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      topKosSummary = '${top.key} | ${top.value} booking';
    }

    final recentActivities = bookings.take(5).map((booking) {
      return AdminActivityItem(
        title: '${booking.userName} booking ${booking.kos.name}',
        subtitle: '${booking.status} | ${booking.paymentStatus}',
        timeLabel: _formatTime(booking.sortKey),
        icon: Icons.bolt_rounded,
      );
    }).toList();

    if (recentActivities.length < 5) {
      recentActivities.addAll(
        owners
            .take(5 - recentActivities.length)
            .map(
              (owner) => AdminActivityItem(
                title: '${owner.name} masuk sebagai pemilik kos',
                subtitle:
                    '${owner.verificationStatus} | ${owner.accountStatus}',
                timeLabel: _formatTime(owner.createdAt),
                icon: Icons.verified_user_rounded,
              ),
            ),
      );
    }

    return AdminDashboardData(
      totalUsers: users.where((user) => !user.isAdmin).length,
      totalOwners: owners.length,
      totalKos: kosList.length,
      activeRooms: activeRooms,
      bookingsToday: bookingsToday,
      platformRevenue: platformRevenue,
      activeComplaints: activeComplaints,
      blockedUsers: blockedUsers,
      reportedKos: reportedKos,
      recentActivities: recentActivities,
      latestOwnerSummary: owners.isEmpty
          ? 'Belum ada owner baru.'
          : '${owners.first.name} | ${owners.first.verificationStatus}',
      topKosSummary: topKosSummary,
      topBookingSummary: bookings.isEmpty
          ? 'Belum ada booking masuk.'
          : '${bookings.first.kos.name} | ${bookings.first.status}',
    );
  }
}

class AdminActivityItem {
  const AdminActivityItem({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final IconData icon;
}

class ChatPreviewData {
  const ChatPreviewData({
    required this.id,
    required this.kos,
    required this.lastMessage,
    required this.timeLabel,
    required this.sortKey,
  });

  final String id;
  final KosData kos;
  final String lastMessage;
  final String timeLabel;
  final DateTime sortKey;

  factory ChatPreviewData.fromMap({
    required String id,
    required Map<String, dynamic> data,
    required KosData kos,
  }) {
    final timestamp =
        (data['last_message_time'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return ChatPreviewData(
      id: id,
      kos: kos,
      lastMessage: data['last_message'] as String? ?? '',
      timeLabel: _formatTime(timestamp),
      sortKey: timestamp,
    );
  }
}

class ChatMessageData {
  const ChatMessageData({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timeLabel,
  });

  final String id;
  final String senderId;
  final String text;
  final String timeLabel;

  factory ChatMessageData.fromMap(String id, Map<String, dynamic> map) {
    final timestamp =
        (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    return ChatMessageData(
      id: id,
      senderId: map['sender_id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      timeLabel: _formatTime(timestamp),
    );
  }
}

class BookingData {
  const BookingData({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.userPhoto,
    required this.emergencyContact,
    required this.kos,
    required this.roomLabel,
    required this.note,
    required this.paymentProofUrl,
    required this.startDate,
    required this.startDateValue,
    required this.endDate,
    required this.endDateValue,
    required this.durationLabel,
    required this.monthlyPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.cancelReason,
    required this.total,
    required this.totalPrice,
    required this.sortKey,
    required this.paymentUpdatedAt,
    required this.ownerNotes,
  });

  factory BookingData.empty(String roomLabel, KosData kos) {
    return BookingData(
      id: '',
      userId: '',
      userName: 'Belum terisi',
      userEmail: '-',
      userPhone: '-',
      userPhoto: '',
      emergencyContact: '-',
      kos: kos,
      roomLabel: roomLabel,
      note: '',
      paymentProofUrl: '',
      startDate: '-',
      startDateValue: DateTime.fromMillisecondsSinceEpoch(0),
      endDate: '-',
      endDateValue: DateTime.fromMillisecondsSinceEpoch(0),
      durationLabel: '-',
      monthlyPrice: 0,
      paymentMethod: '-',
      paymentStatus: 'Tersedia',
      status: 'Tersedia',
      cancelReason: '',
      total: _currency(0),
      totalPrice: 0,
      sortKey: DateTime.fromMillisecondsSinceEpoch(0),
      paymentUpdatedAt: null,
      ownerNotes: const [],
    );
  }

  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String userPhoto;
  final String emergencyContact;
  final KosData kos;
  final String roomLabel;
  final String note;
  final String paymentProofUrl;
  final String startDate;
  final DateTime startDateValue;
  final String endDate;
  final DateTime endDateValue;
  final String durationLabel;
  final int monthlyPrice;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String cancelReason;
  final String total;
  final int totalPrice;
  final DateTime sortKey;
  final DateTime? paymentUpdatedAt;
  final List<String> ownerNotes;

  factory BookingData.fromMap({
    required String id,
    required Map<String, dynamic> map,
    required KosData kos,
  }) {
    final timestamp =
        (map['created_at'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final startDateValue = _parseStoredDate(
      map['start_date'],
      fallbackLabel: map['start_date_label'] as String?,
      fallback: timestamp,
    );
    final durationLabel = map['duration_label'] as String? ?? '-';
    final endDateValue = _parseStoredDate(
      map['end_date'],
      fallbackLabel: map['end_date_label'] as String?,
      fallback: _addMonths(startDateValue, _monthsFromDuration(durationLabel)),
    );
    return BookingData(
      id: id,
      userId: map['user_id'] as String? ?? '',
      userName: map['user_name'] as String? ?? 'Penyewa',
      userEmail: map['user_email'] as String? ?? '-',
      userPhone: map['user_phone'] as String? ?? '-',
      userPhoto: map['user_photo'] as String? ?? '',
      emergencyContact: map['emergency_contact'] as String? ?? '-',
      kos: kos,
      roomLabel: map['room_label'] as String? ?? '-',
      note: map['note'] as String? ?? '',
      paymentProofUrl: map['payment_proof_url'] as String? ?? '',
      startDate:
          map['start_date_label'] as String? ?? _formatLongDate(startDateValue),
      startDateValue: startDateValue,
      endDate:
          map['end_date_label'] as String? ?? _formatLongDate(endDateValue),
      endDateValue: endDateValue,
      durationLabel: durationLabel,
      monthlyPrice: (map['monthly_price'] as num?)?.toInt() ?? kos.price,
      paymentMethod: map['payment_method'] as String? ?? '-',
      paymentStatus: map['payment_status'] as String? ?? 'Pending',
      status: map['status'] as String? ?? '-',
      cancelReason: map['cancel_reason'] as String? ?? '',
      total: _currency((map['total_price'] as num?)?.toInt() ?? 0),
      totalPrice: (map['total_price'] as num?)?.toInt() ?? 0,
      sortKey: timestamp,
      paymentUpdatedAt: (map['payment_updated_at'] as Timestamp?)?.toDate(),
      ownerNotes: (map['owner_notes'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onPressed,
  });

  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
          ),
          if (buttonLabel != null && onPressed != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onPressed, child: Text(buttonLabel!)),
          ],
        ],
      ),
    );
  }
}

class _HomeHero extends StatefulWidget {
  const _HomeHero({required this.onChanged, required this.onSubmitted});

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  State<_HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<_HomeHero> {
  late final FocusNode _focusNode;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 235,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFFD7F2F1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _sampleKosMap1['foto_urls'][1] as String,
            fit: BoxFit.cover,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  const Color(0xFF003636).withValues(alpha: 0.22),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Cari kos impianmu\ndi sini!',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF073B3A),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _focusNode.requestFocus(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      decoration: InputDecoration(
                        hintText: 'Cari lokasi atau nama kos...',
                        hintStyle: const TextStyle(color: Color(0xFF667271)),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF667271),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
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

class _CategorySection extends StatelessWidget {
  const _CategorySection();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CategoryItem(icon: Icons.female_rounded, label: 'Putri'),
        _CategoryItem(icon: Icons.male_rounded, label: 'Putra'),
        _CategoryItem(icon: Icons.groups_rounded, label: 'Campur'),
        _CategoryItem(icon: Icons.star_rounded, label: 'Eksklusif'),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EDEE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: const Color(0xFF006A6A), size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF5D6B6B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _KosCard extends StatelessWidget {
  const _KosCard({required this.kos, required this.onTap});

  final KosData kos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E7E7)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 190,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Image.network(kos.gallery.first, fit: BoxFit.cover),
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _TagChip(
                      label: kos.category,
                      color: kos.category == 'Eksklusif'
                          ? const Color(0xFF006A6A)
                          : const Color(0xFF9F4035),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF4B400),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${kos.rating.toStringAsFixed(1)} (${kos.reviewCount})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    kos.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kos.area,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF5D6B6B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kos.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF839090),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: kos.facilities
                        .take(3)
                        .map((facility) => _SmallPill(label: facility))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.meeting_room_rounded,
                        size: 16,
                        color: Color(0xFF5D6B6B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${kos.availableRooms} kamar tersedia',
                        style: const TextStyle(
                          color: Color(0xFF5D6B6B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      text: _currency(kos.price),
                      style: const TextStyle(
                        color: Color(0xFF006A6A),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                      children: const [
                        TextSpan(
                          text: ' / bulan',
                          style: TextStyle(
                            color: Color(0xFF5D6B6B),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
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

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFFFFDAD5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: [
                const Spacer(),
                Expanded(
                  child: Image.network(
                    _sampleKosMap2['foto_urls'][1] as String,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFFFFDAD5),
                    const Color(0xFFFFDAD5).withValues(alpha: 0.78),
                    const Color(0xFFFFDAD5).withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'FLASH SALE',
                  style: TextStyle(
                    color: Color(0xFF752219),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Diskon Rp 200 ribu',
                  style: TextStyle(
                    color: Color(0xFF752219),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Untuk penghuni baru bulan ini',
                  style: TextStyle(
                    color: Color(0xFF752219),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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

class _AuthModeChip extends StatelessWidget {
  const _AuthModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected
                  ? const Color(0xFF006A6A)
                  : const Color(0xFF5D6B6B),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF314040),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        items: items
            .map(
              (item) =>
                  DropdownMenuItem<String>(value: item, child: Text(item)),
            )
            .toList(),
        onChanged: (selected) {
          if (selected != null) {
            onChanged(selected);
          }
        },
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _FacilityChip extends StatelessWidget {
  const _FacilityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF006A6A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF5D6B6B),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DashboardShortcutChip extends StatelessWidget {
  const _DashboardShortcutChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF5F5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF006A6A)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF006A6A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerMetricCard extends StatelessWidget {
  const _OwnerMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 162,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF5D6B6B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF182022),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF5D6B6B),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerSectionCard extends StatelessWidget {
  const _OwnerSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _OwnerListTile extends StatelessWidget {
  const _OwnerListTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
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
              const SizedBox(width: 12),
              _StatusBadge(label: trailing),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: Color(0xFF006A6A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006A6A), Color(0xFF00A8A8)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(role, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF006A6A)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: bold ? const Color(0xFF182022) : const Color(0xFF5D6B6B),
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      fontSize: bold ? 16 : 14,
    );

    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    Color background = const Color(0xFFE5F7F6);
    Color foreground = const Color(0xFF006A6A);

    if (label.contains('Menunggu')) {
      background = const Color(0xFFFFF5DD);
      foreground = const Color(0xFFB78103);
    } else if (label.contains('Dibatalkan') ||
        label.contains('Overdue') ||
        label.contains('Telat')) {
      background = const Color(0xFFFFE4E0);
      foreground = const Color(0xFF9F4035);
    } else if (label.contains('Lunas') ||
        label.contains('Sudah Check-in') ||
        label.contains('Terisi')) {
      background = const Color(0xFFE5F7F6);
      foreground = const Color(0xFF006A6A);
    } else if (label.contains('Sudah Dikonfirmasi') ||
        label.contains('Pending') ||
        label.contains('Tersedia')) {
      background = const Color(0xFFEAF1FF);
      foreground = const Color(0xFF35589F);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: const Color(0xFF35589F)),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF182022),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF5D6B6B), height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminSectionCard extends StatelessWidget {
  const _AdminSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AdminShortcutChip extends StatelessWidget {
  const _AdminShortcutChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: const Color(0xFF35589F)),
      label: Text(label),
      onPressed: onTap,
      side: BorderSide.none,
      backgroundColor: const Color(0xFFEAF1FF),
    );
  }
}

class _AdminActionTile extends StatelessWidget {
  const _AdminActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEAF1FF),
        child: Icon(icon, color: const Color(0xFF35589F)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _AdminEntityTile extends StatelessWidget {
  const _AdminEntityTile({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFEAF1FF),
                child: Icon(icon, color: const Color(0xFF35589F)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF182022),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF5D6B6B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(label: badge),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminDetailHeader extends StatelessWidget {
  const _AdminDetailHeader({
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusBadge(label: badge),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Color(0xFF5D6B6B))),
        ],
      ),
    );
  }
}

class _AdminAccessErrorPage extends StatelessWidget {
  const _AdminAccessErrorPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 42,
                color: Color(0xFF9F4035),
              ),
              const SizedBox(height: 14),
              const Text(
                'Admin Belum Bisa Akses Data',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF5D6B6B),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5D6B6B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF182022),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hintText, required this.onChanged});

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _StaticActionLine extends StatelessWidget {
  const _StaticActionLine(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: Color(0xFF35589F),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _StaticBadgeChip extends StatelessWidget {
  const _StaticBadgeChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF35589F),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? const Color(0xFFD7F2F1)
        : Colors.transparent;
    final foregroundColor = selected
        ? const Color(0xFF003636)
        : const Color(0xFF667271);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foregroundColor),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _currency(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return 'Rp $buffer';
}

String _firebaseMessage(FirebaseException error) {
  switch (error.code) {
    case 'permission-denied':
      return error.message ??
          'Akses Firestore ditolak. Deploy/update rules Firestore dulu.';
    case 'unavailable':
      return 'Firestore belum bisa dihubungi. Periksa koneksi internet.';
    case 'not-found':
      return 'Data terkait tidak ditemukan. Muat ulang lalu coba lagi.';
    case 'unauthenticated':
      return 'Sesi login tidak valid. Silakan masuk ulang.';
    default:
      return error.message ?? 'Firebase gagal memproses permintaan.';
  }
}

String _streamErrorMessage(Object? error) {
  if (error is FirebaseException) {
    return _firebaseMessage(error);
  }
  return 'Terjadi kendala saat mengambil data admin. Cek rules Firestore dan koneksi.';
}

Future<void> _confirmCancelBooking(
  BuildContext context,
  BookingData booking,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Batalkan booking?'),
        content: Text(
          'Booking ${booking.kos.name} untuk ${booking.roomLabel} akan dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Batalkan'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  try {
    await FirestoreService.instance.cancelBookingByTenant(booking);
    if (!context.mounted) {
      return;
    }
    await _showLightDialog(
      context,
      title: 'Booking dibatalkan',
      message: 'Booking anda berhasil dibatalkan.',
    );
    if (!context.mounted) {
      return;
    }
    Navigator.pop(context);
  } on FirebaseException catch (error) {
    if (!context.mounted) {
      return;
    }
    _showLightDialog(
      context,
      title: 'Pembatalan gagal',
      message: _firebaseMessage(error),
    );
  }
}

Future<void> _showLightDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Oke'),
          ),
        ],
      );
    },
  );
}

bool _isAdminRole(String role) {
  return role == 'super_admin' ||
      role == 'admin' ||
      role == 'moderator' ||
      role == 'finance_admin' ||
      role == 'customer_service';
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour.$minute';
}

int _totalPrice(int monthlyPrice, String durationLabel) {
  final months = int.tryParse(durationLabel.split(' ').first) ?? 1;
  return monthlyPrice * months;
}

const List<String> _cancelReasons = [
  'Kamar penuh',
  'Pembayaran gagal',
  'Tidak sesuai aturan',
];

const List<String> _paymentStatuses = [
  'Lunas',
  'Pending',
  'Belum Bayar',
  'Overdue',
];

int _monthsFromDuration(String durationLabel) {
  return int.tryParse(durationLabel.split(' ').first) ?? 1;
}

DateTime _addMonths(DateTime date, int months) {
  final targetMonth = date.month + months;
  final year = date.year + ((targetMonth - 1) ~/ 12);
  final month = ((targetMonth - 1) % 12) + 1;
  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  final day = math.min(date.day, lastDayOfMonth);
  return DateTime(year, month, day);
}

String _formatLongDate(DateTime date) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

DateTime _parseStoredDate(
  Object? value, {
  String? fallbackLabel,
  DateTime? fallback,
}) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }
  if (fallbackLabel != null && fallbackLabel.isNotEmpty) {
    final parsed = _parseIndonesianDate(fallbackLabel);
    if (parsed != null) {
      return parsed;
    }
  }
  return fallback ?? DateTime.now();
}

DateTime? _parseIndonesianDate(String label) {
  final months = <String, int>{
    'januari': 1,
    'februari': 2,
    'maret': 3,
    'april': 4,
    'mei': 5,
    'juni': 6,
    'juli': 7,
    'agustus': 8,
    'september': 9,
    'oktober': 10,
    'november': 11,
    'desember': 12,
  };
  final parts = label.trim().split(' ');
  if (parts.length != 3) {
    return null;
  }
  final day = int.tryParse(parts[0]);
  final month = months[parts[1].toLowerCase()];
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) {
    return null;
  }
  return DateTime(year, month, day);
}

String _dayKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime _nextBillingDueDate(DateTime startDate, DateTime reference) {
  var dueDate = DateTime(reference.year, reference.month, startDate.day);
  final lastDay = DateTime(reference.year, reference.month + 1, 0).day;
  if (startDate.day > lastDay) {
    dueDate = DateTime(reference.year, reference.month, lastDay);
  }
  if (!dueDate.isAfter(reference)) {
    final nextMonth = DateTime(reference.year, reference.month + 1, 1);
    final nextLastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    final nextDay = math.min(startDate.day, nextLastDay);
    dueDate = DateTime(nextMonth.year, nextMonth.month, nextDay);
  }
  return dueDate;
}

String _checkInCountdownLabel(DateTime startDate) {
  final days = startDate.difference(DateTime.now()).inDays;
  if (days > 1) {
    return 'Check-in dalam $days hari';
  }
  if (days == 1) {
    return 'Check-in besok';
  }
  if (days == 0) {
    return 'Check-in hari ini';
  }
  return 'Tanggal check-in sudah lewat ${days.abs()} hari';
}

String _transactionFilterLabel(OwnerTransactionFilter filter) {
  switch (filter) {
    case OwnerTransactionFilter.all:
      return 'Semua';
    case OwnerTransactionFilter.thisMonth:
      return 'Bulan Ini';
    case OwnerTransactionFilter.unpaid:
      return 'Belum Bayar';
    case OwnerTransactionFilter.overdue:
      return 'Telat';
    case OwnerTransactionFilter.paid:
      return 'Lunas';
  }
}

extension _DemoKosOwner on Map<String, dynamic> {
  Map<String, dynamic> forOwner({
    required String ownerId,
    required String ownerName,
    required String ownerPhoto,
  }) {
    return {
      ...this,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'owner_status': 'Online',
      'owner_photo': ownerPhoto,
      'approval_mode': this['approval_mode'] ?? 'Manual Approval',
      'total_rooms': this['total_rooms'] ?? this['available_rooms'] ?? 0,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}

const Map<String, dynamic> _sampleKosMap1 = {
  'owner_id': 'demo-owner-rina',
  'owner_name': 'Bu Rina',
  'owner_status': 'Online',
  'owner_photo':
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80',
  'nama_kos': 'Kos Menteng Syariah',
  'area': 'Jakarta Pusat',
  'alamat': 'Jl. HOS Cokroaminoto No. 18, Menteng, Jakarta Pusat',
  'deskripsi':
      'Kos nyaman untuk mahasiswi dan karyawan dengan lingkungan tenang, akses mudah ke transportasi umum, serta keamanan 24 jam.',
  'harga_mulai': 1500000,
  'fasilitas': ['WiFi Gratis', 'AC', 'CCTV', 'Dapur Bersama', 'Parkir Motor'],
  'gender': 'Putri',
  'foto_urls': [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuC2D57JOt6UVKCAyyDeDdptmIBGYgck1Ue48jjfJQb3kIU95FQdBMD6VCxfQbBp0YPh8V-jOCjqg__tiHnXkfZTf48h5dD9p0umsCPvfz10JYJ10Wep4WWe8XCZRp40gokF-HLXaCSdn2A-w4Muc8igEC42zgaGYzcSsoxXZIDcZxToKULKyVarbgerAjGTDPDsrRTglAx_GheZmLCJIbjbxUqBPYseBCZ1quwgl5BnTKS-O7mC0pCq82MJECLzhJ9cqfDV5ea9',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDn4tW5bdE8f1lqK3t3lYIgcPfwHcKHMo5tQfvpjQluS7BD0zV_3tvTgIKGeqyB5reZIeue7h3ixhunQli9uywMlzXvFSd4-oBKv340V8O5yHvYohZ8WLjiXZa1wnuLuSdGvdY-nTX3IkZkewXkfOrXOpqLKt8Vw9dfjzwxUCrExOjOjdJlJ7cK386R-Lcnym2wiSAE-o7ovXu4qZLndSqqn0I9IXgZpuo5H4h75guKvOTzPm7QgwQzRff7CGdfpez5BJGIjCnA',
  ],
  'rating': 4.8,
  'total_review': 120,
  'available_rooms': 3,
  'status': 'active',
};

const Map<String, dynamic> _sampleKosMap2 = {
  'owner_id': 'demo-owner-dimas',
  'owner_name': 'Pak Dimas',
  'owner_status': 'Terakhir aktif 5 menit lalu',
  'owner_photo':
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
  'nama_kos': 'Griya Urban Kemang',
  'area': 'Jakarta Selatan',
  'alamat': 'Jl. Kemang Utara No. 7, Mampang, Jakarta Selatan',
  'deskripsi':
      'Kos eksklusif dengan desain modern, kamar mandi dalam, laundry, dan lokasi strategis dekat area perkantoran.',
  'harga_mulai': 3200000,
  'fasilitas': ['KM Dalam', 'Laundry', 'WiFi', 'CCTV', 'Dapur Mini'],
  'gender': 'Eksklusif',
  'foto_urls': [
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAogmMwDw1tdNckktoBtTIzdjTITVdLL8ZGZqMyKgS2nPXQZi3dXnNiH5YmQUGLXt7ao_eVWqhEXBUMe6U8edaHSCbbS1bXulHzgc6Cys3Mvf9rm7tjQk4nCl6zH5x_L0GcWFLaV-gQcQca4PVv2p9s8bP9jXLeojMuls_q5WFMlhWbjOVCxI5frkyRp5FYRRimGmNwIuIAK17wmpnOBPWg31wTuAQyIv1m09lAM5cLhF3LFzI4TIpgLDG6mx_kKjz8q6YElb7f',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBTtRX9PGRevp8GKF9nCE-UV8z1Tkj1c21GYZGl6QBU6eg39HNS01x779ls19eCLmTN7VFTHP4KRdzl8g-EkvSEuzLgb7_zyUlX4jrbQmlkPoLDWp11R_VXIsEgZOsyf-G9gDe3JXJ02CXYVIq_siC_2uItA6M81wUMveDwySY74XjW6bwc_4E1FvyyVFBtw6f7kkq8o94d0WwzjazE13X5Bm9Hljj6JKUw5SRMVriA5ppgKmxLph9qaoXqf14dEa_p2JCWQ7x6',
  ],
  'rating': 4.9,
  'total_review': 85,
  'available_rooms': 2,
  'status': 'active',
};
