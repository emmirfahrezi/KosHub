import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    final pages = [
      HomePage(
        onOpenChat: () => setState(() => _currentIndex = 1),
        onOpenBookings: () => setState(() => _currentIndex = 2),
      ),
      const ChatListPage(),
      const BookingHistoryPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
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
              children: [
                _NavItem(
                  label: 'Home',
                  icon: Icons.home_rounded,
                  selected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  label: 'Chat',
                  icon: Icons.chat_bubble_rounded,
                  selected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  label: 'Booking',
                  icon: Icons.bookmark_rounded,
                  selected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  label: 'Profil',
                  icon: Icons.person_rounded,
                  selected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
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
                    onSubmitted: (_) => widget.onOpenBookings(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data demo berhasil dimuat.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat data demo.')),
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
      bottomSheet: SafeArea(
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_firebaseMessage(error))),
                      );
                    } catch (_) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chat gagal dibuat. Coba lagi.'),
                        ),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => BookingFormPage(kos: kos),
                      ),
                    );
                  },
                  child: const Text('Booking Sekarang'),
                ),
              ),
            ],
          ),
        ),
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

                final messages = snapshot.data ?? const <ChatMessageData>[];
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_firebaseMessage(error))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesan gagal dikirim. Coba lagi.')),
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
  final _startDateController = TextEditingController(text: '20 Mei 2026');
  String _selectedDuration = '6 bulan';
  String _selectedPayment = 'Transfer Bank';
  bool _saving = false;

  @override
  void dispose() {
    _startDateController.dispose();
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
                    widget.kos.gallery.first,
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
            hintText: '20 Mei 2026',
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
    setState(() => _saving = true);
    try {
      await FirestoreService.instance.createBooking(
        kos: widget.kos,
        durationLabel: _selectedDuration,
        paymentMethod: _selectedPayment,
        startDateLabel: _startDateController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking berhasil dibuat.')));
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking gagal dibuat.')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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
              return Container(
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
                      label: 'Pembayaran',
                      value: booking.paymentMethod,
                    ),
                    const Divider(height: 24),
                    _SummaryRow(
                      label: 'Total',
                      value: booking.total,
                      bold: true,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class OwnerRegistrationPage extends StatefulWidget {
  const OwnerRegistrationPage({super.key});

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
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _ownerNameController.text = user?.displayName ?? '';
    _photoController.text = _sampleKosMap1['foto_urls'][0] as String;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pemilik Kos'),
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lengkapi data kos pertamamu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  'Setelah dikirim, akunmu akan berubah menjadi pemilik dan listing kos langsung tampil di halaman utama.',
                  style: TextStyle(color: Color(0xFF5D6B6B), height: 1.45),
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
              : const Text('Kirim Pendaftaran'),
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
        facilities: facilities,
        photoUrl: photoUrl,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pendaftaran pemilik berhasil. Listing kos kamu sudah aktif.',
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
              const SizedBox(height: 18),
              const _ProfileMenuTile(
                icon: Icons.person_outline_rounded,
                title: 'Data Diri',
                subtitle: 'Profil diambil dari Firebase Auth dan Firestore',
              ),
              const _ProfileMenuTile(
                icon: Icons.receipt_long_rounded,
                title: 'Riwayat Transaksi',
                subtitle: 'Pantau status pembayaran dan booking',
              ),
              const _ProfileMenuTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Chat Aktif',
                subtitle: 'Semua percakapan realtime tersimpan di Firestore',
              ),
              const SizedBox(height: 12),
              if (isOwner)
                const _ProfileMenuTile(
                  icon: Icons.storefront_rounded,
                  title: 'Akun Pemilik Aktif',
                  subtitle:
                      'Kamu sudah terdaftar sebagai pemilik kos dan bisa mulai menambahkan listing.',
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
      'created_at':
          existingData == null
              ? FieldValue.serverTimestamp()
              : existingData['created_at'],
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
      'foto_urls': [photoUrl],
      'rating': 0,
      'total_review': 0,
      'available_rooms': availableRooms,
      'status': 'active',
      'created_at': FieldValue.serverTimestamp(),
    });

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
    final ownerRina = _users.doc('demo-owner-rina');
    final ownerDimas = _users.doc('demo-owner-dimas');

    await Future.wait([
      ownerRina.set({
        'name': 'Bu Rina',
        'email': 'rina-owner@koshub.id',
        'role': 'pemilik',
        'is_active': true,
        'photo_url':
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80',
      }, SetOptions(merge: true)),
      ownerDimas.set({
        'name': 'Pak Dimas',
        'email': 'dimas-owner@koshub.id',
        'role': 'pemilik',
        'is_active': true,
        'photo_url':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
      }, SetOptions(merge: true)),
      _kos.doc('kos-1').set(_sampleKosMap1),
      _kos.doc('kos-2').set(_sampleKosMap2),
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
              return ChatPreviewData.fromMap(
                id: doc.id,
                data: data,
                kos: kos,
              );
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
          return BookingData.fromMap(data, kos);
        }),
      );
      final resolved = items.whereType<BookingData>().toList();
      resolved.sort((a, b) => b.sortKey.compareTo(a.sortKey));
      return resolved;
    });
  }

  Future<void> createBooking({
    required KosData kos,
    required String durationLabel,
    required String paymentMethod,
    required String startDateLabel,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    await _bookings.add({
      'user_id': user.uid,
      'owner_id': kos.ownerId,
      'kos_id': kos.id,
      'kos_snapshot': kos.toMap(),
      'room_label': 'Kamar Demo',
      'start_date_label': startDateLabel,
      'duration_label': durationLabel,
      'payment_method': paymentMethod,
      'status': 'Menunggu Pembayaran',
      'total_price': _totalPrice(kos.price, durationLabel),
      'created_at': FieldValue.serverTimestamp(),
    });
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
    required this.availableRooms,
    required this.description,
    required this.facilities,
    required this.gallery,
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
  final int availableRooms;
  final String description;
  final List<String> facilities;
  final List<String> gallery;
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
      availableRooms: (map['available_rooms'] as num?)?.toInt() ?? 0,
      description: map['deskripsi'] as String? ?? '-',
      facilities: (map['fasilitas'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      gallery: (map['foto_urls'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
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
      'foto_urls': gallery,
      'rating': rating,
      'total_review': reviewCount,
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
  });

  final String id;
  final String name;
  final String email;
  final String role;

  factory AppUserData.fromMap(String id, Map<String, dynamic> map) {
    return AppUserData(
      id: id,
      name: map['name'] as String? ?? '-',
      email: map['email'] as String? ?? '-',
      role: map['role'] as String? ?? 'penyewa',
    );
  }
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
    required this.kos,
    required this.roomLabel,
    required this.startDate,
    required this.durationLabel,
    required this.paymentMethod,
    required this.status,
    required this.total,
    required this.sortKey,
  });

  final KosData kos;
  final String roomLabel;
  final String startDate;
  final String durationLabel;
  final String paymentMethod;
  final String status;
  final String total;
  final DateTime sortKey;

  factory BookingData.fromMap(Map<String, dynamic> map, KosData kos) {
    final timestamp =
        (map['created_at'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return BookingData(
      kos: kos,
      roomLabel: map['room_label'] as String? ?? '-',
      startDate: map['start_date_label'] as String? ?? '-',
      durationLabel: map['duration_label'] as String? ?? '-',
      paymentMethod: map['payment_method'] as String? ?? '-',
      status: map['status'] as String? ?? '-',
      total: _currency((map['total_price'] as num?)?.toInt() ?? 0),
      sortKey: timestamp,
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
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;

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
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ListTile(
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
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
      return 'Akses Firestore ditolak. Deploy/update rules Firestore dulu.';
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

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour.$minute';
}

int _totalPrice(int monthlyPrice, String durationLabel) {
  final months = int.tryParse(durationLabel.split(' ').first) ?? 1;
  return monthlyPrice * months;
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
