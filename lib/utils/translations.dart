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
    'privacy_policy': {
      'ar': 'سياسة الخصوصية',
      'en': 'Privacy Policy'
    },
    'privacy_effective_date': {
      'ar': 'تاريخ السريان: أكتوبر 2026',
      'en': 'Effective Date: October 2026'
    },
    'privacy_intro': {
      'ar': 'نحن في تطبيق "رسمنا" نؤمن بأن الخصوصية هي حق أساسي من حقوق المستخدمين. لقد صُمم هذا التطبيق ليكون بيئة آمنة وحرة لبيع وشراء الصور الرقمية، ودون أي تعقيدات تتعلق بجمع البيانات أو تتبع النشاط الشخصي.\n\nباستخدامك لتطبيق "رسمنا"، فإنك توافق على الالتزام بالبنود الموضحة في هذه السياسة:',
      'en': 'At Rasmna, we believe that privacy is a fundamental right of every user. This app is designed to be a safe and free environment for buying and selling digital images, without any complexities related to data collection or personal activity tracking.\n\nBy using Rasmna, you agree to comply with the terms outlined in this policy:'
    },
    'privacy_footer': {
      'ar': 'خصوصيتك محمية بالكامل — نحن لا نجمع أي بيانات',
      'en': 'Your privacy is fully protected — we collect no data'
    },
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

    // ═══════════════════════════════════════
    // 🎨 متجر الأيقونات (جديد)
    // ═══════════════════════════════════════
    'icon_store': {'ar': 'متجر الأيقونات', 'en': 'Icon Store'},
    'icon_store_desc': {
      'ar': 'ميّز اسمك بأيقونة حصرية',
      'en': 'Stand out with an exclusive icon'
    },
    'manage_icons': {'ar': 'إدارة الأيقونات', 'en': 'Manage Icons'},
    'manage_icons_desc': {
      'ar': 'إضافة، تعديل، تسعير، تعطيل أيقونات المتجر',
      'en': 'Add, edit, price, disable store icons'
    },
    'my_active_icon': {'ar': 'أيقونتي النشطة', 'en': 'My Active Icon'},
    'no_icons_yet': {'ar': 'لا توجد أيقونات بعد', 'en': 'No icons yet'},
    'no_icons_hint': {
      'ar': 'عد قريباً، سيتم إضافة أيقونات جديدة',
      'en': 'Check back soon, new icons are coming'
    },
    'icon_name': {'ar': 'اسم الأيقونة', 'en': 'Icon Name'},
    'icon_description': {'ar': 'الوصف', 'en': 'Description'},
    'icon_description_hint': {
      'ar': 'وصف مختصر (اختياري)',
      'en': 'Short description (optional)'
    },
    'icon_price': {'ar': 'السعر (نقاط)', 'en': 'Price (points)'},
    'icon_duration': {'ar': 'المدة (يوم)', 'en': 'Duration (days)'},
    'icon_order': {'ar': 'ترتيب الظهور', 'en': 'Display Order'},
    'icon_order_hint': {
      'ar': 'الأصغر يظهر أولاً',
      'en': 'Smaller appears first'
    },
    'icon_image': {'ar': 'صورة الأيقونة', 'en': 'Icon Image'},
    'icon_image_hint': {
      'ar': 'PNG شفاف مُفضّل (512×512)',
      'en': 'Transparent PNG preferred (512×512)'
    },
    'new_icon': {'ar': 'أيقونة جديدة', 'en': 'New Icon'},
    'edit_icon': {'ar': 'تعديل أيقونة', 'en': 'Edit Icon'},
    'create_icon': {'ar': 'إنشاء الأيقونة', 'en': 'Create Icon'},
    'icon_created': {
      'ar': 'تم إنشاء الأيقونة',
      'en': 'Icon created successfully'
    },
    'icon_updated': {
      'ar': 'تم تحديث الأيقونة',
      'en': 'Icon updated successfully'
    },
    'icon_deleted': {
      'ar': 'تم حذف الأيقونة',
      'en': 'Icon deleted'
    },
    'icon_activate': {'ar': 'تفعيل', 'en': 'Activate'},
    'icon_deactivate': {'ar': 'تعطيل', 'en': 'Deactivate'},
    'icon_active': {'ar': 'فعّالة', 'en': 'Active'},
    'icon_inactive': {'ar': 'معطّلة', 'en': 'Inactive'},
    'icon_is_active': {'ar': 'الأيقونة فعّالة', 'en': 'Icon is active'},
    'icon_is_active_hint': {
      'ar': 'عند التعطيل، لن تظهر في المتجر',
      'en': 'When disabled, it won\'t show in store'
    },
    'buy_icon': {'ar': 'شراء الأيقونة', 'en': 'Buy Icon'},
    'purchase_icon': {'ar': 'شراء', 'en': 'Purchase'},
    'purchase_confirm': {
      'ar': 'هل تريد شراء هذه الأيقونة؟',
      'en': 'Do you want to buy this icon?'
    },
    'purchase_success': {
      'ar': 'تم شراء الأيقونة بنجاح',
      'en': 'Icon purchased successfully'
    },
    'purchase_failed': {
      'ar': 'فشل شراء الأيقونة',
      'en': 'Failed to purchase icon'
    },
    'insufficient_points': {
      'ar': 'رصيدك غير كافٍ',
      'en': 'Insufficient points'
    },
    'already_own_icon': {
      'ar': 'أنت تملك هذه الأيقونة بالفعل',
      'en': 'You already own this icon'
    },
    'icon_not_available': {
      'ar': 'هذه الأيقونة غير متاحة حالياً',
      'en': 'This icon is not available'
    },
    'icon_expires_after': {
      'ar': 'تنتهي الصلاحية بعد',
      'en': 'Expires after'
    },
    'icon_days': {'ar': 'يوم', 'en': 'days'},
    'icon_days_remaining': {
      'ar': 'يوم متبقٍ',
      'en': 'days remaining'
    },
    'icon_expiring_soon': {
      'ar': 'ستنتهي قريباً',
      'en': 'Expiring soon'
    },
    'icon_expired': {'ar': 'منتهية', 'en': 'Expired'},
    'icon_valid_until': {
      'ar': 'سارية حتى',
      'en': 'Valid until'
    },
    'you_currently_have': {
      'ar': 'لديك حالياً',
      'en': 'You currently have'
    },
    'buy_now': {'ar': 'اشترِ الآن', 'en': 'Buy Now'},
    'change_icon': {'ar': 'تغيير الأيقونة', 'en': 'Change Icon'},
    'your_active_icon': {
      'ar': 'أيقونتك الحالية',
      'en': 'Your current icon'
    },
    'no_active_icon': {
      'ar': 'لا تملك أيقونة نشطة',
      'en': 'You don\'t have an active icon'
    },
    'no_active_icon_hint': {
      'ar': 'اشترِ واحدة من المتجر لتظهر بجانب اسمك',
      'en': 'Buy one from the store to show next to your name'
    },
    'cleanup_expired': {
      'ar': 'تنظيف المنتهية',
      'en': 'Clean expired'
    },
    'cleanup_success': {
      'ar': 'تم تنظيف الأيقونات المنتهية',
      'en': 'Expired icons cleaned'
    },
    'confirm_delete_icon': {
      'ar': 'هل أنت متأكد من حذف هذه الأيقونة؟',
      'en': 'Are you sure you want to delete this icon?'
    },
    'confirm_delete_icon_hint': {
      'ar': 'لن يتمكن المستخدمون من رؤيتها في المتجر',
      'en': 'Users won\'t see it in the store'
    },
    'image_required': {
      'ar': 'يجب اختيار صورة للأيقونة',
      'en': 'Please pick an icon image'
    },
    'points_balance': {
      'ar': 'رصيدك الحالي',
      'en': 'Your balance'
    },
    'icon_store_tagline': {
      'ar': '🎨 ميّز اسمك بأيقونة حصرية',
      'en': '🎨 Make your name stand out'
    },
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
