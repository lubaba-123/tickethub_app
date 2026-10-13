import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../state/booking_state.dart';
import '../../theme/app_theme.dart';
import 'ticket_detail_screen.dart';
import 'my_tickets_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final String bookingId;

  const BookingConfirmationScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingState>().byId(bookingId);

    if (booking == null) {
      return const Scaffold(body: Center(child: Text('Booking not found.')));
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: AppColors.success, size: 54),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Booking Confirmed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  booking.paymentMethod.isOnline
                      ? 'Your payment was received and your tickets are ready.'
                      : 'Your tickets are reserved. Please pay at the venue.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 26),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Booking ID', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        booking.bookingCode,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.primary),
                      ),
                      const Divider(height: 28),
                      Text(booking.listingTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(booking.businessName, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      _line(Icons.calendar_today_outlined, DateFormat('EEE, d MMM yyyy').format(booking.eventDate)),
                      const SizedBox(height: 6),
                      _line(Icons.access_time_rounded, '${booking.startTime} - ${booking.endTime}'),
                      const SizedBox(height: 6),
                      _line(Icons.location_on_outlined, booking.location),
                      const SizedBox(height: 6),
                      _line(
                        Icons.confirmation_number_outlined,
                        booking.seatIds.isEmpty
                            ? booking.ticketTypeSummary
                            : '${booking.ticketTypeSummary}  (${booking.seatIds.join(', ')})',
                      ),
                      const Divider(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            'Rs. ${NumberFormat('#,###').format(booking.totalAmount)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TicketDetailScreen(bookingId: booking.id)),
                  ),
                  child: const Text('View Digital Ticket'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
                  ),
                  child: const Text('My Tickets'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}