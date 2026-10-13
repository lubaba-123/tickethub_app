import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/mock_data.dart';
import '../models/business_model.dart';
import '../models/listing_model.dart';
import '../models/ticket_type_model.dart';

class BusinessState extends ChangeNotifier {
  static const _businessesKey = 'tickethub_businesses';
  static const _listingsKey = 'tickethub_listings';
  static const _ticketTypesKey = 'tickethub_ticket_types';

  final _uuid = const Uuid();
  List<Business> _businesses = [];
  List<Listing> _listings = [];
  List<TicketType> _ticketTypes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void notifyListeners() {
    syncCatalog(businesses: _businesses, listings: _listings, ticketTypes: _ticketTypes);
    super.notifyListeners();
  }

  List<Business> get businesses => _businesses;
  List<Listing> get listings => _listings;
  List<TicketType> get ticketTypes => _ticketTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> bootstrap() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    final businessesRaw = prefs.getString(_businessesKey);
    if (businessesRaw != null) {
      final List decoded = jsonDecode(businessesRaw) as List;
      _businesses =
          decoded.map((e) => Business.fromJson(e as Map<String, dynamic>)).toList();
    }

    final listingsRaw = prefs.getString(_listingsKey);
    if (listingsRaw != null) {
      final List decoded = jsonDecode(listingsRaw) as List;
      _listings =
          decoded.map((e) => Listing.fromJson(e as Map<String, dynamic>)).toList();
    }

    final ticketTypesRaw = prefs.getString(_ticketTypesKey);
    if (ticketTypesRaw != null) {
      final List decoded = jsonDecode(ticketTypesRaw) as List;
      _ticketTypes =
          decoded.map((e) => TicketType.fromJson(e as Map<String, dynamic>)).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _persistBusinesses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _businessesKey,
      jsonEncode(_businesses.map((b) => b.toJson()).toList()),
    );
  }

  Future<void> _persistListings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _listingsKey,
      jsonEncode(_listings.map((l) => l.toJson()).toList()),
    );
  }

  Future<void> _persistTicketTypes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ticketTypesKey,
      jsonEncode(_ticketTypes.map((t) => t.toJson()).toList()),
    );
  }

  List<TicketType> ticketTypesForListing(String listingId) {
    return _ticketTypes.where((t) => t.listingId == listingId).toList();
  }

  Future<bool> addTicketType({
    required String listingId,
    required String name,
    required double price,
    required int totalQty,
  }) async {
    _error = null;

    if (name.trim().isEmpty || price <= 0 || totalQty <= 0) {
      _error = 'Enter a valid name, price and quantity.';
      notifyListeners();
      return false;
    }
    final duplicate = _ticketTypes.any(
      (t) => t.listingId == listingId && t.name.toLowerCase() == name.trim().toLowerCase(),
    );
    if (duplicate) {
      _error = 'A ticket type with this name already exists.';
      notifyListeners();
      return false;
    }

    final ticketType = TicketType(
      id: _uuid.v4(),
      listingId: listingId,
      name: name.trim(),
      price: price,
      totalQty: totalQty,
    );
    _ticketTypes.add(ticketType);

    final listingIndex = _listings.indexWhere((l) => l.id == listingId);
    if (listingIndex != -1) {
      final l = _listings[listingIndex];
      _listings[listingIndex] = Listing(
        id: l.id,
        businessId: l.businessId,
        title: l.title,
        description: l.description,
        category: l.category,
        date: l.date,
        startTime: l.startTime,
        endTime: l.endTime,
        location: l.location,
        requiresSeatSelection: l.requiresSeatSelection,
        status: l.status,
        ticketTypeIds: [...l.ticketTypeIds, ticketType.id],
      );
      await _persistListings();
    }

    await _persistTicketTypes();
    notifyListeners();
    return true;
  }

  Future<bool> updateTicketType({
    required String ticketTypeId,
    required String name,
    required double price,
    required int totalQty,
  }) async {
    _error = null;
    final index = _ticketTypes.indexWhere((t) => t.id == ticketTypeId);
    if (index == -1) return false;

    final existing = _ticketTypes[index];
    if (name.trim().isEmpty || price <= 0 || totalQty <= 0) {
      _error = 'Enter a valid name, price and quantity.';
      notifyListeners();
      return false;
    }
    if (totalQty < existing.soldQty) {
      _error = 'Total quantity cannot be less than tickets already sold (${existing.soldQty}).';
      notifyListeners();
      return false;
    }
    final duplicate = _ticketTypes.any(
      (t) =>
          t.id != ticketTypeId &&
          t.listingId == existing.listingId &&
          t.name.toLowerCase() == name.trim().toLowerCase(),
    );
    if (duplicate) {
      _error = 'A ticket type with this name already exists.';
      notifyListeners();
      return false;
    }

    _ticketTypes[index] = TicketType(
      id: existing.id,
      listingId: existing.listingId,
      name: name.trim(),
      price: price,
      totalQty: totalQty,
      soldQty: existing.soldQty,
    );

    await _persistTicketTypes();
    notifyListeners();
    return true;
  }

  Future<void> deleteTicketType(String ticketTypeId) async {
    final index = _ticketTypes.indexWhere((t) => t.id == ticketTypeId);
    if (index == -1) return;
    final removed = _ticketTypes.removeAt(index);

    final listingIndex = _listings.indexWhere((l) => l.id == removed.listingId);
    if (listingIndex != -1) {
      final l = _listings[listingIndex];
      _listings[listingIndex] = Listing(
        id: l.id,
        businessId: l.businessId,
        title: l.title,
        description: l.description,
        category: l.category,
        date: l.date,
        startTime: l.startTime,
        endTime: l.endTime,
        location: l.location,
        requiresSeatSelection: l.requiresSeatSelection,
        status: l.status,
        ticketTypeIds: l.ticketTypeIds.where((id) => id != ticketTypeId).toList(),
      );
      await _persistListings();
    }

    await _persistTicketTypes();
    notifyListeners();
  }

  Business? businessById(String id) {
    final matches = _businesses.where((b) => b.id == id);
    return matches.isNotEmpty ? matches.first : null;
  }

  Future<bool> setBusinessStatus(String businessId, BusinessStatus status) async {
    final index = _businesses.indexWhere((b) => b.id == businessId);
    if (index == -1) return false;
    _businesses[index] = _businesses[index].copyWith(status: status);
    await _persistBusinesses();
    notifyListeners();
    return true;
  }

  Business? businessForOwner(String ownerId) {
    final matches = _businesses.where((b) => b.ownerId == ownerId);
    return matches.isNotEmpty ? matches.first : null;
  }

  List<Listing> listingsForBusiness(String businessId) {
    return _listings.where((l) => l.businessId == businessId).toList();
  }

  Future<bool> registerBusiness({
    required String ownerId,
    required String name,
    required String category,
    required String description,
    required String location,
    required String contactPhone,
  }) async {
    _error = null;

    if (name.trim().isEmpty || description.trim().isEmpty || location.trim().isEmpty) {
      _error = 'Please fill in all required fields.';
      notifyListeners();
      return false;
    }
    if (businessForOwner(ownerId) != null) {
      _error = 'You already have a registered business.';
      notifyListeners();
      return false;
    }

    final business = Business(
      id: _uuid.v4(),
      ownerId: ownerId,
      name: name.trim(),
      category: category,
      description: description.trim(),
      location: location.trim(),
      contactPhone: contactPhone.trim(),
      status: BusinessStatus.pending,
      createdAt: DateTime.now(),
    );

    _businesses.add(business);
    await _persistBusinesses();
    notifyListeners();
    return true;
  }

  Future<bool> updateBusiness({
    required String businessId,
    required String name,
    required String category,
    required String description,
    required String location,
    required String contactPhone,
  }) async {
    final index = _businesses.indexWhere((b) => b.id == businessId);
    if (index == -1) return false;

    _businesses[index] = _businesses[index].copyWith(
      name: name.trim(),
      category: category,
      description: description.trim(),
      location: location.trim(),
      contactPhone: contactPhone.trim(),
    );

    await _persistBusinesses();
    notifyListeners();
    return true;
  }

  Future<String?> addListing({
    required String businessId,
    required String title,
    required String description,
    required String category,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String location,
    required bool requiresSeatSelection,
  }) async {
    _error = null;

    if (title.trim().isEmpty || location.trim().isEmpty) {
      _error = 'Please fill in all required fields.';
      notifyListeners();
      return null;
    }

    final listing = Listing(
      id: _uuid.v4(),
      businessId: businessId,
      title: title.trim(),
      description: description.trim(),
      category: category,
      date: date,
      startTime: startTime,
      endTime: endTime,
      location: location.trim(),
      requiresSeatSelection: requiresSeatSelection,
      status: ListingStatus.active,
      ticketTypeIds: const [],
    );

    _listings.add(listing);
    await _persistListings();
    notifyListeners();
    return listing.id;
  }

  Future<bool> updateListing({
    required String listingId,
    required String title,
    required String description,
    required String category,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String location,
    required bool requiresSeatSelection,
  }) async {
    final index = _listings.indexWhere((l) => l.id == listingId);
    if (index == -1) return false;

    final existing = _listings[index];
    _listings[index] = Listing(
      id: existing.id,
      businessId: existing.businessId,
      title: title.trim(),
      description: description.trim(),
      category: category,
      date: date,
      startTime: startTime,
      endTime: endTime,
      location: location.trim(),
      requiresSeatSelection: requiresSeatSelection,
      status: existing.status,
      ticketTypeIds: existing.ticketTypeIds,
    );

    await _persistListings();
    notifyListeners();
    return true;
  }

  Future<void> deleteListing(String listingId) async {
    _listings.removeWhere((l) => l.id == listingId);
    _ticketTypes.removeWhere((t) => t.listingId == listingId);
    await _persistListings();
    await _persistTicketTypes();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}