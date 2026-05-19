part of '../../main.dart';

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
