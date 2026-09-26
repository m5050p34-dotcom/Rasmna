import 'package:intl/intl.dart';

class Helpers {
  static String formatDate(DateTime date, {String locale = 'ar'}) =>
      DateFormat.yMMMd(locale).format(date);

  static String formatDateTime(DateTime date, {String locale = 'ar'}) =>
      DateFormat.yMMMd(locale).add_Hm().format(date);

  static String timeAgo(DateTime date, {bool isArabic = true}) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30) {
      return formatDate(date, locale: isArabic ? 'ar' : 'en');
    } else if (diff.inDays > 0) {
      return isArabic ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return isArabic ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return isArabic ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    }
    return isArabic ? 'الآن' : 'now';
  }

  static String formatPrice(double price, {bool isArabic = true}) {
    if (price == 0) return isArabic ? 'مجاني' : 'Free';
    if (price == price.roundToDouble()) {
      return '${price.toInt()} ${isArabic ? "نقطة" : "pts"}';
    }
    return '${price.toStringAsFixed(2)} ${isArabic ? "نقطة" : "pts"}';
  }

  static String formatPoints(int points, {bool isArabic = true}) =>
      '$points ${isArabic ? "نقطة" : "pts"}';

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // ═══════════════════════════════════════════════
  // 💬 رسائل الخطأ الاحترافية
  // ═══════════════════════════════════════════════
  static String errorMessage(Object error) {
    final msg = error.toString().toLowerCase();

    // ─── الشبكة ───
    if (msg.contains('socketexception') ||
        msg.contains('network is unreachable') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection')) {
      return '📶 لا يوجد اتصال بالإنترنت. تحقق من الشبكة.';
    }

    // ─── تسجيل الدخول ───
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials') ||
        msg.contains('invalid grant') ||
        msg.contains('invalid password')) {
      return '❌ البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }

    // ─── التسجيل: البريد مستخدم ───
    if (msg.contains('user already registered') ||
        msg.contains('already registered') ||
        msg.contains('email address is already') ||
        msg.contains('already exists') ||
        msg.contains('duplicate key')) {
      return '📧 هذا البريد الإلكتروني مسجل بالفعل.\nجرب تسجيل الدخول بدلاً من التسجيل.';
    }

    // ─── تأكيد البريد ───
    if (msg.contains('email not confirmed') ||
        msg.contains('email_not_confirmed')) {
      return '✉️ يجب تأكيد البريد الإلكتروني أولاً. تحقق من بريدك.';
    }

    // ─── كلمة المرور القصيرة ───
    if (msg.contains('password should be at least') ||
        msg.contains('password is too short') ||
        (msg.contains('password') && msg.contains('least'))) {
      return '🔒 كلمة المرور قصيرة جداً (6 أحرف على الأقل)';
    }

    // ─── كلمة مرور ضعيفة ───
    if (msg.contains('weak password') ||
        msg.contains('password too weak') ||
        msg.contains('pwned')) {
      return '🔒 كلمة المرور ضعيفة جداً.\nاستخدم مزيجاً من الأحرف والأرقام.';
    }

    // ─── التسجيل معطل ───
    if (msg.contains('signup disabled') ||
        msg.contains('signups not allowed') ||
        msg.contains('disabled signups')) {
      return '🚫 التسجيل غير متاح حالياً. حاول لاحقاً.';
    }

    // ─── تجاوز حد الإرسال ───
    if (msg.contains('email rate limit') ||
        msg.contains('over_email_send_rate_limit') ||
        msg.contains('rate limit exceeded') ||
        msg.contains('too many requests')) {
      return '⏳ تم إرسال رسائل كثيرة. انتظر قليلاً ثم أعد المحاولة.';
    }

    // ─── البريد غير صالح ───
    if (msg.contains('invalid email') ||
        msg.contains('email format') ||
        msg.contains('not a valid email')) {
      return '📧 صيغة البريد الإلكتروني غير صحيحة';
    }

    // ─── الأدمن ───
    if (msg.contains('only admins')) {
      return '👑 هذا الإجراء متاح للأدمن فقط';
    }

    // ─── المستخدم ───
    if (msg.contains('user not found')) {
      return '👤 المستخدم غير موجود';
    }

    if (msg.contains('not authenticated') ||
        msg.contains('jwt expired') ||
        msg.contains('invalid token')) {
      return '🔐 انتهت جلستك. سجل الدخول مرة أخرى.';
    }

    // ─── المكافأة اليومية ───
    if (msg.contains('already claimed') ||
        msg.contains('لقد استلمت')) {
      return '🎁 لقد استلمت مكافأة اليوم بالفعل';
    }

    // ─── الشراء ───
    if (msg.contains('already purchased')) {
      return '🛒 لقد اشتريت هذه الصورة مسبقاً';
    }

    if (msg.contains('insufficient')) {
      return '💰 رصيدك غير كافٍ لإتمام العملية';
    }

    if (msg.contains('cannot purchase your own')) {
      return '🚫 لا يمكنك شراء صورتك الخاصة';
    }

    // ─── الصور ───
    if (msg.contains('photo not found')) {
      return '🖼️ الصورة غير موجودة';
    }

    if (msg.contains('bucket not found') ||
        msg.contains('storageexception')) {
      return '📦 خطأ في التخزين. حاول لاحقاً.';
    }

    if (msg.contains('exceeded the maximum')) {
      return '📏 حجم الملف كبير جداً';
    }

    // ─── RLS ───
    if (msg.contains('row level security') ||
        msg.contains('permission denied') ||
        msg.contains('not allowed')) {
      return '⛔ لا تملك صلاحية لهذا الإجراء';
    }

    // ─── عام ───
    if (msg.length > 150) {
      return '⚠️ حدث خطأ غير متوقع. حاول مرة أخرى.';
    }

    // الافتراضي: أعد الرسالة الأصلية إن كانت قصيرة
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
