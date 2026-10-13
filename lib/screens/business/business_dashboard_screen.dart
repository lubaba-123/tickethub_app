import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/listing_model.dart';
import '../../state/auth_state.dart';
import '../../state/booking_state.dart';
import '../../state/business_state.dart';
import '../../state/review_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dashboard_widgets.dart';

class BusinessDashboardScreen extends StatelessWidget {
  const BusinessDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final owner = context.watch<AuthState>().currentUser!;
    final businessState = context.watch<BusinessState>();
    final bookingState = context.watch<BookingState>();
    final reviewState = context.watch<ReviewState>();
    final business = businessState.businessForOwner(owner.id);

    if (business == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: Text('Register your business first.')),
      );
    }

    final money = NumberFormat('#,###');
    final bookings = bookingState.bookingsForBusiness(business.id);
    final active = bookings.where((b) => b.holdsInventory).toList();
    final cancelled = bookings.length - active.length;
    final ticketsSold = active.fold<int>(0, (a, b) => a + b.quantity);
    final revenue = active.fold<double>(0, (a, b) => a + b.totalAmount);

    final listings = businessState.listingsForBusiness(business.id);
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final activeListings = listings.where((l) => l.status == ListingStatus.active).length;
    final upcomingEvents = listings.where((l) => !l.date.isBefore(startOfToday)).length;

    var capacity = 0;
    var sold = 0;
    for (final listing in listings) {
      for (final type in businessState.ticketTypesForListing(listing.id)) {
        capacity += type.totalQty;
        sold += bookingState.bookedQty(type.id) + type.soldQty;
      }
    }
    final available = capacity - sold < 0 ? 0 : capacity - sold;

    final rows = <_SalesRow>[];
    for (final listing in listings) {
      final listingBookings = active.where((b) => b.listingId == listing.id);
      rows.add(_SalesRow(
        listing.title,
        listingBookings.fold<int>(0, (a, b) => a + b.quantity),
        listingBookings.fold<double>(0, (a, b) => a + b.totalAmount),
      ));
    }
    rows.sort((a, b) => b.revenue.compareTo(a.revenue));

    final rating = reviewState.summaryFor(business.id, 0, 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Business Dashboard')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(business.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              StatGrid(cards: [
                StatCard(label: 'Total bookings', value: '${bookings.length}', icon: Icons.receipt_long_outlined),
                StatCard(label: 'Tickets sold', value: '$ticketsSold', icon: Icons.confirmation_number_outlined, color: AppColors.success),
                StatCard(label: 'Total revenue', value: 'Rs. ${money.format(revenue)}', icon: Icons.payments_outlined, color: AppColors.accent),
                StatCard(label: 'Cancelled bookings', value: '$cancelled', icon: Icons.cancel_outlined, color: AppColors.danger),
                StatCard(label: 'Active listings', value: '$activeListings', icon: Icons.event_available_outlined),
                StatCard(label: 'Upcoming events', value: '$upcomingEvents', icon: Icons.upcoming_outlined, color: AppColors.pending),
                StatCard(label: 'Sold tickets (inventory)', value: '$sold', icon: Icons.sell_outlined, color: AppColors.success),
                StatCard(label: 'Available tickets', value: '$available', icon: Icons.inventory_2_outlined),
              ]),
              const SizedBox(height: 18),
              SectionCard(
                title: 'Sales by event',
                child: rows.isEmpty
                    ? const Text('Add listings and sell tickets to see sales here.', style: TextStyle(color: AppColors.textSecondary))
                    : Column(
                        children: [
                          Row(
                            children: const [
                              Expanded(flex: 5, child: Text('Event', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                              Expanded(flex: 2, child: Text('Tickets sold', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                              Expanded(flex: 3, child: Text('Revenue', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                            ],
                          ),
                          const Divider(height: 20),
                          for (final row in rows)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Expanded(flex: 5, child: Text(row.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                                  Expanded(flex: 2, child: Text('${row.tickets}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                                  Expanded(flex: 3, child: Text('Rs. ${money.format(row.revenue)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 18),
              SectionCard(
                title: 'Revenue chart',
                child: HorizontalBarChart(
                  color: AppColors.accent,
                  bars: [
                    for (final row in rows.take(6)) ChartBar(row.title, row.revenue, 'Rs. ${money.format(row.revenue)}'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionCard(
                title: 'Customer reviews',
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.pending, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      rating.count == 0 ? 'No reviews yet' : '${rating.rating.toStringAsFixed(1)} / 5  (${rating.count} review${rating.count == 1 ? '' : 's'})',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesRow {
  final String title;
  final int tickets;
  final double revenue;

  _SalesRow(this.title, this.tickets, this.revenue);
}
