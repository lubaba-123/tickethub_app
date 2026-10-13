class TicketType {
  final String id;
  final String listingId;
  final String name;
  final double price;
  final int totalQty;
  final int soldQty;

  TicketType({
    required this.id,
    required this.listingId,
    required this.name,
    required this.price,
    required this.totalQty,
    this.soldQty = 0,
  });

  int get remaining => totalQty - soldQty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'listingId': listingId,
        'name': name,
        'price': price,
        'totalQty': totalQty,
        'soldQty': soldQty,
      };

  factory TicketType.fromJson(Map<String, dynamic> json) {
    return TicketType(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      totalQty: json['totalQty'] as int,
      soldQty: json['soldQty'] as int,
    );
  }
}
