class SortOptionModel {
  final String id;
  final String key;
  final String labelAr;
  final String labelEn;
  final bool enabled;
  final int displayOrder;
  final bool isDefault;
  final DateTime createdAt;

  SortOptionModel({
    required this.id,
    required this.key,
    required this.labelAr,
    required this.labelEn,
    required this.enabled,
    required this.displayOrder,
    required this.isDefault,
    required this.createdAt,
  });

  factory SortOptionModel.fromJson(Map<String, dynamic> json) {
    return SortOptionModel(
      id: json['id'] as String,
      key: json['key'] as String,
      labelAr: (json['label_ar'] ?? '') as String,
      labelEn: (json['label_en'] ?? '') as String,
      enabled: (json['enabled'] ?? true) as bool,
      displayOrder: (json['display_order'] ?? 0) as int,
      isDefault: (json['is_default'] ?? false) as bool,
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
        'enabled': enabled,
        'display_order': displayOrder,
        'is_default': isDefault,
        'created_at': createdAt.toIso8601String(),
      };

  SortOptionModel copyWith({
    String? key,
    String? labelAr,
    String? labelEn,
    bool? enabled,
    int? displayOrder,
    bool? isDefault,
  }) {
    return SortOptionModel(
      id: id,
      key: key ?? this.key,
      labelAr: labelAr ?? this.labelAr,
      labelEn: labelEn ?? this.labelEn,
      enabled: enabled ?? this.enabled,
      displayOrder: displayOrder ?? this.displayOrder,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
    );
  }

  String label({bool isArabic = true}) => isArabic ? labelAr : labelEn;
}
