class AppVersionModel {
  final String id;
  final String versionName;
  final int versionCode;
  final String changelog;
  final String downloadUrl;
  final bool isMandatory;
  final bool isActive;
  final DateTime createdAt;

  AppVersionModel({
    required this.id,
    required this.versionName,
    required this.versionCode,
    required this.changelog,
    required this.downloadUrl,
    required this.isMandatory,
    required this.isActive,
    required this.createdAt,
  });

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      id: json['id'] as String,
      versionName: (json['version_name'] ?? '') as String,
      versionCode: (json['version_code'] ?? 0) as int,
      changelog: (json['changelog'] ?? '') as String,
      downloadUrl: (json['download_url'] ?? '') as String,
      isMandatory: (json['is_mandatory'] ?? false) as bool,
      isActive: (json['is_active'] ?? true) as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'version_name': versionName,
        'version_code': versionCode,
        'changelog': changelog,
        'download_url': downloadUrl,
        'is_mandatory': isMandatory,
        'is_active': isActive,
      };

  AppVersionModel copyWith({
    String? versionName,
    int? versionCode,
    String? changelog,
    String? downloadUrl,
    bool? isMandatory,
    bool? isActive,
  }) {
    return AppVersionModel(
      id: id,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      changelog: changelog ?? this.changelog,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      isMandatory: isMandatory ?? this.isMandatory,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
