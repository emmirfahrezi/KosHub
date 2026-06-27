import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:url_launcher/url_launcher.dart';

part 'src/auth/auth_pages.dart';
part 'src/shell/main_shell.dart';
part 'src/admin/admin_shell.dart';
part 'src/admin/admin_pages.dart';
part 'src/tenant/home_page.dart';
part 'src/tenant/kos_detail_page.dart';
part 'src/tenant/chat_pages.dart';
part 'src/tenant/notifications_page.dart';
part 'src/tenant/booking_pages.dart';
part 'src/owner/owner_dashboard_page.dart';
part 'src/owner/owner_booking_page.dart';
part 'src/owner/owner_residents_page.dart';
part 'src/owner/owner_rooms_page.dart';
part 'src/owner/owner_transactions_page.dart';
part 'src/owner/owner_booking_detail_page.dart';
part 'src/owner/resident_detail_page.dart';
part 'src/owner/room_transaction_detail_pages.dart';
part 'src/owner/owner_notifications_settings.dart';
part 'src/owner/owner_reviews_page.dart';
part 'src/owner/owner_registration_page.dart';
part 'src/profile/profile_pages.dart';
part 'src/admin/admin_detail_pages.dart';
part 'src/data/supabase_auth.dart';
part 'src/data/supabase_service.dart';
part 'src/data/models.dart';
part 'src/shared/widgets.dart';
part 'src/shared/helpers.dart';
part 'src/data/sample_data.dart';

const List<String> _adminSeedEmails = [
  'emmir.fahrezi1@gmail.com',
  'faizkhairan6@gmail.com',
];
const String _supabaseUrl = 'https://qqcjuxabcikoiuwhuliv.supabase.co';
const String _supabaseAnonKey =
    'sb_publishable_CT6DVNOjIFXAns4Cmx3y9w_XaM9xQcK';

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
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = supabase.Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _LoadingScreen(
              label: 'Supabase gagal dimuat. Coba periksa koneksi atau config.',
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
      stream: SupabaseAuth.instance.authStateChanges(),
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
