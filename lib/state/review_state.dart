import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/review_model.dart';

class RatingSummary {
  final double rating;
  final int count;

  const RatingSummary(this.rating, this.count);
}

class ReviewState extends ChangeNotifier {
  static const _reviewsKey = 'tickethub_reviews';

  final _uuid = const Uuid();
  List<Review> _reviews = [];
  String? _error;

  List<Review> get reviews {
    final list = [..._reviews];
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  String? get error => _error;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reviewsKey);
    if (raw != null) {
      final List decoded = jsonDecode(raw) as List;
      _reviews = decoded.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reviewsKey, jsonEncode(_reviews.map((r) => r.toJson()).toList()));
  }

  List<Review> forBusiness(String businessId) {
    return reviews.where((r) => r.businessId == businessId).toList();
  }

  Review? forBooking(String bookingId) {
    final matches = _reviews.where((r) => r.bookingId == bookingId);
    return matches.isNotEmpty ? matches.first : null;
  }

  RatingSummary summaryFor(String businessId, double baseRating, int baseCount) {
    final list = _reviews.where((r) => r.businessId == businessId).toList();
    if (list.isEmpty) return RatingSummary(baseRating, baseCount);
    final sum = list.fold<int>(0, (a, r) => a + r.rating);
    final count = baseCount + list.length;
    final rating = (baseRating * baseCount + sum) / count;
    return RatingSummary(rating, count);
  }

  Future<bool> addReview({
    required String businessId,
    required String listingId,
    required String bookingId,
    required String customerId,
    required String customerName,
    required int rating,
    required String comment,
  }) async {
    _error = null;
    if (rating < 1 || rating > 5) {
      _error = 'Please choose a rating from 1 to 5.';
      notifyListeners();
      return false;
    }
    if (forBooking(bookingId) != null) {
      _error = 'You have already reviewed this booking.';
      notifyListeners();
      return false;
    }

    _reviews.add(Review(
      id: _uuid.v4(),
      businessId: businessId,
      listingId: listingId,
      bookingId: bookingId,
      customerId: customerId,
      customerName: customerName,
      rating: rating,
      comment: comment.trim(),
      createdAt: DateTime.now(),
    ));
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> deleteReview(String reviewId) async {
    _reviews.removeWhere((r) => r.id == reviewId);
    await _persist();
    notifyListeners();
  }
}
