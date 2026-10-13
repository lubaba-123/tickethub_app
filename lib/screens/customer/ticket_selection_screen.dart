import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../models/listing_model.dart';
import '../../models/ticket_type_model.dart';
import '../../state/booking_state.dart';
import '../../theme/app_theme.dart';
import 'checkout_screen.dart';

class TicketSelectionScreen extends StatefulWidget {
  final Listing listing;
  final List<TicketType> ticketTypes;

  const TicketSelectionScreen({
    super.key,
    required this.listing,
    required this.ticketTypes,
  });

  @override
  State<TicketSelectionScreen> createState() => _TicketSelectionScreenState();
}

class _TicketSelectionScreenState extends State<TicketSelectionScreen> {
  static const int _maxTickets = 10;
  final Map<String, int> _quantities = {};

  late final List<TicketType> _sortedTypes;

  @override
  void initState() {
    super.initState();
    _sortedTypes = [...widget.ticketTypes]..sort((a, b) => a.price.compareTo(b.price));
  }

  int get _totalTickets => _quantities.values.fold<int>(0, (a, b) => a + b);

  double get _totalPrice {
    var sum = 0.0;
    for (final type in _sortedTypes) {
      sum += type.price * (_quantities[type.id] ?? 0);
    }
    return sum;
  }

  void _change(TicketType type, int delta, int available) {
    final current = _quantities[type.id] ?? 0;
    final next = current + delta;
    if (next < 0 || next > available) return;
    if (delta > 0 && _totalTickets >= _maxTickets) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can book up to $_maxTickets tickets at a time.')),
      );
      return;
    }
    setState(() => _quantities[type.id] = next);
  }

  void _continue() {
    final items = <BookingItem>[
      for (final type in _sortedTypes)
        if ((_quantities[type.id] ?? 0) > 0)
          BookingItem(
            typeId: type.id,
            typeName: type.name,
            unitPrice: type.price,
            quantity: _quantities[type.id]!,
          ),
    ];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          listing: widget.listing,
          ticketTypes: widget.ticketTypes,
          items: items,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingState>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.listing.title)),
      body: widget.ticketTypes.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No ticket types have been added for this listing yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('EEE, d MMM').format(widget.listing.date),
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 14),
                              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                widget.listing.startTime,
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  widget.listing.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Text('Select tickets', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                          const SizedBox(height: 12),
                          for (final type in _sortedTypes) _typeCard(type, bookings.availableFor(type)),
                        ],
                      ),
                    ),
                  ),
                ),
                _bottomBar(),
              ],
            ),
    );
  }

  Widget _typeCard(TicketType type, int available) {
    final qty = _quantities[type.id] ?? 0;
    final soldOut = available == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: qty > 0 ? AppColors.primary : AppColors.border, width: qty > 0 ? 1.6 : 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${NumberFormat('#,###').format(type.price)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  soldOut ? 'Sold out' : '$available left',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: soldOut ? AppColors.danger : (available <= 10 ? AppColors.pending : AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          if (soldOut)
            const SizedBox.shrink()
          else
            Row(
              children: [
                _stepButton(Icons.remove_rounded, qty > 0 ? () => _change(type, -1, available) : null),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$qty',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                _stepButton(Icons.add_rounded, qty < available ? () => _change(type, 1, available) : null),
              ],
            ),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.border : AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _totalTickets == 0 ? 'No tickets selected' : '$_totalTickets ticket(s)',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rs. ${NumberFormat('#,###').format(_totalPrice)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: ElevatedButton(
                    onPressed: _totalTickets == 0 ? null : _continue,
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
