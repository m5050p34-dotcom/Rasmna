import 'photo_model.dart';
import 'profile_model.dart';

class ReportModel {
  final String id;
  final String photoId;
  final String reporterId;
  final String reason;
  final String? details;
  final String status;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? adminNotes;
  final DateTime createdAt;
  final PhotoModel? photo;
  final ProfileModel? reporter;

  ReportModel({
    required this.id,
    required this.photoId,
    required this.reporterId,
    required this.reason,
    this.details,
    required this.status,
    this.resolvedBy,
    this.resolvedAt,
    this.adminNotes,
    required this.createdAt,
    this.photo,
    this.reporter,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    PhotoModel? photoData;
    ProfileModel? reporterData;

    final photoJson = json['photos'];
    if (photoJson != null && photoJson is Map<String, dynamic>) {
      photoData = PhotoModel.fromJson(photoJson);
    }

    final reporterJson = json['reporter'];
    if (reporterJson != null && reporterJson is Map<String, dynamic>) {
      reporterData = ProfileModel.fromJson(reporterJson);
    }

    return ReportModel(
      id: json['id'] as String,
      photoId: json['photo_id'] as String,
      reporterId: json['reporter_id'] as String,
      reason: (json['reason'] ?? '') as String,
      details: json['details'] as String?,
      status: (json['status'] ?? 'pending') as String,
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      adminNotes: json['admin_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      photo: photoData,
      reporter: reporterData,
    );
  }

  bool get isPending => status == 'pending';
  bool get isResolved => status == 'resolved';
  bool get isDismissed => status == 'dismissed';
}
