import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../state/auth_state.dart';
import '../../state/booking_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/booking_card.dart';
import 'ticket_detail_screen.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthState>().currentUser?.id ?? '';
    final bookings = context.watch<BookingState>();
    final upcoming = bookings.upcomingFor(userId);
    final history = bookings.historyFor(userId);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Tickets'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Upcoming (${upcoming.length})'),
              Tab(text: 'History (${history.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _list(
              context,
              upcoming,
              'No upcoming bookings yet.\nBrowse events and book your first ticket!',
            ),
            _list(
              context,
              history,
              'Your past, used and cancelled bookings will appear here.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<Booking> items, String emptyText) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.confirmation_number_outlined, size: 44, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                emptyText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final booking in items)
              BookingCard(
                booking: booking,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TicketDetailScreen(bookingId: booking.id)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
