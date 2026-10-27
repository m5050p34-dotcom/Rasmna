# قواعد عامة لحماية الإشعارات والحزم الأساسية
-keep class io.flutter.** { *; }
-keep class io.supabase.** { *; }
-keep class com.dexterous.** { *; }
-keep class com.baseflow.** { *; }
-dontwarn io.flutter.embedding.**
-dontwarn io.supabase.**

# حماية مكتبات Flutter المحلية
-keep class com.rasmna.** { *; }
