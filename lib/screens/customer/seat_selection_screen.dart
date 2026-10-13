import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../models/listing_model.dart';
import '../../models/seat_model.dart';
import '../../models/ticket_type_model.dart';
import '../../state/auth_state.dart';
import '../../state/seat_state.dart';
import '../../theme/app_theme.dart';
import 'checkout_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Listing listing;
  final List<TicketType> ticketTypes;

  const SeatSelectionScreen({
    super.key,
    required this.listing,
    required this.ticketTypes,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  static const int _maxSeats = 8;
  static const List<Color> _categoryColors = [
    Color(0xFF2E7D9A),
    Color(0xFF7B5EA7),
    Color(0xFFC9972B),
    Color(0xFF3F8F5B),
    Color(0xFFB0525F),
  ];
  static const Color _bookedColor = Color(0xFFD1D5DB);
  static const Color _heldColor = Color(0xFFF59E0B);

  late final List<SeatGroup> _groups;
  late final Map<String, Seat> _seatById;
  late final Map<String, int> _seatOrder;
  late final Map<String, TicketType> _typeById;
  late final Map<String, Color> _colorByType;
  final Set<String> _selected = {};
  bool _loading = true;
  String _userId = 'guest';

  @override
  void initState() {
    super.initState();
    _groups = buildSeatLayout(widget.ticketTypes);
    _seatById = {
      for (final g in _groups)
        for (final r in g.rows)
          for (final s in r) s.id: s,
    };
    var order = 0;
    _seatOrder = {
      for (final g in _groups)
        for (final r in g.rows)
          for (final s in r) s.id: order++,
    };
    _typeById = {for (final t in widget.ticketTypes) t.id: t};
    _colorByType = {
      for (var i = 0; i < _groups.length; i++)
        _groups[i].type.id: _categoryColors[i % _categoryColors.length],
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final seats = context.read<SeatState>();
    _userId = context.read<AuthState>().currentUser?.id ?? 'guest';
    await seats.ensureSeeded(widget.listing.id, widget.ticketTypes);
    if (!mounted) return;
    setState(() {
      _selected.addAll(
        seats.heldByUser(widget.listing.id, _userId).where(_seatById.containsKey),
      );
      _loading = false;
    });
  }

  List<String> _orderedSelection() {
    final list = _selected.toList();
    list.sort((a, b) => _seatOrder[a]!.compareTo(_seatOrder[b]!));
    return list;
  }

  double _total() {
    return _selected.fold<double>(
      0,
      (sum, id) => sum + _typeById[_seatById[id]!.ticketTypeId]!.price,
    );
  }

  void _toggle(Seat seat) {
    final seats = context.read<SeatState>();
    final id = seat.id;
    if (seats.bookedSeats(widget.listing.id).contains(id)) return;
    if (seats.isHeldByOther(widget.listing.id, id, _userId)) return;

    if (!_selected.contains(id) && _selected.length >= _maxSeats) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can select up to $_maxSeats seats per booking.')),
      );
      return;
    }

    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _onHoldExpired() {
    if (!mounted) return;
    context.read<SeatState>().refresh(widget.listing.id);
    setState(() => _selected.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your seat reservation expired. Please select seats again.')),
    );
  }

  Future<void> _continue() async {
    final seats = context.read<SeatState>();
    final ok = seats.holdSeats(widget.listing.id, Set<String>.from(_selected), _userId);

    if (!ok) {
      final booked = seats.bookedSeats(widget.listing.id);
      setState(() {
        _selected.removeWhere(
          (id) => booked.contains(id) || seats.isHeldByOther(widget.listing.id, id, _userId),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Some seats are no longer available. Please choose again.')),
      );
      return;
    }

    final ordered = _orderedSelection();
    final items = _buildItems();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          listing: widget.listing,
          ticketTypes: widget.ticketTypes,
          items: items,
          seatIds: ordered,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _selected
        ..clear()
        ..addAll(seats.heldByUser(widget.listing.id, _userId).where(_seatById.containsKey));
    });
  }

  List<BookingItem> _buildItems() {
    final counts = <String, int>{};
    for (final id in _selected) {
      final typeId = _seatById[id]!.ticketTypeId;
      counts[typeId] = (counts[typeId] ?? 0) + 1;
    }
    final items = <BookingItem>[];
    for (final group in _groups) {
      final qty = counts[group.type.id];
      if (qty == null || qty == 0) continue;
      items.add(BookingItem(
        typeId: group.type.id,
        typeName: group.type.name,
        unitPrice: group.type.price,
        quantity: qty,
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final seats = context.watch<SeatState>();

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
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth > 560 ? 560.0 : constraints.maxWidth;
                          final size = (((width - 40 - 44) / kSeatColumns) - 4).clamp(16.0, 32.0).toDouble();
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                                children: [
                                  _infoRow(),
                                  const SizedBox(height: 18),
                                  _screenIndicator(),
                                  const SizedBox(height: 18),
                                  _legend(),
                                  for (final group in _groups) ..._groupSection(group, size, seats),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _bottomBar(seats),
                  ],
                ),
    );
  }

  Widget _infoRow() {
    return Row(
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
    );
  }

  Widget _screenIndicator() {
    return Column(
      children: [
        Container(
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 36),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'SCREEN / STAGE',
          style: TextStyle(fontSize: 10, letterSpacing: 1.6, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _legend() {
    Widget item(Widget swatch, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          swatch,
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      );
    }

    Widget box({required Color fill, required Color border}) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: border, width: 1.4),
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        item(box(fill: Colors.white, border: AppColors.textSecondary), 'Available'),
        item(box(fill: AppColors.primary, border: AppColors.primary), 'Selected'),
        item(box(fill: _bookedColor, border: _bookedColor), 'Booked'),
        item(box(fill: _heldColor.withValues(alpha: 0.35), border: _heldColor), 'Reserved'),
      ],
    );
  }

  List<Widget> _groupSection(SeatGroup group, double size, SeatState seats) {
    final booked = seats.bookedSeats(widget.listing.id);
    final color = _colorByType[group.type.id]!;
    final bookedInGroup = [
      for (final row in group.rows)
        for (final seat in row)
          if (booked.contains(seat.id)) seat,
    ].length;
    final free = group.totalSeats - bookedInGroup;

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 22, 0, 10),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(group.type.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              'Rs. ${NumberFormat('#,###').format(group.type.price)} / seat',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: color),
            ),
            const Spacer(),
            Text(
              '$free of ${group.totalSeats} free',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      for (final row in group.rows) _seatRow(row, size, color, seats),
    ];
  }

  Widget _seatRow(List<Seat> rowSeats, double size, Color color, SeatState seats) {
    final children = <Widget>[
      SizedBox(
        width: 28,
        child: Text(
          rowSeats.first.row,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
      ),
    ];

    for (var c = 0; c < kSeatColumns; c++) {
      if (c == kSeatColumns ~/ 2) children.add(const SizedBox(width: 16));
      children.add(
        c < rowSeats.length
            ? _seatCell(rowSeats[c], size, color, seats)
            : SizedBox(width: size + 4, height: size + 4),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: children);
  }

  Widget _seatCell(Seat seat, double size, Color color, SeatState seats) {
    final id = seat.id;
    final isBooked = seats.bookedSeats(widget.listing.id).contains(id);
    final isHeld = !isBooked && seats.isHeldByOther(widget.listing.id, id, _userId);
    final isSelected = _selected.contains(id);

    Color fill = Colors.white;
    Color border = color;
    Widget? child;

    if (isBooked) {
      fill = _bookedColor;
      border = _bookedColor;
      child = Icon(Icons.close_rounded, size: size * 0.5, color: const Color(0xFF9CA3AF));
    } else if (isHeld) {
      fill = _heldColor.withValues(alpha: 0.35);
      border = _heldColor;
    } else if (isSelected) {
      fill = AppColors.primary;
      border = AppColors.primary;
      child = Icon(Icons.check_rounded, size: size * 0.62, color: Colors.white);
    } else if (size >= 24) {
      child = Text(
        '${seat.number}',
        style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w700, color: color),
      );
    }

    return GestureDetector(
      onTap: () => _toggle(seat),
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: border, width: 1.4),
        ),
        child: child,
      ),
    );
  }

  Widget _bottomBar(SeatState seats) {
    final ordered = _orderedSelection();
    final expiry = seats.holdExpiry(widget.listing.id, _userId);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (expiry != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: AppColors.pending),
                    const SizedBox(width: 6),
                    const Text(
                      'Seats reserved for ',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                    _HoldCountdown(expiresAt: expiry, onExpired: _onHoldExpired),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ordered.isEmpty
                            ? 'Select your seats'
                            : '${ordered.length} seat${ordered.length == 1 ? '' : 's'} selected',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ordered.isEmpty ? 'Tap a seat to select it' : ordered.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (ordered.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Text(
                      'Rs. ${NumberFormat('#,###').format(_total())}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                    ),
                  ),
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: ordered.isEmpty ? null : _continue,
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldCountdown extends StatefulWidget {
  final DateTime expiresAt;
  final VoidCallback onExpired;

  const _HoldCountdown({required this.expiresAt, required this.onExpired});

  @override
  State<_HoldCountdown> createState() => _HoldCountdownState();
}

class _HoldCountdownState extends State<_HoldCountdown> {
  Timer? _timer;
  late Duration _remaining;
  bool _fired = false;

  Duration _calc() {
    final diff = widget.expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void initState() {
    super.initState();
    _remaining = _calc();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant _HoldCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _fired = false;
      _remaining = _calc();
    }
  }

  void _tick() {
    if (!mounted) return;
    final remaining = _calc();
    setState(() => _remaining = remaining);
    if (remaining == Duration.zero && !_fired) {
      _fired = true;
      widget.onExpired();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Text(
      '$minutes:$seconds',
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.pending),
    );
  }
}