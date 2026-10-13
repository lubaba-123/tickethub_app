import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/booking_model.dart';
import '../../state/auth_state.dart';
import '../../state/booking_state.dart';
import '../../state/business_state.dart';
import '../../state/notification_state.dart';
import '../../state/review_state.dart';
import '../../state/seat_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/booking_status_chip.dart';

class TicketDetailScreen extends StatelessWidget {
  final String bookingId;

  const TicketDetailScreen({super.key, required this.bookingId});

  Future<void> _cancel(BuildContext context, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text(
          booking.status == BookingStatus.paid
              ? 'Your payment will be marked as refunded and the tickets will be released.'
              : 'The tickets will be released and this booking will be cancelled.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep booking')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel booking', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final bookings = context.read<BookingState>();
    final seats = context.read<SeatState>();
    final notifications = context.read<NotificationState>();
    String? ownerId;
    for (final b in context.read<BusinessState>().businesses) {
      if (b.id == booking.businessId) ownerId = b.ownerId;
    }
    final result = await bookings.cancelBooking(booking.id);
    if (result != null && booking.seatIds.isNotEmpty) {
      await seats.releaseBooked(booking.listingId, booking.seatIds.toSet());
    }
    if (result != null) {
      await notifications.notify(
        booking.customerId,
        'Booking ${result.status.label.toLowerCase()}',
        '${booking.listingTitle} (${booking.bookingCode}) was ${result.status.label.toLowerCase()}.',
      );
      if (ownerId != null) {
        await notifications.notify(
          ownerId,
          'Booking cancelled',
          '${booking.customerName} cancelled ${booking.quantity} ticket(s) for ${booking.listingTitle}.',
        );
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result == null ? 'This booking cannot be cancelled.' : 'Booking cancelled.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingState>().byId(bookingId);

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Digital Ticket')),
        body: const Center(child: Text('Ticket not found.')),
      );
    }

    final status = booking.effectiveStatus;
    final qrActive = status == BookingStatus.paid || status == BookingStatus.confirmed || status == BookingStatus.pending;

    return Scaffold(
      appBar: AppBar(title: const Text('Digital Ticket')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    booking.businessName,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                                  ),
                                ),
                                BookingStatusChip(status: status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              booking.listingTitle,
                              style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _row('Date', DateFormat('EEE, d MMM yyyy').format(booking.eventDate)),
                            _row('Time', '${booking.startTime} - ${booking.endTime}'),
                            _row('Location', booking.location),
                            _row('Ticket type', booking.ticketTypeSummary),
                            if (booking.seatIds.isNotEmpty) _row('Seats', booking.seatIds.join(', ')),
                            _row('Quantity', '${booking.quantity}'),
                            _row('Customer', booking.customerName),
                            _row('Payment', booking.paymentMethod.label),
                            _row('Total amount', 'Rs. ${NumberFormat('#,###').format(booking.totalAmount)}', bold: true),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 24,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final dashes = (constraints.maxWidth / 10).floor();
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(
                                    dashes,
                                    (_) => const SizedBox(
                                      width: 5,
                                      height: 1.5,
                                      child: DecoratedBox(decoration: BoxDecoration(color: AppColors.border)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                            height: 24,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Opacity(
                              opacity: qrActive ? 1 : 0.25,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: QrImageView(
                                  data: booking.qrData,
                                  version: QrVersions.auto,
                                  size: 190,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () async {
                                await Clipboard.setData(ClipboardData(text: booking.bookingCode));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Booking ID copied.')),
                                  );
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    booking.bookingCode,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.2),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.copy_rounded, size: 16, color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              qrActive
                                  ? 'Show this QR code at the entrance'
                                  : 'This ticket is no longer valid for entry',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (status == BookingStatus.used || status == BookingStatus.completed) ...[
                  const SizedBox(height: 20),
                  _ReviewSection(booking: booking),
                ],
                if (booking.canCancel) ...[
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () => _cancel(context, booking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger, width: 1.4),
                    ),
                    child: const Text('Cancel Booking'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewInput {
  final int rating;
  final String comment;

  const _ReviewInput(this.rating, this.comment);
}

class _ReviewSection extends StatelessWidget {
  final Booking booking;

  const _ReviewSection({required this.booking});

  Future<void> _openDialog(BuildContext context) async {
    final input = await showDialog<_ReviewInput>(
      context: context,
      builder: (_) => const _ReviewDialog(),
    );
    if (input == null || !context.mounted) return;

    final reviews = context.read<ReviewState>();
    final ok = await reviews.addReview(
      businessId: booking.businessId,
      listingId: booking.listingId,
      bookingId: booking.id,
      customerId: booking.customerId,
      customerName: booking.customerName,
      rating: input.rating,
      comment: input.comment,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Thanks for your review!' : (reviews.error ?? 'Could not save review.'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().currentUser;
    if (user == null || user.id != booking.customerId) return const SizedBox.shrink();

    final review = context.watch<ReviewState>().forBooking(booking.id);

    if (review == null) {
      return OutlinedButton.icon(
        onPressed: () => _openDialog(context),
        icon: const Icon(Icons.star_outline_rounded),
        label: const Text('Rate your experience'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your review', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 20,
                  color: AppColors.pending,
                ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment, style: const TextStyle(fontSize: 13.5, height: 1.35)),
          ],
        ],
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 0;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate your experience'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () => setState(() => _rating = i),
                    icon: Icon(
                      i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 34,
                      color: AppColors.pending,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(hintText: 'Share a few words about the event (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: _rating == 0 ? null : () => Navigator.of(context).pop(_ReviewInput(_rating, _controller.text)),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}