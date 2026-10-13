import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/seat_model.dart';
import '../models/ticket_type_model.dart';

class _Hold {
  final String userId;
  final DateTime expiresAt;

  const _Hold(this.userId, this.expiresAt);
}

class SeatState extends ChangeNotifier {
  static const _bookedKey = 'tickethub_booked_seats';
  static const _seededKey = 'tickethub_seeded_listings';
  static const Duration holdDuration = Duration(minutes: 5);

  late final Future<void> ready;
  Map<String, Set<String>> _booked = {};
  Set<String> _seeded = {};
  final Map<String, Map<String, _Hold>> _holds = {};

  SeatState() {
    ready = _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final bookedRaw = prefs.getString(_bookedKey);
    if (bookedRaw != null) {
      final decoded = jsonDecode(bookedRaw) as Map<String, dynamic>;
      _booked = decoded.map((k, v) => MapEntry(k, Set<String>.from(v as List)));
    }

    final seededRaw = prefs.getStringList(_seededKey);
    if (seededRaw != null) _seeded = seededRaw.toSet();

    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _bookedKey,
      jsonEncode(_booked.map((k, v) => MapEntry(k, v.toList()))),
    );
    await prefs.setStringList(_seededKey, _seeded.toList());
  }

  Future<void> ensureSeeded(String listingId, List<TicketType> types) async {
    await ready;
    if (_seeded.contains(listingId)) return;

    final booked = _booked.putIfAbsent(listingId, () => <String>{});
    for (final group in buildSeatLayout(types)) {
      final seats = [for (final row in group.rows) ...row];
      final random = Random(listingId.hashCode ^ group.type.id.hashCode);
      seats.shuffle(random);
      final count = group.type.soldQty < seats.length ? group.type.soldQty : seats.length;
      for (var i = 0; i < count; i++) {
        booked.add(seats[i].id);
      }
    }

    _seeded.add(listingId);
    await _persist();
    notifyListeners();
  }

  Set<String> bookedSeats(String listingId) {
    return _booked[listingId] ?? <String>{};
  }

  void _purge(String listingId) {
    final holds = _holds[listingId];
    if (holds == null) return;
    final now = DateTime.now();
    holds.removeWhere((_, hold) => hold.expiresAt.isBefore(now));
  }

  void refresh(String listingId) {
    _purge(listingId);
    notifyListeners();
  }

  bool isHeldByOther(String listingId, String seatId, String userId) {
    _purge(listingId);
    final hold = _holds[listingId]?[seatId];
    return hold != null && hold.userId != userId;
  }

  Set<String> heldByUser(String listingId, String userId) {
    _purge(listingId);
    final holds = _holds[listingId];
    if (holds == null) return <String>{};
    return holds.entries
        .where((e) => e.value.userId == userId)
        .map((e) => e.key)
        .toSet();
  }

  DateTime? holdExpiry(String listingId, String userId) {
    _purge(listingId);
    final holds = _holds[listingId];
    if (holds == null) return null;
    for (final hold in holds.values) {
      if (hold.userId == userId) return hold.expiresAt;
    }
    return null;
  }

  bool holdSeats(String listingId, Set<String> seatIds, String userId) {
    _purge(listingId);
    final booked = bookedSeats(listingId);
    final holds = _holds.putIfAbsent(listingId, () => {});

    for (final id in seatIds) {
      if (booked.contains(id)) return false;
      final existing = holds[id];
      if (existing != null && existing.userId != userId) return false;
    }

    holds.removeWhere((_, hold) => hold.userId == userId);
    final expiry = DateTime.now().add(holdDuration);
    for (final id in seatIds) {
      holds[id] = _Hold(userId, expiry);
    }

    notifyListeners();
    return true;
  }

  void releaseHolds(String listingId, String userId) {
    _holds[listingId]?.removeWhere((_, hold) => hold.userId == userId);
    notifyListeners();
  }

  Future<void> releaseBooked(String listingId, Set<String> seatIds) async {
    _booked[listingId]?.removeAll(seatIds);
    await _persist();
    notifyListeners();
  }

  Future<void> confirmBooking(String listingId, Set<String> seatIds, String userId) async {
    final booked = _booked.putIfAbsent(listingId, () => <String>{});
    booked.addAll(seatIds);
    _holds[listingId]?.removeWhere((_, hold) => hold.userId == userId);
    await _persist();
    notifyListeners();
  }
}