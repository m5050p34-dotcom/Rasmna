import 'photo_model.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  final String? title;
  final String? linkPhotoId;
  final String? linkUrl;         // 🆕 رابط خارجي
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final PhotoModel? linkedPhoto;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.linkPhotoId,
    this.linkUrl,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    this.linkedPhoto,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    PhotoModel? photoData;
    final photoJson = json['photos'];
    if (photoJson != null && photoJson is Map<String, dynamic>) {
      photoData = PhotoModel.fromJson(photoJson);
    }

    return BannerModel(
      id: json['id'] as String,
      imageUrl: (json['image_url'] ?? '') as String,
      title: json['title'] as String?,
      linkPhotoId: json['link_photo_id'] as String?,
      linkUrl: json['link_url'] as String?,     // 🆕
      displayOrder: (json['display_order'] ?? 0) as int,
      isActive: (json['is_active'] ?? true) as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      linkedPhoto: photoData,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'image_url': imageUrl,
        'title': title,
        'link_photo_id': linkPhotoId,
        'link_url': linkUrl,                    // 🆕
        'display_order': displayOrder,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  BannerModel copyWith({
    String? imageUrl,
    String? title,
    String? linkPhotoId,
    String? linkUrl,
    int? displayOrder,
    bool? isActive,
  }) {
    return BannerModel(
      id: id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      linkPhotoId: linkPhotoId ?? this.linkPhotoId,
      linkUrl: linkUrl ?? this.linkUrl,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      linkedPhoto: linkedPhoto,
    );
  }

  /// هل للبانر رابط للفتح؟
  bool get hasLink =>
      (linkUrl != null && linkUrl!.trim().isNotEmpty) || linkedPhoto != null;

  /// هل الرابط الخارجي صالح؟
  bool get hasValidExternalLink {
    if (linkUrl == null || linkUrl!.trim().isEmpty) return false;
    final url = linkUrl!.trim().toLowerCase();
    return url.startsWith('http://') || url.startsWith('https://');
  }
}
