import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';

class PointsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════
  // ➕ إضافة/خصم نقاط
  // ═══════════════════════════════════════════════
  Future<int> addPoints({
    required String userId,
    required int amount,
    required String type,
    String? reason,
    String? referenceId,
  }) async {
    final response = await _supabase.rpc(
      'add_points',
      params: {
        'p_user_id': userId,
        'p_amount': amount,
        'p_type': type,
        'p_reason': reason,
        'p_reference_id': referenceId,
      },
    );
    return response as int;
  }

  // ═══════════════════════════════════════════════
  // 🎯 تعيين الرصيد (للأدمن)
  // ═══════════════════════════════════════════════
  Future<int> setUserPoints({
    required String userId,
    required int newValue,
    String? reason,
  }) async {
    final response = await _supabase.rpc(
      'set_user_points',
      params: {
        'p_user_id': userId,
        'p_new_value': newValue,
        'p_reason': reason,
      },
    );
    return response as int;
  }

  // ═══════════════════════════════════════════════
  // 🎁 تحويل النقاط (هدية)
  // ═══════════════════════════════════════════════
  Future<TransferResult> transferPoints({
    required String recipientId,
    required int amount,
    String? message,
  }) async {
    try {
      final response = await _supabase.rpc(
        'transfer_points',
        params: {
          'p_recipient_id': recipientId,
          'p_amount': amount,
          'p_message': message,
        },
      );

      final data = response as Map<String, dynamic>;
      return TransferResult(
        success: data['success'] as bool? ?? false,
        sentAmount: (data['sent_amount'] as num?)?.toInt() ?? 0,
        recipientReceived: (data['recipient_received'] as num?)?.toInt() ?? 0,
        commission: (data['commission'] as num?)?.toInt() ?? 0,
        newSenderBalance: (data['new_sender_balance'] as num?)?.toInt() ?? 0,
        newRecipientBalance:
            (data['new_recipient_balance'] as num?)?.toInt() ?? 0,
      );
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('insufficient points')) {
        throw Exception('رصيدك غير كافٍ');
      }
      if (msg.contains('minimum transfer')) {
        throw Exception('الحد الأدنى للتحويل 20 نقطة');
      }
      if (msg.contains('yourself')) {
        throw Exception('لا يمكنك التحويل لنفسك');
      }
      if (msg.contains('not authenticated')) {
        throw Exception('يجب تسجيل الدخول');
      }
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════
  // 📜 سجل الحركات
  // ═══════════════════════════════════════════════
  Future<List<TransactionModel>> getUserTransactions(
    String userId, {
    int limit = 50,
  }) async {
    final response = await _supabase
        .from('points_transactions')
        .select('*, admin:admin_id(id, username, email, points, is_admin)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TransactionModel>> getAllTransactions({
    int limit = 100,
    String? filterType,
    String? filterUserId,
  }) async {
    var query = _supabase
        .from('points_transactions')
        .select('*, admin:admin_id(id, username, email, points, is_admin)');

    if (filterType != null && filterType.isNotEmpty) {
      query = query.eq('type', filterType);
    }
    if (filterUserId != null && filterUserId.isNotEmpty) {
      query = query.eq('user_id', filterUserId);
    }

    final response =
        await query.order('created_at', ascending: false).limit(limit);

    return (response as List)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Stream<List<Map<String, dynamic>>> streamUserTransactions(
    String userId,
  ) {
    return _supabase
        .from('points_transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((list) => list.reversed.toList());
  }
}

// ═══════════════════════════════════════════════
// نموذج نتيجة التحويل
// ═══════════════════════════════════════════════
class TransferResult {
  final bool success;
  final int sentAmount;
  final int recipientReceived;
  final int commission;
  final int newSenderBalance;
  final int newRecipientBalance;

  TransferResult({
    required this.success,
    required this.sentAmount,
    required this.recipientReceived,
    required this.commission,
    required this.newSenderBalance,
    required this.newRecipientBalance,
  });
}
