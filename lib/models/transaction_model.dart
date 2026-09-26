import 'profile_model.dart';

class TransactionModel {
  final String id;
  final String userId;
  final int amount;         // موجب = إضافة، سالب = خصم
  final int balanceAfter;   // الرصيد بعد الحركة
  final String type;        // daily_login, purchase, admin_grant...
  final String? reason;     // السبب (نص)
  final String? adminId;    // الأدمن المسؤول (إن وُجد)
  final String? referenceId;// مرجع (صورة، مستخدم آخر...)
  final DateTime createdAt;
  final ProfileModel? admin; // بيانات الأدمن

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.balanceAfter,
    required this.type,
    this.reason,
    this.adminId,
    this.referenceId,
    required this.createdAt,
    this.admin,
  });

  // ═══════════════════════════════════════════════
  // التحويل من JSON
  // ═══════════════════════════════════════════════
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    ProfileModel? adminData;
    
    // Supabase يعيد العلاقة تحت اسم 'admin' أو 'profiles'
    final adminJson = json['admin'] ?? json['profiles'];
    if (adminJson != null && adminJson is Map<String, dynamic>) {
      adminData = ProfileModel.fromJson(adminJson);
    }

    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] ?? 0) as int,
      balanceAfter: (json['balance_after'] ?? 0) as int,
      type: (json['type'] ?? '') as String,
      reason: json['reason'] as String?,
      adminId: json['admin_id'] as String?,
      referenceId: json['reference_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      admin: adminData,
    );
  }

  // ═══════════════════════════════════════════════
  // التحويل إلى JSON (للإرسال)
  // ═══════════════════════════════════════════════
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'balance_after': balanceAfter,
      'type': type,
      'reason': reason,
      'admin_id': adminId,
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ═══════════════════════════════════════════════
  // خصائص مساعدة
  // ═══════════════════════════════════════════════

  /// هل الحركة إضافة (موجبة)؟
  bool get isCredit => amount > 0;

  /// هل الحركة خصم (سالبة)؟
  bool get isDebit => amount < 0;

  /// المبلغ كقيمة مطلقة (لعرض الحجم فقط)
  int get absAmount => amount.abs();

  /// هل الحركة من أدمن؟
  bool get isAdminAction => adminId != null;

  /// نص الرصيد المُنسّق (+500 / -200)
  String get amountLabel => isCredit ? '+$amount' : '$amount';
}
