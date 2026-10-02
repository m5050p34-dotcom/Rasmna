import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/photo_model.dart';
import '../models/profile_model.dart';
import '../utils/constants.dart';
import 'points_service.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PointsService _pointsService = PointsService();
  final _uuid = const Uuid();

  Future<ProfileModel> getProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(response);
  }

  Future<List<ProfileModel>> getAllProfiles({
    String? searchQuery,
    bool onlyAdmins = false,
    bool onlyBanned = false,
  }) async {
    var query = _supabase.from('profiles').select();
    if (onlyAdmins) query = query.eq('is_admin', true);
    if (onlyBanned) query = query.eq('is_banned', true);
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or(
        'username.ilike.%$searchQuery%,email.ilike.%$searchQuery%',
      );
    }
    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await _supabase.from('profiles').update(updates).eq('id', userId);
  }

  Future<String> uploadAvatarFile(String userId, File file) async {
    final fileName = '$userId/avatar_${_uuid.v4()}.jpg';
    await _supabase.storage.from('avatars').upload(
          fileName,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return _supabase.storage.from('avatars').getPublicUrl(fileName);
  }

  Future<AvatarChangeResult> changeAvatar({
    required String userId,
    required File file,
  }) async {
    final avatarUrl = await uploadAvatarFile(userId, file);
    final response = await _supabase.rpc(
      'change_avatar',
      params: {
        'p_user_id': userId,
        'p_new_avatar_url': avatarUrl,
      },
    );
    final data = response as Map<String, dynamic>;
    return AvatarChangeResult(
      changed: data['changed'] as bool? ?? true,
      pointsSpent: (data['points_spent'] as num?)?.toInt() ?? 0,
      newBalance: (data['new_balance'] as num?)?.toInt() ?? 0,
    );
  }

  Future<UsernameChangeResult> changeUsername({
    required String userId,
    required String newUsername,
  }) async {
    try {
      final response = await _supabase.rpc(
        'change_username',
        params: {
          'p_user_id': userId,
          'p_new_username': newUsername,
        },
      );
      final data = response as Map<String, dynamic>;
      return UsernameChangeResult(
        changed: data['changed'] as bool? ?? false,
        pointsSpent: (data['points_spent'] as num?)?.toInt() ?? 0,
        newBalance: (data['new_balance'] as num?)?.toInt() ?? 0,
      );
    } on PostgrestException catch (e) {
      if (e.message.contains('Insufficient points')) {
        throw Exception('رصيدك غير كافٍ. تحتاج 50 نقطة');
      }
      if (e.message.contains('too short')) {
        throw Exception('الاسم قصير جداً (3 أحرف على الأقل)');
      }
      if (e.message.contains('too long')) {
        throw Exception('الاسم طويل جداً (50 حرفاً كحد أقصى)');
      }
      rethrow;
    }
  }

  Future<DailyRewardResult> claimDailyReward(String userId) async {
    final profile = await getProfile(userId);
    final now = DateTime.now();

    if (profile.lastLoginDate != null) {
      final last = profile.lastLoginDate!;
      final sameDay = now.year == last.year &&
          now.month == last.month &&
          now.day == last.day;
      if (sameDay) {
        throw Exception('لقد استلمت مكافأة اليوم بالفعل');
      }
    }

    int newStreak;
    int earnedPoints;

    if (profile.lastLoginDate == null) {
      newStreak = 1;
      earnedPoints = 10;
    } else {
      final nowDate = DateTime(now.year, now.month, now.day);
      final lastDate = DateTime(
        profile.lastLoginDate!.year,
        profile.lastLoginDate!.month,
        profile.lastLoginDate!.day,
      );
      final diffInDays = nowDate.difference(lastDate).inDays;

      if (diffInDays == 1) {
        final next = profile.loginStreak + 1;
        if (next > 7) {
          newStreak = 1;
          earnedPoints = 10;
        } else {
          newStreak = next;
          earnedPoints = next * 10;
        }
      } else {
        newStreak = 1;
        earnedPoints = 10;
      }
    }

    final isWeekComplete = newStreak == 7;

    await _pointsService.addPoints(
      userId: userId,
      amount: earnedPoints,
      type: AppConstants.txDailyLogin,
      reason: 'مكافأة اليوم $newStreak من 7',
    );

    await _supabase.from('profiles').update({
      'login_streak': isWeekComplete ? 0 : newStreak,
      'last_login_date': now.toIso8601String(),
    }).eq('id', userId);

    return DailyRewardResult(
      earnedPoints: earnedPoints,
      day: newStreak,
      isWeekComplete: isWeekComplete,
      newTotalPoints: profile.points + earnedPoints,
    );
  }

  // ═══════════════════════════════════════════════
  // 🚫 حظر مستخدم (مع السبب)
  // ═══════════════════════════════════════════════
  Future<void> setBanned(String userId, bool banned, {String? reason}) async {
    if (banned) {
      final r = reason?.trim() ?? '';
      if (r.isEmpty) {
        throw Exception('يجب إدخال سبب الحظر');
      }

      try {
        await _supabase.rpc(
          'ban_user',
          params: {
            'p_user_id': userId,
            'p_reason': r,
          },
        );
      } on PostgrestException catch (e) {
        final msg = e.message;
        if (msg.contains('Cannot ban yourself')) {
          throw Exception('لا يمكنك حظر نفسك');
        }
        if (msg.contains('Admin only')) {
          throw Exception('هذه العملية للأدمن فقط');
        }
        if (msg.contains('User not found')) {
          throw Exception('المستخدم غير موجود');
        }
        rethrow;
      }
    } else {
      try {
        await _supabase.rpc(
          'unban_user',
          params: {'p_user_id': userId},
        );
      } on PostgrestException catch (e) {
        if (e.message.contains('Admin only')) {
          throw Exception('هذه العملية للأدمن فقط');
        }
        rethrow;
      }
    }
  }

  Future<void> setAdmin(String userId, bool isAdmin) async {
    await _supabase
        .from('profiles')
        .update({'is_admin': isAdmin}).eq('id', userId);
  }

  Future<Map<String, int>> getStats() async {
    final profiles = await _supabase.from('profiles').select('id, points');
    final photos = await _supabase.from('photos').select('id');
    final profilesList = profiles as List;
    final totalPoints = profilesList.fold<int>(
      0,
      (sum, p) => sum + ((p['points'] ?? 0) as int),
    );
    return {
      'total_users': profilesList.length,
      'total_photos': (photos as List).length,
      'total_points': totalPoints,
    };
  }

  Future<List<PhotoModel>> getPhotographerPhotos(String userId) async {
    final response = await _supabase
        .from('photos')
        .select(
          '*, profiles:user_id(id, username, email, avatar_url, is_admin)',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => PhotoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════
  // 📧 تغيير البريد (مع كلمة المرور — فوري)
  // ═══════════════════════════════════════════════
  Future<void> changeMyEmailWithPassword({
    required String currentEmail,
    required String password,
    required String newEmail,
  }) async {
    // 1) التحقق من كلمة المرور بمحاولة تسجيل دخول
    try {
      await _supabase.auth.signInWithPassword(
        email: currentEmail,
        password: password,
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid')) {
        throw Exception('كلمة المرور غير صحيحة');
      }
      rethrow;
    }

    // 2) تحديث البريد (فوري بدون تأكيد إذا كان معطلاً)
    try {
      await _supabase.auth.updateUser(
        UserAttributes(email: newEmail.trim()),
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already') || msg.contains('registered')) {
        throw Exception('هذا البريد مسجل بالفعل');
      }
      if (msg.contains('invalid') || msg.contains('email')) {
        throw Exception('صيغة البريد غير صحيحة');
      }
      rethrow;
    }

    // 3) مزامنة البريد في جدول profiles يدوياً كاحتياط
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _supabase
          .from('profiles')
          .update({'email': newEmail.trim()})
          .eq('id', userId);
    }
  }

  // ═══════════════════════════════════════════════
  // 📧 تغيير البريد (للأدمن — فوري)
  // ═══════════════════════════════════════════════
  Future<void> adminChangeEmail({
    required String userId,
    required String newEmail,
  }) async {
    final response = await _supabase.functions.invoke(
      'admin-change-email',
      body: {
        'user_id': userId,
        'new_email': newEmail.trim(),
      },
    );

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'فشل تغيير البريد';
      throw Exception(error);
    }
  }
}

// ═══════════════════════════════════════════════
// نماذج النتائج
// ═══════════════════════════════════════════════
class DailyRewardResult {
  final int earnedPoints;
  final int day;
  final bool isWeekComplete;
  final int newTotalPoints;
  DailyRewardResult({
    required this.earnedPoints,
    required this.day,
    required this.isWeekComplete,
    required this.newTotalPoints,
  });
}

class UsernameChangeResult {
  final bool changed;
  final int pointsSpent;
  final int newBalance;
  UsernameChangeResult({
    required this.changed,
    required this.pointsSpent,
    required this.newBalance,
  });
}

class AvatarChangeResult {
  final bool changed;
  final int pointsSpent;
  final int newBalance;
  AvatarChangeResult({
    required this.changed,
    required this.pointsSpent,
    required this.newBalance,
  });
}
