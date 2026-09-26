import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class T {
  static const Map<String, Map<String, String>> _data = {
    // ═══════════════════════════════════════
    // عام
    // ═══════════════════════════════════════
    'app_name': {'ar': 'رسمنا', 'en': 'Rasmna'},
    'marketplace': {'ar': 'سوق الصور', 'en': 'Marketplace'},
    'loading': {'ar': 'جارٍ التحميل...', 'en': 'Loading...'},
    'retry': {'ar': 'إعادة المحاولة', 'en': 'Retry'},
    'cancel': {'ar': 'إلغاء', 'en': 'Cancel'},
    'save': {'ar': 'حفظ', 'en': 'Save'},
    'delete': {'ar': 'حذف', 'en': 'Delete'},
    'edit': {'ar': 'تعديل', 'en': 'Edit'},
    'add': {'ar': 'إضافة', 'en': 'Add'},
    'search': {'ar': 'بحث', 'en': 'Search'},
    'refresh': {'ar': 'تحديث', 'en': 'Refresh'},
    'yes': {'ar': 'نعم', 'en': 'Yes'},
    'no': {'ar': 'لا', 'en': 'No'},
    'confirm': {'ar': 'تأكيد', 'en': 'Confirm'},
    'close': {'ar': 'إغلاق', 'en': 'Close'},

    // ═══════════════════════════════════════
    // القائمة الجانبية
    // ═══════════════════════════════════════
    'my_profile': {'ar': 'ملفي الشخصي', 'en': 'My Profile'},
    'upload_photo': {'ar': 'رفع صورة', 'en': 'Upload Photo'},
    'favorites': {'ar': 'المفضلة', 'en': 'Favorites'},
    'admin_panel': {'ar': 'لوحة الأدمن', 'en': 'Admin Panel'},
    'dark_mode': {'ar': 'الوضع الليلي', 'en': 'Dark Mode'},
    'logout': {'ar': 'تسجيل الخروج', 'en': 'Logout'},
    'logout_confirm': {
      'ar': 'هل تريد الخروج من الحساب؟',
      'en': 'Do you want to logout?'
    },
    'logout_success': {
      'ar': 'تم تسجيل الخروج',
      'en': 'Logged out successfully'
    },
    'points': {'ar': 'نقطة', 'en': 'points'},

    // ═══════════════════════════════════════
    // السوق
    // ═══════════════════════════════════════
    'all': {'ar': 'الكل', 'en': 'All'},
    'no_photos_yet': {'ar': 'لا توجد صور بعد', 'en': 'No photos yet'},
    'sort': {'ar': 'فرز', 'en': 'Sort'},

    // ═══════════════════════════════════════
    // الملف الشخصي
    // ═══════════════════════════════════════
    'edit_profile': {'ar': 'تعديل الملف', 'en': 'Edit Profile'},
    'my_photos': {'ar': 'صوري', 'en': 'My Photos'},
    'points_history': {'ar': 'سجل النقاط', 'en': 'Points History'},
    'daily_reward': {'ar': 'المكافأة اليومية', 'en': 'Daily Reward'},
    'claim_reward': {'ar': 'استلام المكافأة', 'en': 'Claim Reward'},
    'already_claimed': {
      'ar': 'تم استلامها اليوم',
      'en': 'Already claimed today'
    },
    'admin_badge': {'ar': 'أدمن', 'en': 'Admin'},

    // ═══════════════════════════════════════
    // تفاصيل الصورة
    // ═══════════════════════════════════════
    'fullscreen_preview': {
      'ar': 'معاينة كاملة الشاشة',
      'en': 'Fullscreen Preview'
    },
    'free': {'ar': 'مجاني', 'en': 'Free'},
    'buy': {'ar': 'شراء', 'en': 'Buy'},
    'download': {'ar': 'تحميل', 'en': 'Download'},
    'download_photo': {'ar': 'تحميل الصورة', 'en': 'Download Photo'},
    'downloading': {'ar': 'جارٍ التحميل...', 'en': 'Downloading...'},

    // ═══════════════════════════════════════
    // رفع الصورة
    // ═══════════════════════════════════════
    'upload_new_photo': {
      'ar': 'رفع صورة جديدة',
      'en': 'Upload New Photo'
    },
    'photo_title': {'ar': 'عنوان الصورة', 'en': 'Photo title'},
    'category': {'ar': 'التصنيف', 'en': 'Category'},
    'make_free': {'ar': 'اجعلها مجانية', 'en': 'Make it free'},
    'price_points': {'ar': 'السعر (بالنقاط)', 'en': 'Price (points)'},
    'publish_photo': {'ar': 'نشر الصورة', 'en': 'Publish Photo'},

    // ═══════════════════════════════════════
    // تسجيل الدخول
    // ═══════════════════════════════════════
    'login': {'ar': 'تسجيل الدخول', 'en': 'Login'},
    'signup': {'ar': 'إنشاء حساب', 'en': 'Sign Up'},
    'email': {'ar': 'البريد الإلكتروني', 'en': 'Email'},
    'password': {'ar': 'كلمة المرور', 'en': 'Password'},
    'confirm_password': {
      'ar': 'تأكيد كلمة المرور',
      'en': 'Confirm Password'
    },
    'no_account': {'ar': 'ليس لديك حساب؟', 'en': 'No account?'},
    'create_account': {'ar': 'أنشئ حساباً', 'en': 'Create Account'},

    // ═══════════════════════════════════════
    // لوحة الأدمن
    // ═══════════════════════════════════════
    'statistics': {'ar': 'الإحصائيات', 'en': 'Statistics'},
    'users': {'ar': 'المستخدمون', 'en': 'Users'},
    'photos': {'ar': 'الصور', 'en': 'Photos'},
    'total_points': {'ar': 'إجمالي النقاط', 'en': 'Total Points'},
    'actions': {'ar': 'الإجراءات', 'en': 'Actions'},
    'manage_users': {'ar': 'إدارة المستخدمين', 'en': 'Manage Users'},
  };

  /// ترجمة مفتاح حسب اللغة الحالية (يتطلب context)
  static String get(BuildContext context, String key) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    return _data[key]?[isArabic ? 'ar' : 'en'] ?? key;
  }

  /// ترجمة بدون context
  static String tr(String key, {bool isArabic = true}) {
    return _data[key]?[isArabic ? 'ar' : 'en'] ?? key;
  }
}
