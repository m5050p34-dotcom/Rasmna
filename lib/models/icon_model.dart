// ═══════════════════════════════════════════════════════════
// 🎨 موديلات متجر الأيقونات
// ═══════════════════════════════════════════════════════════

/// أيقونة معروضة في المتجر (يديرها الأدمن)
class IconModel {
  final String id;
  final String name;
  final String? description;
  final String imageUrl;
  final int price;
  final int durationDays;
  final bool isActive;
  final int displayOrder;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  IconModel({
    required this.id,
    required this.name,
    this.description,
    required this.imageUrl,
    required this.price,
    this.durationDays = 30,
    this.isActive = true,
    this.displayOrder = 0,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IconModel.fromJson(Map<String, dynamic> json) {
    return IconModel(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      imageUrl: (json['image_url'] ?? '') as String,
      price: (json['price'] ?? 0) as int,
      durationDays: (json['duration_days'] ?? 30) as int,
      isActive: (json['is_active'] ?? true) as bool,
      displayOrder: (json['display_order'] ?? 0) as int,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'price': price,
        'duration_days': durationDays,
        'is_active': isActive,
        'display_order': displayOrder,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// نسخة معدّلة للإنشاء (بدون id وتواريخ)
  Map<String, dynamic> toInsertJson() => {
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'price': price,
        'duration_days': durationDays,
        'is_active': isActive,
        'display_order': displayOrder,
      };

  IconModel copyWith({
    String? name,
    String? description,
    String? imageUrl,
    int? price,
    int? durationDays,
    bool? isActive,
    int? displayOrder,
  }) {
    return IconModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      durationDays: durationDays ?? this.durationDays,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// سجل شراء المستخدم لأيقونة معينة
// ═══════════════════════════════════════════════════════════
class UserIconModel {
  final String id;
  final String userId;
  final String iconId;
  final int pricePaid;
  final DateTime purchasedAt;
  final DateTime expiresAt;
  final bool isActive;

  // بيانات الأيقونة (من JOIN اختياري)
  final IconModel? icon;

  UserIconModel({
    required this.id,
    required this.userId,
    required this.iconId,
    required this.pricePaid,
    required this.purchasedAt,
    required this.expiresAt,
    required this.isActive,
    this.icon,
  });

  factory UserIconModel.fromJson(Map<String, dynamic> json) {
    return UserIconModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      iconId: json['icon_id'] as String,
      pricePaid: (json['price_paid'] ?? 0) as int,
      purchasedAt: json['purchased_at'] != null
          ? DateTime.parse(json['purchased_at'] as String)
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now(),
      isActive: (json['is_active'] ?? true) as bool,
      // إذا كان الاستعلام يحتوي JOIN على icons
      icon: json['icons'] != null
          ? IconModel.fromJson(json['icons'] as Map<String, dynamic>)
          : null,
    );
  }

  /// هل السجل لا يزال فعّالاً (الآن)؟
  bool get isCurrentlyValid =>
      isActive && expiresAt.isAfter(DateTime.now());

  /// عدد الأيام المتبقية
  int get daysRemaining {
    final diff = expiresAt.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}

// ═══════════════════════════════════════════════════════════
// نتيجة عملية الشراء (تُعاد من RPC purchase_icon)
// ═══════════════════════════════════════════════════════════
class PurchaseIconResult {
  final bool success;
  final String iconId;
  final String iconName;
  final int pricePaid;
  final DateTime expiresAt;
  final int newBalance;

  PurchaseIconResult({
    required this.success,
    required this.iconId,
    required this.iconName,
    required this.pricePaid,
    required this.expiresAt,
    required this.newBalance,
  });

  factory PurchaseIconResult.fromJson(Map<String, dynamic> json) {
    return PurchaseIconResult(
      success: (json['success'] ?? false) as bool,
      iconId: (json['icon_id'] ?? '') as String,
      iconName: (json['icon_name'] ?? '') as String,
      pricePaid: (json['price_paid'] ?? 0) as int,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now(),
      newBalance: (json['new_balance'] ?? 0) as int,
    );
  }
}
