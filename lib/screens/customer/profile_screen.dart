import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../state/booking_state.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'my_tickets_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.currentUser;
    final bookings = context.watch<BookingState>();

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in.')));
    }

    final total = bookings.bookingsForUser(user.id).length;
    final upcoming = bookings.upcomingFor(user.id).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(user.email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    _stat('Total bookings', '$total'),
                    const SizedBox(width: 12),
                    _stat('Upcoming', '$upcoming'),
                  ],
                ),
                const SizedBox(height: 22),
                _infoTile(Icons.phone_outlined, 'Phone', user.phone),
                _infoTile(Icons.badge_outlined, 'Account type', 'Customer'),
                const SizedBox(height: 10),
                _actionTile(
                  context,
                  Icons.confirmation_number_outlined,
                  'My Tickets',
                  () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
                  ),
                ),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger, width: 1.4),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        ],
      ),
    );
  }

  Widget _actionTile(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
