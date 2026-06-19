part of '../../main.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = SupabaseAuth.instance.currentUser!;

    return StreamBuilder<AppUserData?>(
      stream: SupabaseService.instance.userProfileStream(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(label: 'Menyiapkan tampilan akun...');
        }

        final profile = snapshot.data;
        if (profile?.isAdmin == true) {
          return AdminShell(profile: profile!);
        }

        final isOwner = profile?.canAccessOwnerShell == true;
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
                        dense: destinations.length > 5,
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
