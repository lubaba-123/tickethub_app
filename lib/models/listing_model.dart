enum ListingStatus { active, inactive, soldOut }

ListingStatus listingStatusFromString(String value) {
  return ListingStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => ListingStatus.active,
  );
}

class Listing {
  final String id;
  final String businessId;
  final String title;
  final String description;
  final String category;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String location;
  final bool requiresSeatSelection;
  final ListingStatus status;
  final List<String> ticketTypeIds;

  Listing({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.requiresSeatSelection = false,
    this.status = ListingStatus.active,
    this.ticketTypeIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'title': title,
        'description': description,
        'category': category,
        'date': date.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'location': location,
        'requiresSeatSelection': requiresSeatSelection,
        'status': status.name,
        'ticketTypeIds': ticketTypeIds,
      };

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      location: json['location'] as String,
      requiresSeatSelection: json['requiresSeatSelection'] as bool,
      status: listingStatusFromString(json['status'] as String),
      ticketTypeIds: List<String>.from(json['ticketTypeIds'] as List),
    );
  }
}
