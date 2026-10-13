import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/mock_data.dart';
import '../../models/business_model.dart';
import '../../models/listing_model.dart';
import '../../state/booking_state.dart';
import '../../state/review_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/open_listing.dart';
import '../../widgets/business_card.dart';
import '../../widgets/listing_card.dart';
import 'business_details_screen.dart';

enum _Mode { businesses, events }

enum _DateFilter { any, today, week, pick }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const double _priceCap = 6000;
  static const _sorts = ['Popular', 'Soonest', 'Price: Low to High', 'Price: High to Low', 'Highest Rated'];

  final _controller = TextEditingController();
  _Mode _mode = _Mode.businesses;
  String _query = '';
  String? _category;
  _DateFilter _dateFilter = _DateFilter.any;
  DateTime? _pickedDate;
  double _maxPrice = _priceCap;
  bool _onlyAvailable = false;
  String _sort = 'Popular';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matchesText(String q, List<String> fields) {
    if (q.isEmpty) return true;
    final lower = q.toLowerCase();
    return fields.any((f) => f.toLowerCase().contains(lower));
  }

  List<Business> _businessResults() {
    return mockBusinesses.where((b) {
      final matchesQuery = _matchesText(_query, [b.name, b.location, b.category]);
      final matchesCategory = _category == null || b.category == _category;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  bool _matchesDate(Listing listing) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(listing.date.year, listing.date.month, listing.date.day);
    switch (_dateFilter) {
      case _DateFilter.any:
        return true;
      case _DateFilter.today:
        return day == today;
      case _DateFilter.week:
        return !day.isBefore(today) && day.difference(today).inDays <= 7;
      case _DateFilter.pick:
        final picked = _pickedDate;
        if (picked == null) return true;
        return day == DateTime(picked.year, picked.month, picked.day);
    }
  }

  List<Listing> _eventResults(BookingState bookings, ReviewState reviews) {
    final list = mockListings.where((l) {
      final businessName = _safeBusinessName(l.businessId);
      if (!_matchesText(_query, [l.title, businessName, l.location, l.category])) return false;
      if (_category != null && l.category != _category) return false;
      if (!_matchesDate(l)) return false;
      if (_maxPrice < _priceCap && lowestPriceForListing(l.id) > _maxPrice) return false;
      if (_onlyAvailable) {
        final types = ticketTypesForListing(l.id);
        if (!types.any((t) => bookings.availableFor(t) > 0)) return false;
      }
      return true;
    }).toList();

    int popularity(Listing l) {
      return ticketTypesForListing(l.id).fold<int>(0, (a, t) => a + t.soldQty + bookings.bookedQty(t.id));
    }

    double rating(Listing l) {
      for (final b in mockBusinesses) {
        if (b.id == l.businessId) return reviews.summaryFor(b.id, b.rating, b.reviewCount).rating;
      }
      return 0;
    }

    switch (_sort) {
      case 'Soonest':
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Price: Low to High':
        list.sort((a, b) => lowestPriceForListing(a.id).compareTo(lowestPriceForListing(b.id)));
        break;
      case 'Price: High to Low':
        list.sort((a, b) => lowestPriceForListing(b.id).compareTo(lowestPriceForListing(a.id)));
        break;
      case 'Highest Rated':
        list.sort((a, b) => rating(b).compareTo(rating(a)));
        break;
      default:
        list.sort((a, b) => popularity(b).compareTo(popularity(a)));
    }
    return list;
  }

  String _safeBusinessName(String id) {
    for (final b in mockBusinesses) {
      if (b.id == id) return b.name;
    }
    return '';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _pickedDate = picked;
        _dateFilter = _DateFilter.pick;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingState>();
    final reviews = context.watch<ReviewState>();
    final isEvents = _mode == _Mode.events;
    final businessResults = isEvents ? const <Business>[] : _businessResults();
    final eventResults = isEvents ? _eventResults(bookings, reviews) : const <Listing>[];
    final resultCount = isEvents ? eventResults.length : businessResults.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: SegmentedButton<_Mode>(
                  segments: const [
                    ButtonSegment(value: _Mode.businesses, label: Text('Businesses'), icon: Icon(Icons.storefront_outlined)),
                    ButtonSegment(value: _Mode.events, label: Text('Events & Tickets'), icon: Icon(Icons.event_outlined)),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: TextField(
                  controller: _controller,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: isEvents ? 'Search events, venues or locations' : 'Search by name, category or location',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _chip('All', _category == null, () => setState(() => _category = null)),
                    for (final cat in mockCategories)
                      _chip(cat, _category == cat, () => setState(() => _category = _category == cat ? null : cat)),
                  ],
                ),
              ),
              if (isEvents) _filters(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$resultCount result${resultCount == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ),
              ),
              Expanded(
                child: resultCount == 0
                    ? const Center(child: Text('No results found.', style: TextStyle(color: AppColors.textSecondary)))
                    : isEvents
                        ? ListView(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                            children: [
                              for (final listing in eventResults)
                                ListingCard(listing: listing, onTap: () => openListing(context, listing)),
                            ],
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                            itemCount: businessResults.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.78,
                            ),
                            itemBuilder: (context, i) {
                              final business = businessResults[i];
                              return BusinessCard(
                                business: business,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => BusinessDetailsScreen(businessId: business.id)),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filters() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        title: const Text('Filters & sort', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        leading: const Icon(Icons.tune_rounded, color: AppColors.primary),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Any date', _dateFilter == _DateFilter.any, () => setState(() => _dateFilter = _DateFilter.any)),
                _chip('Today', _dateFilter == _DateFilter.today, () => setState(() => _dateFilter = _DateFilter.today)),
                _chip('Next 7 days', _dateFilter == _DateFilter.week, () => setState(() => _dateFilter = _DateFilter.week)),
                _chip(
                  _pickedDate == null ? 'Pick date' : DateFormat('d MMM').format(_pickedDate!),
                  _dateFilter == _DateFilter.pick,
                  _pickDate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Max price', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              Text(
                _maxPrice >= _priceCap ? 'Any price' : 'Up to Rs. ${NumberFormat('#,###').format(_maxPrice)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
              ),
            ],
          ),
          Slider(
            value: _maxPrice,
            min: 500,
            max: _priceCap,
            divisions: 11,
            onChanged: (v) => setState(() => _maxPrice = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Only show available tickets', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            value: _onlyAvailable,
            onChanged: (v) => setState(() => _onlyAvailable = v),
          ),
          DropdownButtonFormField<String>(
            initialValue: _sort,
            decoration: const InputDecoration(labelText: 'Sort by'),
            items: [for (final s in _sorts) DropdownMenuItem(value: s, child: Text(s))],
            onChanged: (v) => setState(() => _sort = v ?? 'Popular'),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}