import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/banner_provider.dart';
import 'providers/categories_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/featured_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/photo_provider.dart';
import 'providers/platform_provider.dart';
import 'providers/points_provider.dart';
import 'providers/sort_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/marketplace_screen.dart';
import 'screens/onboarding/permissions_screen.dart';
import 'services/ads_service.dart';
import 'services/local_notifications_service.dart';
import 'services/permissions_service.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🎬 AdMob + Unity Ads Mediation - لا ننتظره
  AdsService().initialize().catchError((e) {
    debugPrint('⚠️ Ads init failed: $e');
  });

  // 🔔 Local Notifications - لا ننتظره
  LocalNotificationsService.initialize().catchError((e) {
    debugPrint('⚠️ Local Notifications init failed: $e');
  });

  // 🗄️ Supabase - مع timeout
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      publishableKey: SupabaseConfig.supabasePublishableKey,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('⚠️ Supabase init timeout');
        throw Exception('Supabase timeout');
      },
    );
  } catch (e) {
    debugPrint('❌ Supabase init error: $e');
  }

  runApp(const RasmnaApp());
}

class RasmnaApp extends StatefulWidget {
  const RasmnaApp({super.key});

  @override
  State<RasmnaApp> createState() => _RasmnaAppState();
}

class _RasmnaAppState extends State<RasmnaApp> {
  bool _showPermissions = false;
  bool _checking = true;
  bool _permissionsDone = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    try {
      final isFirst = await PermissionsService.isFirstLaunch()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      if (mounted) {
        setState(() {
          _showPermissions = isFirst;
          _checking = false;
        });
      }
    } catch (e) {
      debugPrint('❌ First launch check error: $e');
      if (mounted) {
        setState(() {
          _showPermissions = false;
          _checking = false;
        });
      }
    }
  }

  void _onPermissionsComplete() {
    setState(() {
      _permissionsDone = true;
      _showPermissions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ⏳ في انتظار التحقق
    if (_checking) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // 📋 شاشة الأذونات (أول مرة فقط)
    if (_showPermissions && !_permissionsDone) {
      return MaterialApp(
        title: 'رسمنا',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: PermissionsScreen(onComplete: _onPermissionsComplete),
      );
    }

    // 🏠 التطبيق الرئيسي مع جميع المزودين
    return MultiProvider(
      providers: [
        // ─── المزودون الأساسيون ───
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // ─── مزودو المحتوى ───
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => CategoriesProvider()),
        ChangeNotifierProvider(create: (_) => FeaturedProvider()),

        // ─── ⭐ مزودو المستخدم ───
        ChangeNotifierProvider(create: (_) => PointsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),

        // ─── مزودو الإدارة ───
        ChangeNotifierProvider(create: (_) => SortProvider()),
        ChangeNotifierProvider(create: (_) => PlatformProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return MaterialApp(
            title: 'رسمنا',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: localeProvider.locale,
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(
                textDirection: localeProvider.isArabic
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child ?? const SizedBox(),
              );
            },
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.isAuthenticated) return const MarketplaceScreen();
        return const LoginScreen();
      },
    );
  }
}
