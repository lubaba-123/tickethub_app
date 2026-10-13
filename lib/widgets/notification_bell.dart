import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/shared/notifications_screen.dart';
import '../state/auth_state.dart';
import '../state/notification_state.dart';
import '../theme/app_theme.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthState>().currentUser?.id ?? '';
    final unread = context.watch<NotificationState>().unreadCount(userId);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
          ),
          if (unread > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
