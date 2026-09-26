class AppConstants {
  static const List<Map<String, String>> photoCategories = [
    {'key': 'all', 'ar': 'الكل', 'en': 'All'},
    {'key': 'nature', 'ar': 'طبيعة', 'en': 'Nature'},
    {'key': 'cities', 'ar': 'مدن', 'en': 'Cities'},
    {'key': 'portrait', 'ar': 'بورتريه', 'en': 'Portrait'},
    {'key': 'abstract', 'ar': 'تجريدي', 'en': 'Abstract'},
    {'key': 'sports', 'ar': 'رياضة', 'en': 'Sports'},
    {'key': 'animals', 'ar': 'حيوانات', 'en': 'Animals'},
  ];

  static const String txDailyLogin = 'daily_login';
  static const String txPurchase = 'purchase';
  static const String txSale = 'sale';
  static const String txAdminGrant = 'admin_grant';
  static const String txAdminDeduct = 'admin_deduct';
  static const String txAdminSet = 'admin_set';
  static const String txWelcomeBonus = 'welcome_bonus';
  static const String txRefund = 'refund';
  static const String txPenalty = 'penalty';
  static const String txUsernameChange = 'username_change';
  static const String txAvatarChange = 'avatar_change';
  static const String txPlatformCommission = 'platform_commission';
  static const String txUsernameChangeFee = 'username_change_fee';
  static const String txAvatarChangeFee = 'avatar_change_fee';
  static const String txTransferSent = 'transfer_sent';
  static const String txTransferReceived = 'transfer_received';
  static const String txTransferCommission = 'transfer_commission';

  static const Map<String, Map<String, String>> txLabels = {
    txDailyLogin: {'ar': 'مكافأة يومية', 'en': 'Daily Reward'},
    txPurchase: {'ar': 'شراء صورة', 'en': 'Purchase'},
    txSale: {'ar': 'بيع صورة', 'en': 'Sale'},
    txAdminGrant: {'ar': 'مكافأة إدارية', 'en': 'Admin Grant'},
    txAdminDeduct: {'ar': 'خصم إداري', 'en': 'Admin Deduction'},
    txAdminSet: {'ar': 'تعيين إداري', 'en': 'Admin Set'},
    txWelcomeBonus: {'ar': 'مكافأة ترحيبية', 'en': 'Welcome Bonus'},
    txRefund: {'ar': 'استرداد', 'en': 'Refund'},
    txPenalty: {'ar': 'عقوبة', 'en': 'Penalty'},
    txUsernameChange: {'ar': 'تغيير اسم المستخدم', 'en': 'Username Change'},
    txAvatarChange: {'ar': 'تغيير الصورة الرمزية', 'en': 'Avatar Change'},
    txPlatformCommission: {'ar': 'عمولة المنصة', 'en': 'Platform Commission'},
    txUsernameChangeFee: {'ar': 'رسم تغيير اسم', 'en': 'Username Change Fee'},
    txAvatarChangeFee: {'ar': 'رسم تغيير صورة', 'en': 'Avatar Change Fee'},
    txTransferSent: {'ar': '🎁 تحويل (مرسل)', 'en': '🎁 Transfer (Sent)'},
    txTransferReceived: {'ar': '🎁 هدية (مستلمة)', 'en': '🎁 Gift (Received)'},
    txTransferCommission: {'ar': '💰 عمولة هدية', 'en': '💰 Gift Commission'},
  };

  static const List<String> supportedFormats = ['jpg', 'jpeg', 'png', 'webp', 'raw'];
  static const int maxImageSizeMB = 50;
}
