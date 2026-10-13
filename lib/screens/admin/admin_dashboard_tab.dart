import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/mock_data.dart';
import '../../models/booking_model.dart';
import '../../models/business_model.dart';
import '../../models/user_model.dart';
import '../../state/auth_state.dart';
import '../../state/booking_state.dart';
import '../../state/business_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/dashboard_widgets.dart';
import '../customer/ticket_detail_screen.dart';

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  String _categoryFor(String listingId) {
    for (final l in mockListings) {
      if (l.id == listingId) return l.category;
    }
    return 'Other';
  }

  @override
  Widget build(BuildContext context) {
    final users = context.watch<AuthState>().users.where((u) => u.role != UserRole.admin).toList();
    final businessState = context.watch<BusinessState>();
    final bookingState = context.watch<BookingState>();
    final money = NumberFormat('#,###');

    final businesses = businessState.businesses;
    final activeBusinesses = businesses.where((b) => b.status == BusinessStatus.approved).length;
    final pendingBusinesses = businesses.where((b) => b.status == BusinessStatus.pending).length;

    final allBookings = bookingState.bookings;
    final live = allBookings.where((b) => b.holdsInventory).toList();
    final ticketsSold = live.fold<int>(0, (a, b) => a + b.quantity);
    final revenue = live.fold<double>(0, (a, b) => a + b.totalAmount);

    final byEvent = <String, int>{};
    final byCategory = <String, double>{};
    for (final booking in live) {
      byEvent[booking.listingTitle] = (byEvent[booking.listingTitle] ?? 0) + booking.quantity;
      final category = _categoryFor(booking.listingId);
      byCategory[category] = (byCategory[category] ?? 0) + booking.totalAmount;
    }
    final popular = byEvent.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final categories = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final byStatus = <BookingStatus, int>{};
    for (final booking in allBookings) {
      byStatus[booking.effectiveStatus] = (byStatus[booking.effectiveStatus] ?? 0) + 1;
    }

    final recent = [...allBookings]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            StatGrid(cards: [
              StatCard(label: 'Total users', value: '${users.length}', icon: Icons.people_outline),
              StatCard(label: 'Total businesses', value: '${businesses.length}', icon: Icons.storefront_outlined, color: AppColors.accent),
              StatCard(label: 'Total events', value: '${businessState.listings.length}', icon: Icons.event_outlined, color: AppColors.pending),
              StatCard(label: 'Total tickets sold', value: '$ticketsSold', icon: Icons.confirmation_number_outlined, color: AppColors.success),
              StatCard(label: 'Total bookings', value: '${allBookings.length}', icon: Icons.receipt_long_outlined),
              StatCard(label: 'Total revenue', value: 'Rs. ${money.format(revenue)}', icon: Icons.payments_outlined, color: AppColors.accent),
              StatCard(label: 'Active businesses', value: '$activeBusinesses', icon: Icons.verified_outlined, color: AppColors.success),
              StatCard(label: 'Pending businesses', value: '$pendingBusinesses', icon: Icons.hourglass_top_rounded, color: AppColors.pending),
            ]),
            const SizedBox(height: 18),
            SectionCard(
              title: 'Popular events (tickets sold)',
              child: HorizontalBarChart(
                bars: [for (final e in popular.take(6)) ChartBar(e.key, e.value.toDouble(), '${e.value}')],
              ),
            ),
            const SizedBox(height: 18),
            SectionCard(
              title: 'Revenue by category',
              child: HorizontalBarChart(
                color: AppColors.accent,
                bars: [for (final e in categories.take(6)) ChartBar(e.key, e.value, 'Rs. ${money.format(e.value)}')],
              ),
            ),
            const SizedBox(height: 18),
            SectionCard(
              title: 'Bookings by status',
              child: byStatus.isEmpty
                  ? const Text('No bookings yet.', style: TextStyle(color: AppColors.textSecondary))
                  : ColumnBarChart(
                      bars: [
                        for (final status in BookingStatus.values)
                          if (byStatus[status] != null)
                            ChartBar(status.label, byStatus[status]!.toDouble(), '${byStatus[status]}'),
                      ],
                    ),
            ),
            const SizedBox(height: 22),
            const Text('Recent bookings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              const Text('No bookings yet.', style: TextStyle(color: AppColors.textSecondary))
            else
              for (final booking in recent.take(5))
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
