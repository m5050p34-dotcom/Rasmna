class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        type: (json['type'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        body: (json['body'] ?? '') as String,
        data: json['data'] as Map<String, dynamic>?,
        isRead: (json['is_read'] ?? false) as bool,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  static const String typeSale = 'sale';
  static const String typePurchase = 'purchase';
  static const String typeComment = 'comment';
  static const String typeRating = 'rating';
  static const String typeFollow = 'follow';
  static const String typeFavorite = 'favorite';
  static const String typeDailyReward = 'daily_reward';
  static const String typeAdminGrant = 'admin_grant';
  static const String typeSystem = 'system';
}
