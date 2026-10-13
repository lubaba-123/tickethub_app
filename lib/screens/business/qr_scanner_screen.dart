import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../state/auth_state.dart';
import '../../state/booking_state.dart';
import '../../state/business_state.dart';
import '../../state/notification_state.dart';
import '../../theme/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = TextEditingController();
  TicketCheck? _result;
  final List<String> _recent = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Set<String> _businessIds() {
    final owner = context.read<AuthState>().currentUser;
    if (owner == null) return {};
    final business = context.read<BusinessState>().businessForOwner(owner.id);
    return business == null ? {} : {business.id};
  }

  void _validate() {
    final result = context.read<BookingState>().validateTicket(_controller.text, _businessIds());
    setState(() => _result = result);
  }

  Future<void> _allowEntry(Booking booking) async {
    final bookings = context.read<BookingState>();
    final notifications = context.read<NotificationState>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await bookings.markUsed(booking.id);
    if (!mounted) return;
    if (ok) {
      await notifications.notify(
        booking.customerId,
        'Ticket scanned',
        'Your ticket ${booking.bookingCode} for ${booking.listingTitle} was verified. Enjoy the event!',
      );
      _recent.insert(0, '${booking.bookingCode}  •  ${booking.customerName}');
      if (_recent.length > 8) _recent.removeLast();
      _controller.clear();
      setState(() => _result = null);
      messenger.showSnackBar(const SnackBar(content: Text('Entry allowed. Ticket marked as Used.')));
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('Could not mark this ticket as used.')));
    }
  }

  Color _color(TicketCheckStatus status) {
    switch (status) {
      case TicketCheckStatus.valid:
        return AppColors.success;
      case TicketCheckStatus.alreadyUsed:
        return AppColors.pending;
      case TicketCheckStatus.cancelled:
      case TicketCheckStatus.invalid:
        return AppColors.danger;
    }
  }

  IconData _icon(TicketCheckStatus status) {
    switch (status) {
      case TicketCheckStatus.valid:
        return Icons.verified_rounded;
      case TicketCheckStatus.alreadyUsed:
        return Icons.history_toggle_off_rounded;
      case TicketCheckStatus.cancelled:
        return Icons.cancel_rounded;
      case TicketCheckStatus.invalid:
        return Icons.error_rounded;
    }
  }

  String _title(TicketCheckStatus status) {
    switch (status) {
      case TicketCheckStatus.valid:
        return 'Valid Ticket';
      case TicketCheckStatus.alreadyUsed:
        return 'Already Used';
      case TicketCheckStatus.cancelled:
        return 'Cancelled Ticket';
      case TicketCheckStatus.invalid:
        return 'Invalid Ticket';
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('Ticket Validation')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
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
                    Row(
                      children: const [
                        Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                        SizedBox(width: 10),
                        Text('Verify a ticket', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enter the booking ID printed under the customer\'s QR code (for example TH-261009-4F7A2C), or the scanned QR text.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (_) => _validate(),
                      decoration: const InputDecoration(hintText: 'TH-XXXXXX-XXXXXX'),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(onPressed: _validate, child: const Text('Validate Ticket')),
                  ],
                ),
              ),
              if (result != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _color(result.status).withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _color(result.status), width: 1.4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_icon(result.status), color: _color(result.status), size: 34),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _title(result.status),
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _color(result.status)),
                                ),
                                const SizedBox(height: 2),
                                Text(result.message, style: const TextStyle(fontSize: 12.5, height: 1.35)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (result.booking != null && result.message != 'This ticket belongs to a different business.') ...[
                        const Divider(height: 28),
                        _info('Event', result.booking!.listingTitle),
                        _info('Date', DateFormat('EEE, d MMM yyyy').format(result.booking!.eventDate)),
                        _info('Time', '${result.booking!.startTime} - ${result.booking!.endTime}'),
                        _info('Customer', result.booking!.customerName),
                        _info('Tickets', result.booking!.ticketTypeSummary),
                        if (result.booking!.seatIds.isNotEmpty) _info('Seats', result.booking!.seatIds.join(', ')),
                        _info('Booking ID', result.booking!.bookingCode),
                      ],
                      if (result.status == TicketCheckStatus.valid && result.booking != null) ...[
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => _allowEntry(result.booking!),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('Allow Entry & Mark as Used'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (_recent.isNotEmpty) ...[
                const SizedBox(height: 22),
                const Text('Checked in this session', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 10),
                for (final entry in _recent)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(entry, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}