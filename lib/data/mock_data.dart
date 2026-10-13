import '../models/business_model.dart';
import '../models/listing_model.dart';
import '../models/ticket_type_model.dart';

final List<Business> mockBusinesses = [
  Business(
    id: 'b1',
    ownerId: 'owner1',
    name: 'Grand Cinema Islamabad',
    category: 'Cinema',
    description: 'A premium multiplex screening the latest blockbusters.',
    location: 'F-7 Markaz, Islamabad',
    contactPhone: '+92 300 1234567',
    status: BusinessStatus.approved,
    rating: 4.5,
    reviewCount: 320,
    createdAt: DateTime.now().subtract(const Duration(days: 200)),
  ),
  Business(
    id: 'b2',
    ownerId: 'owner2',
    name: 'Alhamra Arts Theatre',
    category: 'Theatre',
    description: 'Live stage dramas and classical performances.',
    location: 'The Mall, Lahore',
    contactPhone: '+92 321 7654321',
    status: BusinessStatus.approved,
    rating: 4.7,
    reviewCount: 148,
    createdAt: DateTime.now().subtract(const Duration(days: 150)),
  ),
  Business(
    id: 'b3',
    ownerId: 'owner3',
    name: 'Soundwave Live',
    category: 'Concerts',
    description: 'Concert promoter bringing top artists to the city.',
    location: 'Jinnah Stadium, Islamabad',
    contactPhone: '+92 333 9988776',
    status: BusinessStatus.approved,
    rating: 4.3,
    reviewCount: 412,
    createdAt: DateTime.now().subtract(const Duration(days: 90)),
  ),
  Business(
    id: 'b4',
    ownerId: 'owner4',
    name: 'Skillverse Workshops',
    category: 'Workshops',
    description: 'Hands-on professional skills workshops every weekend.',
    location: 'Blue Area, Islamabad',
    contactPhone: '+92 345 1122334',
    status: BusinessStatus.approved,
    rating: 4.8,
    reviewCount: 76,
    createdAt: DateTime.now().subtract(const Duration(days: 60)),
  ),
];

final List<Listing> mockListings = [
  Listing(
    id: 'l1',
    businessId: 'b1',
    title: 'Avengers: Example Movie',
    description: 'The team reassembles for one final mission to save the city.',
    category: 'Cinema',
    date: DateTime.now().add(const Duration(days: 1)),
    startTime: '7:00 PM',
    endTime: '9:30 PM',
    location: 'Hall 2, Grand Cinema Islamabad',
    requiresSeatSelection: true,
    ticketTypeIds: ['t1', 't2', 't3'],
  ),
  Listing(
    id: 'l2',
    businessId: 'b2',
    title: 'Waris Shah – A Classical Drama',
    description: 'An award-winning stage adaptation of the Punjabi classic.',
    category: 'Theatre',
    date: DateTime.now().add(const Duration(days: 3)),
    startTime: '6:30 PM',
    endTime: '8:30 PM',
    location: 'Main Hall, Alhamra Arts Theatre',
    requiresSeatSelection: true,
    ticketTypeIds: ['t4', 't5'],
  ),
  Listing(
    id: 'l3',
    businessId: 'b3',
    title: 'Coke Fest Live: Night of Legends',
    description: 'A night of live performances from top chart-topping artists.',
    category: 'Concerts',
    date: DateTime.now().add(const Duration(days: 7)),
    startTime: '8:00 PM',
    endTime: '11:30 PM',
    location: 'Jinnah Stadium, Islamabad',
    requiresSeatSelection: false,
    ticketTypeIds: ['t6', 't7', 't8'],
  ),
  Listing(
    id: 'l4',
    businessId: 'b4',
    title: 'UI/UX Design Bootcamp',
    description: 'A full-day hands-on workshop covering UI/UX fundamentals.',
    category: 'Workshops',
    date: DateTime.now().add(const Duration(days: 5)),
    startTime: '10:00 AM',
    endTime: '4:00 PM',
    location: 'Skillverse Hub, Blue Area',
    requiresSeatSelection: false,
    ticketTypeIds: ['t9'],
  ),
];

final List<TicketType> mockTicketTypes = [
  TicketType(id: 't1', listingId: 'l1', name: 'Regular', price: 800, totalQty: 150, soldQty: 90),
  TicketType(id: 't2', listingId: 'l1', name: 'Premium', price: 1200, totalQty: 80, soldQty: 55),
  TicketType(id: 't3', listingId: 'l1', name: 'VIP', price: 1800, totalQty: 30, soldQty: 12),
  TicketType(id: 't4', listingId: 'l2', name: 'Standard', price: 1000, totalQty: 120, soldQty: 70),
  TicketType(id: 't5', listingId: 'l2', name: 'Balcony', price: 1600, totalQty: 40, soldQty: 18),
  TicketType(id: 't6', listingId: 'l3', name: 'General Admission', price: 1500, totalQty: 500, soldQty: 320),
  TicketType(id: 't7', listingId: 'l3', name: 'VIP', price: 3000, totalQty: 100, soldQty: 72),
  TicketType(id: 't8', listingId: 'l3', name: 'Premium', price: 5000, totalQty: 50, soldQty: 35),
  TicketType(id: 't9', listingId: 'l4', name: 'Full Day Pass', price: 2500, totalQty: 60, soldQty: 41),
];

const List<String> mockCategories = [
  'Cinema',
  'Theatre',
  'Events',
  'Concerts',
  'Sports',
  'Workshops',
  'Attractions',
  'Experiences',
];

Business businessById(String id) =>
    mockBusinesses.firstWhere((b) => b.id == id);

List<Listing> listingsForBusiness(String businessId) =>
    mockListings.where((l) => l.businessId == businessId).toList();

List<TicketType> ticketTypesForListing(String listingId) =>
    mockTicketTypes.where((t) => t.listingId == listingId).toList();

double lowestPriceForListing(String listingId) {
  final types = ticketTypesForListing(listingId);
  if (types.isEmpty) return 0;
  return types.map((t) => t.price).reduce((a, b) => a < b ? a : b);
}

final List<Business> _seedBusinesses = List<Business>.of(mockBusinesses);
final List<Listing> _seedListings = List<Listing>.of(mockListings);
final List<TicketType> _seedTicketTypes = List<TicketType>.of(mockTicketTypes);

void syncCatalog({
  required List<Business> businesses,
  required List<Listing> listings,
  required List<TicketType> ticketTypes,
}) {
  final seedBusinesses = _seedBusinesses;
  final seedListings = _seedListings;
  final seedTicketTypes = _seedTicketTypes;

  final approved = businesses.where((b) => b.status == BusinessStatus.approved).toList();
  final approvedIds = approved.map((b) => b.id).toSet();
  final liveListings = listings
      .where((l) => approvedIds.contains(l.businessId) && l.status == ListingStatus.active)
      .toList();
  final liveListingIds = liveListings.map((l) => l.id).toSet();

  mockBusinesses
    ..clear()
    ..addAll(seedBusinesses)
    ..addAll(approved);
  mockListings
    ..clear()
    ..addAll(seedListings)
    ..addAll(liveListings);
  mockTicketTypes
    ..clear()
    ..addAll(seedTicketTypes)
    ..addAll(ticketTypes.where((t) => liveListingIds.contains(t.listingId)));
}