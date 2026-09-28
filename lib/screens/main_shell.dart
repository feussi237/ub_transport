import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'home_search_screen.dart';
import 'my_bookings_screen.dart';
import 'notifications_screen.dart';
import 'account_screen.dart';
import 'admin_dashboard_screen.dart';
import 'agency_dashboard_screen.dart';

/// Picks the right landing screen for the signed-in user's role. Passenger
/// accounts get the bottom-nav [MainShell]; agency staff and admin accounts
/// (created via the API, not the passenger sign-up form) land straight on
/// their web dashboard instead.
Widget homeScreenForRole() {
  switch (AuthService.instance.currentUser?.role) {
    case 'admin':
      return const AdminDashboardScreen();
    case 'agency_staff':
      return const AgencyDashboardScreen();
    default:
      return const MainShell();
  }
}

/// Post-login/signup entry point. Wraps the four main sections of the app
/// (search, bookings, notifications, account) behind a bottom nav bar so
/// they stay one tap away instead of being buried in a menu.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    HomeSearchScreen(),
    MyBookingsScreen(),
    NotificationsScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: 72,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.search_rounded),
                selectedIcon: Icon(Icons.search_rounded),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.confirmation_number_outlined),
                selectedIcon: Icon(Icons.confirmation_num_rounded),
                label: 'Bookings',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_none_rounded),
                selectedIcon: Icon(Icons.notifications_rounded),
                label: 'Alerts',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
