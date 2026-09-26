class SupabaseConfig {
  // ═══════════════════════════════════════════════
  // إعدادات الاتصال بـ Supabase
  // ═══════════════════════════════════════════════
  static const String supabaseUrl = 'https://uoztuhreqmxkfmmwcnzw.supabase.co';
  static const String supabasePublishableKey =
      'sb_publishable_SQghctHNqqs4FJ7O6-nSCA_7sUO7kNO';

  // ═══════════════════════════════════════════════
  // أسماء الجداول (لتجنب الأخطاء الإملائية)
  // ═══════════════════════════════════════════════
  static const String profilesTable = 'profiles';
  static const String photosTable = 'photos';
  static const String transactionsTable = 'points_transactions';
  static const String photosBucket = 'photos';

  // ═══════════════════════════════════════════════
  // إعدادات المكافأة اليومية
  // ═══════════════════════════════════════════════
  static const int dailyRewardBase = 20;       // اليوم الأول
  static const int dailyRewardIncrement = 30;  // الزيادة اليومية
  static const int dailyRewardMax = 200;       // اليوم السابع
}
