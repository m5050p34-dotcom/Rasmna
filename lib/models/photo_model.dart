import 'profile_model.dart';

class PhotoModel {
  final String id;
  final String userId;
  final String title;
  final String category;
  final double price;
  final String imageUrl;
  final String format;
  final DateTime createdAt;
  final ProfileModel? owner; // بيانات صاحب الصورة

  PhotoModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.format,
    required this.createdAt,
    this.owner,
  });

  // ═══════════════════════════════════════════════
  // التحويل من JSON
  // ═══════════════════════════════════════════════
  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    ProfileModel? ownerData;
    
    // Supabase يعيد العلاقة تحت اسم 'profiles' عند استخدام join
    final ownerJson = json['profiles'];
    if (ownerJson != null && ownerJson is Map<String, dynamic>) {
      ownerData = ProfileModel.fromJson(ownerJson);
    }

    return PhotoModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: (json['title'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      price: json['price'] != null
          ? (json['price'] as num).toDouble()
          : 0.0,
      imageUrl: (json['image_url'] ?? '') as String,
      format: (json['format'] ?? 'jpg') as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      owner: ownerData,
    );
  }

  // ═══════════════════════════════════════════════
  // التحويل إلى JSON (بدون owner لتجنب مشاكل الإدراج)
  // ═══════════════════════════════════════════════
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'category': category,
      'price': price,
      'image_url': imageUrl,
      'format': format,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ═══════════════════════════════════════════════
  // نسخ الكائن مع تعديل حقول محددة
  // ═══════════════════════════════════════════════
  PhotoModel copyWith({
    String? title,
    String? category,
    double? price,
    String? imageUrl,
    String? format,
    ProfileModel? owner,
  }) {
    return PhotoModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      format: format ?? this.format,
      createdAt: createdAt,
      owner: owner ?? this.owner,
    );
  }

  // ═══════════════════════════════════════════════
  // خصائص مساعدة
  // ═══════════════════════════════════════════════

  /// هل الصورة مجانية؟
  bool get isFree => price == 0;

  /// اسم صاحب الصورة (أو "مجهول")
  String get ownerName => owner?.username ?? 'Unknown';

  /// الحرف الأول من اسم صاحب الصورة
  String get ownerInitial => owner?.initial ?? '?';
}
