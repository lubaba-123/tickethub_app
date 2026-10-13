class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? refKey;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.refKey,
  });

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      createdAt: createdAt,
      read: read ?? this.read,
      refKey: refKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
        'refKey': refKey,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      read: json['read'] as bool,
      refKey: json['refKey'] as String?,
    );
  }
}
