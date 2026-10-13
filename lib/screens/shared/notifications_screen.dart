import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../state/auth_state.dart';
import '../../state/booking_state.dart';
import '../../state/notification_state.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = context.read<AuthState>().currentUser;
      if (user == null) return;
      final notifications = context.read<NotificationState>();
      final bookings = context.read<BookingState>();
      await notifications.generateReminders(user.id, bookings.upcomingFor(user.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().currentUser;
    final state = context.watch<NotificationState>();
    final List<AppNotification> items = user == null ? [] : state.forUser(user.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (user != null && items.isNotEmpty) ...[
            TextButton(
              onPressed: () => state.markAllRead(user.id),
              child: const Text('Mark all read'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear all',
              onPressed: () => state.clearAll(user.id),
            ),
          ],
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 46, color: AppColors.textSecondary),
                    SizedBox(height: 12),
                    Text(
                      'You are all caught up.\nNew booking and event updates will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final n = items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: n.read ? AppColors.surface : AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: n.read ? AppColors.border : AppColors.primary.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.notifications_active_outlined, size: 20, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                const SizedBox(height: 3),
                                Text(n.body, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35)),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat('d MMM, h:mm a').format(n.createdAt),
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
