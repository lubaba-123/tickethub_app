import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/mock_data.dart';
import '../../models/booking_model.dart';
import '../../models/listing_model.dart';
import '../../models/ticket_type_model.dart';
import '../../state/auth_state.dart';
import '../../state/booking_state.dart';
import '../../state/notification_state.dart';
import '../../state/business_state.dart';
import '../../state/seat_state.dart';
import '../../theme/app_theme.dart';
import 'booking_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Listing listing;
  final List<TicketType> ticketTypes;
  final List<BookingItem> items;
  final List<String> seatIds;

  const CheckoutScreen({
    super.key,
    required this.listing,
    required this.ticketTypes,
    required this.items,
    this.seatIds = const [],
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  PaymentMethod _method = PaymentMethod.cash;
  bool _submitting = false;

  double get _total => widget.items.fold<double>(0, (sum, i) => sum + i.subtotal);

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthState>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _businessName() {
    for (final b in mockBusinesses) {
      if (b.id == widget.listing.businessId) return b.name;
    }
    for (final b in context.read<BusinessState>().businesses) {
      if (b.id == widget.listing.businessId) return b.name;
    }
    return 'Business';
  }

  String? _ownerId() {
    for (final b in context.read<BusinessState>().businesses) {
      if (b.id == widget.listing.businessId) return b.ownerId;
    }
    return null;
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthState>().currentUser;
    if (user == null) return;
    final bookings = context.read<BookingState>();
    final seats = context.read<SeatState>();
    final notifications = context.read<NotificationState>();
    final ownerId = _ownerId();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final businessName = _businessName();

    if (widget.seatIds.isNotEmpty) {
      final held = seats.heldByUser(widget.listing.id, user.id);
      if (!widget.seatIds.every(held.contains)) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Your seat reservation expired. Please select seats again.')),
        );
        navigator.pop();
        return;
      }
    }

    setState(() => _submitting = true);

    if (_method.isOnline) {
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    final booking = await bookings.createBooking(
      customerId: user.id,
      customerName: _nameController.text,
      customerEmail: _emailController.text,
      customerPhone: _phoneController.text,
      businessName: businessName,
      listing: widget.listing,
      ticketTypes: widget.ticketTypes,
      items: widget.items,
      seatIds: widget.seatIds,
      paymentMethod: _method,
    );

    if (booking == null) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text(bookings.error ?? 'Could not complete your booking.')),
      );
      return;
    }

    if (widget.seatIds.isNotEmpty) {
      await seats.confirmBooking(widget.listing.id, widget.seatIds.toSet(), user.id);
    }

    await notifications.notify(
      user.id,
      'Booking confirmed',
      '${booking.listingTitle} • ${booking.bookingCode} • Rs. ${NumberFormat('#,###').format(booking.totalAmount)}',
    );
    if (ownerId != null) {
      await notifications.notify(
        ownerId,
        'New booking',
        '${booking.customerName} booked ${booking.quantity} ticket(s) for ${booking.listingTitle}.',
      );
    }

    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => BookingConfirmationScreen(bookingId: booking.id)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthState>().currentUser;
    final expiry = widget.seatIds.isEmpty || user == null
        ? null
        : context.read<SeatState>().holdExpiry(widget.listing.id, user.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  _sectionTitle('Booking summary'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.listing.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('EEE, d MMM yyyy').format(widget.listing.date)}  •  ${widget.listing.startTime}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.listing.location,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                        const Divider(height: 26),
                        for (final item in widget.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.typeName}  x ${item.quantity}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ),
                                Text(
                                  'Rs. ${NumberFormat('#,###').format(item.subtotal)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        if (widget.seatIds.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: widget.seatIds
                                .map(
                                  (id) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      id,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (expiry != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 15, color: AppColors.pending),
                              const SizedBox(width: 6),
                              Text(
                                'Seats reserved until ${DateFormat('h:mm a').format(expiry)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.pending, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('Your details'),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      final ok = RegExp(r'^[\w.\-+]+@[\w\-]+\.[\w\-.]+$').hasMatch(v.trim());
                      return ok ? null : 'Enter a valid email';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('Payment method'),
                  _paymentTile(PaymentMethod.cash, Icons.payments_outlined, 'Pay when you arrive at the venue'),
                  _paymentTile(PaymentMethod.jazzCash, Icons.account_balance_wallet_outlined, 'Mobile wallet (demo payment)'),
                  _paymentTile(PaymentMethod.easyPaisa, Icons.phone_android_rounded, 'Mobile wallet (demo payment)'),
                  _paymentTile(PaymentMethod.card, Icons.credit_card_rounded, 'Card payment (demo payment)'),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        Text(
                          'Rs. ${NumberFormat('#,###').format(_total)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _submitting ? null : _confirm,
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                          )
                        : Text(_method.isOnline ? 'Pay & Confirm Booking' : 'Confirm Booking'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
    );
  }

  Widget _paymentTile(PaymentMethod method, IconData icon, String subtitle) {
    final selected = _method == method;
    return GestureDetector(
      onTap: _submitting ? null : () => setState(() => _method = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}