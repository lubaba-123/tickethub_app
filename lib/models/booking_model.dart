enum BookingStatus { pending, confirmed, paid, cancelled, completed, used, refunded }

enum PaymentMethod { cash, jazzCash, easyPaisa, card }

extension BookingStatusX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.paid:
        return 'Paid';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.used:
        return 'Used';
      case BookingStatus.refunded:
        return 'Refunded';
    }
  }
}

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Pay at venue';
      case PaymentMethod.jazzCash:
        return 'JazzCash';
      case PaymentMethod.easyPaisa:
        return 'EasyPaisa';
      case PaymentMethod.card:
        return 'Debit / Credit Card';
    }
  }

  bool get isOnline => this != PaymentMethod.cash;
}

BookingStatus bookingStatusFromString(String value) {
  return BookingStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => BookingStatus.pending,
  );
}

PaymentMethod paymentMethodFromString(String value) {
  return PaymentMethod.values.firstWhere(
    (m) => m.name == value,
    orElse: () => PaymentMethod.cash,
  );
}

class BookingItem {
  final String typeId;
  final String typeName;
  final double unitPrice;
  final int quantity;

  const BookingItem({
    required this.typeId,
    required this.typeName,
    required this.unitPrice,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
        'typeId': typeId,
        'typeName': typeName,
        'unitPrice': unitPrice,
        'quantity': quantity,
      };

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    return BookingItem(
      typeId: json['typeId'] as String,
      typeName: json['typeName'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }
}

class Booking {
  final String id;
  final String bookingCode;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String businessId;
  final String businessName;
  final String listingId;
  final String listingTitle;
  final DateTime eventDate;
  final String startTime;
  final String endTime;
  final String location;
  final List<BookingItem> items;
  final List<String> seatIds;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final BookingStatus status;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.bookingCode,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.businessId,
    required this.businessName,
    required this.listingId,
    required this.listingTitle,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.items,
    required this.seatIds,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  int get quantity => items.fold<int>(0, (sum, i) => sum + i.quantity);

  String get qrData => 'TICKETHUB:$bookingCode';

  String get ticketTypeSummary =>
      items.map((i) => '${i.typeName} x ${i.quantity}').join(', ');

  bool get isEventPassed {
    final endOfDay = DateTime(eventDate.year, eventDate.month, eventDate.day, 23, 59, 59);
    return endOfDay.isBefore(DateTime.now());
  }

  bool get holdsInventory =>
      status != BookingStatus.cancelled && status != BookingStatus.refunded;

  BookingStatus get effectiveStatus {
    final live = status == BookingStatus.paid || status == BookingStatus.confirmed;
    return live && isEventPassed ? BookingStatus.completed : status;
  }

  bool get isUpcoming =>
      holdsInventory && status != BookingStatus.used && !isEventPassed;

  bool get canCancel =>
      isUpcoming &&
      (status == BookingStatus.pending ||
          status == BookingStatus.confirmed ||
          status == BookingStatus.paid);

  Booking copyWith({BookingStatus? status}) {
    return Booking(
      id: id,
      bookingCode: bookingCode,
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      businessId: businessId,
      businessName: businessName,
      listingId: listingId,
      listingTitle: listingTitle,
      eventDate: eventDate,
      startTime: startTime,
      endTime: endTime,
      location: location,
      items: items,
      seatIds: seatIds,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookingCode': bookingCode,
        'customerId': customerId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'businessId': businessId,
        'businessName': businessName,
        'listingId': listingId,
        'listingTitle': listingTitle,
        'eventDate': eventDate.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'location': location,
        'items': items.map((i) => i.toJson()).toList(),
        'seatIds': seatIds,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      bookingCode: json['bookingCode'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      customerEmail: json['customerEmail'] as String,
      customerPhone: json['customerPhone'] as String,
      businessId: json['businessId'] as String,
      businessName: json['businessName'] as String,
      listingId: json['listingId'] as String,
      listingTitle: json['listingTitle'] as String,
      eventDate: DateTime.parse(json['eventDate'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      location: json['location'] as String,
      items: (json['items'] as List)
          .map((e) => BookingItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      seatIds: List<String>.from(json['seatIds'] as List),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paymentMethod: paymentMethodFromString(json['paymentMethod'] as String),
      status: bookingStatusFromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
