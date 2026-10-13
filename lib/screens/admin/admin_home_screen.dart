import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'admin_bookings_tab.dart';
import 'admin_businesses_tab.dart';
import 'admin_dashboard_tab.dart';
import 'admin_reviews_tab.dart';
import 'admin_users_tab.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _index = 0;

  static const _titles = ['Admin Dashboard', 'Businesses', 'Users', 'Bookings', 'Reviews'];

  Widget _tab() {
    switch (_index) {
      case 0:
        return const AdminDashboardTab();
      case 1:
        return const AdminBusinessesTab();
      case 2:
        return const AdminUsersTab();
      case 3:
        return const AdminBookingsTab();
      default:
        return const AdminReviewsTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('ADMIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _tab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Businesses'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.reviews_outlined), selectedIcon: Icon(Icons.reviews), label: 'Reviews'),
        ],
      ),
    );
  }
}
