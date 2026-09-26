import 'photo_model.dart';

class FeaturedPhotoModel {
  final String id;
  final String photoId;
  final int displayOrder;
  final String? addedBy;
  final DateTime createdAt;
  final PhotoModel? photo;

  FeaturedPhotoModel({
    required this.id,
    required this.photoId,
    required this.displayOrder,
    this.addedBy,
    required this.createdAt,
    this.photo,
  });

  factory FeaturedPhotoModel.fromJson(Map<String, dynamic> json) {
    PhotoModel? photoData;
    final photoJson = json['photos'];
    if (photoJson != null && photoJson is Map<String, dynamic>) {
      photoData = PhotoModel.fromJson(photoJson);
    }

    return FeaturedPhotoModel(
      id: json['id'] as String,
      photoId: json['photo_id'] as String,
      displayOrder: (json['display_order'] ?? 0) as int,
      addedBy: json['added_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      photo: photoData,
    );
  }
}
