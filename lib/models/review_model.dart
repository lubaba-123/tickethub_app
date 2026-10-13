class Review {
  final String id;
  final String businessId;
  final String listingId;
  final String bookingId;
  final String customerId;
  final String customerName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.businessId,
    required this.listingId,
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'listingId': listingId,
        'bookingId': bookingId,
        'customerId': customerId,
        'customerName': customerName,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      listingId: json['listingId'] as String,
      bookingId: json['bookingId'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
