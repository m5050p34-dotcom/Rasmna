import 'profile_model.dart';

class CommentModel {
  final String id;
  final String photoId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProfileModel? author;

  CommentModel({
    required this.id,
    required this.photoId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.author,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    ProfileModel? authorData;
    final authorJson = json['profiles'] ?? json['author'];
    if (authorJson != null && authorJson is Map<String, dynamic>) {
      authorData = ProfileModel.fromJson(authorJson);
    }

    return CommentModel(
      id: json['id'] as String,
      photoId: json['photo_id'] as String,
      userId: json['user_id'] as String,
      content: (json['content'] ?? '') as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      author: authorData,
    );
  }

  bool get isEdited => updatedAt.difference(createdAt).inSeconds > 5;
}
