import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════
  // خصائص سريعة
  // ═══════════════════════════════════════════════
  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isAuthenticated => currentUser != null;
  String? get currentUserId => currentUser?.id;
  String? get currentEmail => currentUser?.email;

  Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  // ═══════════════════════════════════════════════
  // إنشاء حساب
  // ═══════════════════════════════════════════════
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    return await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'username': username.trim()},
    );
  }

  // ═══════════════════════════════════════════════
  // تسجيل الدخول
  // ═══════════════════════════════════════════════
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ═══════════════════════════════════════════════
  // تسجيل الخروج
  // ═══════════════════════════════════════════════
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ═══════════════════════════════════════════════
  // إعادة تعيين كلمة المرور
  // ═══════════════════════════════════════════════
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email.trim());
  }

  // ═══════════════════════════════════════════════
  // تحديث كلمة المرور
  // ═══════════════════════════════════════════════
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // ═══════════════════════════════════════════════
  // 📧 تحديث البريد الإلكتروني
  // ═══════════════════════════════════════════════
  // ⚠️ Supabase سيرسل رسالة تأكيد للبريد الجديد
  //    يتغير البريد بعد الضغط على رابط التأكيد
  Future<void> updateEmail(String newEmail) async {
    await _supabase.auth.updateUser(
      UserAttributes(email: newEmail.trim()),
    );
  }
}
