import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/booking_model.dart';
import '../models/listing_model.dart';
import '../models/ticket_type_model.dart';

enum TicketCheckStatus { valid, alreadyUsed, cancelled, invalid }

class TicketCheck {
  final TicketCheckStatus status;
  final String message;
  final Booking? booking;

  const TicketCheck(this.status, this.message, [this.booking]);
}

class BookingState extends ChangeNotifier {
  static const _bookingsKey = 'tickethub_bookings';

  final _uuid = const Uuid();
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _error;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> bootstrap() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bookingsKey);
    if (raw != null) {
      final List decoded = jsonDecode(raw) as List;
      _bookings = decoded.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _bookingsKey,
      jsonEncode(_bookings.map((b) => b.toJson()).toList()),
    );
  }

  List<Booking> bookingsForUser(String userId) {
    final list = _bookings.where((b) => b.customerId == userId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Booking> upcomingFor(String userId) {
    final list = bookingsForUser(userId).where((b) => b.isUpcoming).toList();
    list.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    return list;
  }

  List<Booking> historyFor(String userId) {
    return bookingsForUser(userId).where((b) => !b.isUpcoming).toList();
  }

  Booking? byId(String id) {
    final matches = _bookings.where((b) => b.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  int bookedQty(String ticketTypeId) {
    var total = 0;
    for (final booking in _bookings) {
      if (!booking.holdsInventory) continue;
      for (final item in booking.items) {
        if (item.typeId == ticketTypeId) total += item.quantity;
      }
    }
    return total;
  }

  int availableFor(TicketType type) {
    final value = type.totalQty - type.soldQty - bookedQty(type.id);
    return value < 0 ? 0 : value;
  }

  String _generateCode() {
    final stamp = DateFormat('yyMMdd').format(DateTime.now());
    String code;
    do {
      code = 'TH-$stamp-${_uuid.v4().substring(0, 6).toUpperCase()}';
    } while (_bookings.any((b) => b.bookingCode == code));
    return code;
  }

  Future<Booking?> createBooking({
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String businessName,
    required Listing listing,
    required List<TicketType> ticketTypes,
    required List<BookingItem> items,
    required List<String> seatIds,
    required PaymentMethod paymentMethod,
  }) async {
    _error = null;

    if (items.isEmpty || items.every((i) => i.quantity <= 0)) {
      _error = 'Please select at least one ticket.';
      notifyListeners();
      return null;
    }

    final typesById = {for (final t in ticketTypes) t.id: t};
    for (final item in items) {
      final type = typesById[item.typeId];
      if (type == null) {
        _error = 'Ticket type "${item.typeName}" is no longer available.';
        notifyListeners();
        return null;
      }
      if (item.quantity > availableFor(type)) {
        _error = 'Only ${availableFor(type)} "${item.typeName}" ticket(s) left.';
        notifyListeners();
        return null;
      }
    }

    final total = items.fold<double>(0, (sum, i) => sum + i.subtotal);

    final booking = Booking(
      id: _uuid.v4(),
      bookingCode: _generateCode(),
      customerId: customerId,
      customerName: customerName.trim(),
      customerEmail: customerEmail.trim(),
      customerPhone: customerPhone.trim(),
      businessId: listing.businessId,
      businessName: businessName,
      listingId: listing.id,
      listingTitle: listing.title,
      eventDate: listing.date,
      startTime: listing.startTime,
      endTime: listing.endTime,
      location: listing.location,
      items: items,
      seatIds: seatIds,
      totalAmount: total,
      paymentMethod: paymentMethod,
      status: paymentMethod.isOnline ? BookingStatus.paid : BookingStatus.confirmed,
      createdAt: DateTime.now(),
    );

    _bookings.add(booking);
    await _persist();
    notifyListeners();
    return booking;
  }

  Future<Booking?> cancelBooking(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return null;

    final booking = _bookings[index];
    if (!booking.canCancel) return null;

    final next = booking.status == BookingStatus.paid
        ? BookingStatus.refunded
        : BookingStatus.cancelled;

    _bookings[index] = booking.copyWith(status: next);
    await _persist();
    notifyListeners();
    return _bookings[index];
  }

  List<Booking> bookingsForBusiness(String businessId) {
    final list = _bookings.where((b) => b.businessId == businessId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  TicketCheck validateTicket(String raw, Set<String> businessIds) {
    var code = raw.trim().toUpperCase();
    if (code.startsWith('TICKETHUB:')) code = code.substring(10);
    if (code.isEmpty) {
      return const TicketCheck(TicketCheckStatus.invalid, 'Enter or scan a ticket code.');
    }

    final matches = _bookings.where((b) => b.bookingCode == code);
    if (matches.isEmpty) {
      return const TicketCheck(TicketCheckStatus.invalid, 'No ticket found for this code.');
    }

    final booking = matches.first;
    if (!businessIds.contains(booking.businessId)) {
      return TicketCheck(TicketCheckStatus.invalid, 'This ticket belongs to a different business.', booking);
    }
    if (booking.status == BookingStatus.cancelled || booking.status == BookingStatus.refunded) {
      return TicketCheck(
        TicketCheckStatus.cancelled,
        'This booking was ${booking.status.label.toLowerCase()}.',
        booking,
      );
    }
    if (booking.status == BookingStatus.used) {
      return TicketCheck(TicketCheckStatus.alreadyUsed, 'This ticket has already been used.', booking);
    }
    if (booking.isEventPassed) {
      return TicketCheck(
        TicketCheckStatus.invalid,
        'This ticket was for ${DateFormat('d MMM yyyy').format(booking.eventDate)}, which has passed.',
        booking,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(booking.eventDate.year, booking.eventDate.month, booking.eventDate.day);
    if (eventDay.isAfter(today)) {
      return TicketCheck(
        TicketCheckStatus.valid,
        'Valid ticket. Note: the event is on ${DateFormat('EEE, d MMM').format(booking.eventDate)}.',
        booking,
      );
    }
    return TicketCheck(TicketCheckStatus.valid, 'Valid ticket. Entry allowed.', booking);
  }

  Future<bool> markUsed(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return false;
    final booking = _bookings[index];
    final usable = booking.status == BookingStatus.paid ||
        booking.status == BookingStatus.confirmed ||
        booking.status == BookingStatus.pending;
    if (!usable) return false;

    _bookings[index] = booking.copyWith(status: BookingStatus.used);
    await _persist();
    notifyListeners();
    return true;
  }
}