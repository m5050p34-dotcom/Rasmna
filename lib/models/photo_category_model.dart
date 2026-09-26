class PhotoCategoryModel {
  final String id;
  final String key;
  final String labelAr;
  final String labelEn;
  final String? iconName;
  final bool enabled;
  final int displayOrder;
  final DateTime createdAt;

  PhotoCategoryModel({
    required this.id,
    required this.key,
    required this.labelAr,
    required this.labelEn,
    this.iconName,
    required this.enabled,
    required this.displayOrder,
    required this.createdAt,
  });

  factory PhotoCategoryModel.fromJson(Map<String, dynamic> json) {
    return PhotoCategoryModel(
      id: json['id'] as String,
      key: json['key'] as String,
      labelAr: (json['label_ar'] ?? '') as String,
      labelEn: (json['label_en'] ?? '') as String,
      iconName: json['icon_name'] as String?,
      enabled: (json['enabled'] ?? true) as bool,
      displayOrder: (json['display_order'] ?? 0) as int,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'label_ar': labelAr,
        'label_en': labelEn,
        'icon_name': iconName,
        'enabled': enabled,
        'display_order': displayOrder,
      };

  String label({bool isArabic = true}) => isArabic ? labelAr : labelEn;
}
