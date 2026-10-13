import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/booking_model.dart';
import '../models/notification_model.dart';

class NotificationState extends ChangeNotifier {
  static const _key = 'tickethub_notifications';

  final _uuid = const Uuid();
  List<AppNotification> _items = [];

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final List decoded = jsonDecode(raw) as List;
      _items = decoded.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items.map((n) => n.toJson()).toList()));
  }

  List<AppNotification> forUser(String userId) {
    final list = _items.where((n) => n.userId == userId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int unreadCount(String userId) {
    return _items.where((n) => n.userId == userId && !n.read).length;
  }

  Future<void> notify(String userId, String title, String body, {String? refKey}) async {
    if (refKey != null && _items.any((n) => n.userId == userId && n.refKey == refKey)) return;
    _items.add(AppNotification(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      refKey: refKey,
    ));
    await _persist();
    notifyListeners();
  }

  Future<void> markAllRead(String userId) async {
    var changed = false;
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].userId == userId && !_items[i].read) {
        _items[i] = _items[i].copyWith(read: true);
        changed = true;
      }
    }
    if (!changed) return;
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll(String userId) async {
    _items.removeWhere((n) => n.userId == userId);
    await _persist();
    notifyListeners();
  }

  Future<void> generateReminders(String userId, List<Booking> upcoming) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    for (final booking in upcoming) {
      final day = DateTime(booking.eventDate.year, booking.eventDate.month, booking.eventDate.day);
      final diff = day.difference(start).inDays;
      if (diff < 0 || diff > 2) continue;
      await notify(
        userId,
        'Upcoming event',
        '${booking.listingTitle} is on ${DateFormat('EEE, d MMM').format(booking.eventDate)} at ${booking.startTime}.',
        refKey: 'reminder:${booking.id}',
      );
    }
  }
}
