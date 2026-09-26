class RatingModel {
  final String id;
  final String photoId;
  final String userId;
  final int rating;
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.photoId,
    required this.userId,
    required this.rating,
    required this.createdAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) => RatingModel(
        id: json['id'] as String,
        photoId: json['photo_id'] as String,
        userId: json['user_id'] as String,
        rating: (json['rating'] ?? 0) as int,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}

class PhotoStats {
  final double avgRating;
  final int ratingsCount;
  final int commentsCount;
  final int favoritesCount;
  final bool isFavorited;
  final int? userRating;

  PhotoStats({
    required this.avgRating,
    required this.ratingsCount,
    required this.commentsCount,
    required this.favoritesCount,
    required this.isFavorited,
    this.userRating,
  });

  factory PhotoStats.fromJson(Map<String, dynamic> json) => PhotoStats(
        avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
        ratingsCount: (json['ratings_count'] ?? 0) as int,
        commentsCount: (json['comments_count'] ?? 0) as int,
        favoritesCount: (json['favorites_count'] ?? 0) as int,
        isFavorited: (json['is_favorited'] ?? false) as bool,
        userRating: json['user_rating'] as int?,
      );

  static PhotoStats empty() => PhotoStats(
        avgRating: 0,
        ratingsCount: 0,
        commentsCount: 0,
        favoritesCount: 0,
        isFavorited: false,
        userRating: null,
      );
}

class PhotographerStats {
  final int photosCount;
  final int followersCount;
  final int followingCount;
  final int totalSales;
  final bool isFollowing;

  PhotographerStats({
    required this.photosCount,
    required this.followersCount,
    required this.followingCount,
    required this.totalSales,
    required this.isFollowing,
  });

  factory PhotographerStats.fromJson(Map<String, dynamic> json) =>
      PhotographerStats(
        photosCount: (json['photos_count'] ?? 0) as int,
        followersCount: (json['followers_count'] ?? 0) as int,
        followingCount: (json['following_count'] ?? 0) as int,
        totalSales: (json['total_sales'] ?? 0) as int,
        isFollowing: (json['is_following'] ?? false) as bool,
      );

  static PhotographerStats empty() => PhotographerStats(
        photosCount: 0,
        followersCount: 0,
        followingCount: 0,
        totalSales: 0,
        isFollowing: false,
      );
}
