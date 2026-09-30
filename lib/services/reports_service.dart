import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_model.dart';

class ReportsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════
  // إرسال بلاغ
  // ═══════════════════════════════════════════════
  Future<void> submitReport({
    required String photoId,
    required String reason,
    String? details,
  }) async {
    await _supabase.rpc('submit_report', params: {
      'p_photo_id': photoId,
      'p_reason': reason,
      'p_details': details,
    });
  }

  // ═══════════════════════════════════════════════
  // هل أبلغ المستخدم عن هذه الصورة؟
  // ═══════════════════════════════════════════════
  Future<bool> hasReported(String photoId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final result = await _supabase
          .from('reports')
          .select('id')
          .eq('photo_id', photoId)
          .eq('reporter_id', userId)
          .maybeSingle();
      return result != null;
    } catch (_) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════
  // جلب كل البلاغات (للأدمن)
  // ═══════════════════════════════════════════════
  Future<List<ReportModel>> getAllReports({
    String? filterStatus,
  }) async {
    var query = _supabase.from('reports').select(
          '*, '
          'photos:photo_id(*, profiles:user_id(id, username, email, avatar_url, is_admin)), '
          'reporter:reporter_id(id, username, email, avatar_url, is_admin)',
        );

    if (filterStatus != null && filterStatus != 'all') {
      query = query.eq('status', filterStatus);
    }

    final response =
        await query.order('created_at', ascending: false);

    return (response as List)
        .map((e) => ReportModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════
  // تحديث حالة البلاغ (للأدمن)
  // ═══════════════════════════════════════════════
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    String? adminNotes,
  }) async {
    await _supabase.from('reports').update({
      'status': status,
      'resolved_by': _supabase.auth.currentUser?.id,
      'resolved_at': DateTime.now().toIso8601String(),
      'admin_notes': adminNotes,
    }).eq('id', reportId);
  }

  // ═══════════════════════════════════════════════
  // عدد البلاغات المعلقة
  // ═══════════════════════════════════════════════
  Future<int> getPendingCount() async {
    try {
      final response = await _supabase
          .from('reports')
          .select('id')
          .eq('status', 'pending');
      return (response as List).length;
    } catch (_) {
      return 0;
    }
  }

  // ═══════════════════════════════════════════════
  // Realtime
  // ═══════════════════════════════════════════════
  Stream<List<Map<String, dynamic>>> streamAllReports() {
    return _supabase
        .from('reports')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((list) => list.reversed.toList());
  }
}
