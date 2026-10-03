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
  final ProfileModel? owner;
  final String? groupId;
  final int groupOrder;
  final bool isGroupCover;

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
    this.groupId,
    this.groupOrder = 0,
    this.isGroupCover = true,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    ProfileModel? ownerData;
    final ownerJson = json['profiles'];
    if (ownerJson != null && ownerJson is Map<String, dynamic>) {
      ownerData = ProfileModel.fromJson(ownerJson);
    }
    return PhotoModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: (json['title'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      imageUrl: (json['image_url'] ?? '') as String,
      format: (json['format'] ?? 'jpg') as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      owner: ownerData,
      groupId: json['group_id'] as String?,
      groupOrder: (json['group_order'] ?? 0) as int,
      isGroupCover: (json['is_group_cover'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'category': category,
        'price': price,
        'image_url': imageUrl,
        'format': format,
        'created_at': createdAt.toIso8601String(),
        'group_id': groupId,
        'group_order': groupOrder,
        'is_group_cover': isGroupCover,
      };

  PhotoModel copyWith({
    String? title,
    String? category,
    double? price,
    String? imageUrl,
    String? format,
    ProfileModel? owner,
    String? groupId,
    int? groupOrder,
    bool? isGroupCover,
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
      groupId: groupId ?? this.groupId,
      groupOrder: groupOrder ?? this.groupOrder,
      isGroupCover: isGroupCover ?? this.isGroupCover,
    );
  }

  bool get isFree => price == 0;
  String get ownerName => owner?.username ?? 'Unknown';
  String get ownerInitial => owner?.initial ?? '?';
  bool get isPartOfGroup => groupId != null && groupId!.isNotEmpty;
}

class PhotoGroup {
  final String id;
  final List<PhotoModel> images;

  PhotoGroup({required this.id, required this.images});

  PhotoModel get cover => images.firstWhere(
        (p) => p.isGroupCover,
        orElse: () => images.first,
      );

  String get title => cover.title;
  double get price => cover.price;
  String get category => cover.category;
  int get count => images.length;
  bool get isMulti => images.length > 1;

  factory PhotoGroup.single(PhotoModel photo) =>
      PhotoGroup(id: photo.id, images: [photo]);
}
