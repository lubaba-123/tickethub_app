enum BusinessStatus { pending, approved, rejected, suspended }

BusinessStatus businessStatusFromString(String value) {
  return BusinessStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => BusinessStatus.pending,
  );
}

class Business {
  final String id;
  final String ownerId;
  final String name;
  final String category;
  final String description;
  final String location;
  final String contactPhone;
  final String? logoAsset;
  final String? coverAsset;
  final BusinessStatus status;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;

  Business({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.description,
    required this.location,
    required this.contactPhone,
    this.logoAsset,
    this.coverAsset,
    this.status = BusinessStatus.pending,
    this.rating = 0,
    this.reviewCount = 0,
    required this.createdAt,
  });

  Business copyWith({
    String? name,
    String? category,
    String? description,
    String? location,
    String? contactPhone,
    BusinessStatus? status,
  }) {
    return Business(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      location: location ?? this.location,
      contactPhone: contactPhone ?? this.contactPhone,
      logoAsset: logoAsset,
      coverAsset: coverAsset,
      status: status ?? this.status,
      rating: rating,
      reviewCount: reviewCount,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'name': name,
        'category': category,
        'description': description,
        'location': location,
        'contactPhone': contactPhone,
        'status': status.name,
        'rating': rating,
        'reviewCount': reviewCount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      contactPhone: json['contactPhone'] as String,
      status: businessStatusFromString(json['status'] as String),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

const List<String> kBusinessCategories = [
  'Cinema',
  'Theatre',
  'Events',
  'Concerts',
  'Sports',
  'Workshops',
  'Attractions',
  'Experiences',
  'Other',
];
