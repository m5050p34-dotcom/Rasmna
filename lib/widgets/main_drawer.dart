import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/profile/favorites_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/transactions_screen.dart';
import '../screens/upload/upload_screen.dart';
import '../utils/app_theme.dart';
import '../utils/translations.dart';
import 'daily_reward_widget.dart';
import 'support_app_button.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();
    final favs = context.watch<FavoritesProvider>();
    final profile = auth.profile;

    return Drawer(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, profile, auth.isAdmin),
            const DailyRewardWidget(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Divider(height: 1),
                  _menuItem(
                    context: context,
                    icon: Icons.person_outline,
                    title: T.get(context, 'my_profile'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _menuItem(
                    context: context,
                    icon: Icons.add_photo_alternate_outlined,
                    title: T.get(context, 'upload_photo'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UploadScreen(),
                        ),
                      );
                    },
                  ),
                  _menuItem(
                    context: context,
                    icon: Icons.favorite,
                    iconColor: AppTheme.secondary,
                    title: T.get(context, 'favorites'),
                    trailing: favs.count > 0
                        ? _badge('${favs.count}', AppTheme.secondary)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FavoritesScreen(),
                        ),
                      );
                    },
                  ),
                  _menuItem(
                    context: context,
                    icon: Icons.history,
                    iconColor: AppTheme.primary,
                    title: 'سجل النقاط',
                    subtitle: 'عرض كل حركات النقاط',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransactionsScreen(),
                        ),
                      );
                    },
                  ),
                  const SupportAppButton(),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Icon(
                      theme.themeMode == ThemeMode.dark
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: theme.themeMode == ThemeMode.dark
                          ? AppTheme.primary
                          : null,
                    ),
                    title: Text(T.get(context, 'dark_mode')),
                    value: theme.themeMode == ThemeMode.dark,
                    onChanged: (_) => theme.toggleTheme(),
                  ),
                  _menuItem(
                    context: context,
                    icon: Icons.language,
                    title: locale.isArabic ? 'English' : 'العربية',
                    onTap: () => locale.toggleLocale(),
                  ),
                  const Divider(height: 1),
                  _menuItem(
                    context: context,
                    icon: Icons.logout,
                    iconColor: AppTheme.error,
                    title: T.get(context, 'logout'),
                    titleColor: AppTheme.error,
                    onTap: () => _handleLogout(context),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? titleColor,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: titleColor != null ? FontWeight.bold : null,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 11))
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic profile, bool isAdmin) {
    final hasAvatar = profile?.avatarUrl != null &&
        (profile!.avatarUrl as String).isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: isAdmin
                      ? Border.all(color: AppTheme.warning, width: 3)
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: hasAvatar
                    ? Image.network(
                        profile.avatarUrl as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _initialText(profile?.initial),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return _initialText(profile?.initial);
                        },
                      )
                    : _initialText(profile?.initial),
              ),
              if (isAdmin)
                Positioned(
                  bottom: -8,
                  left: -8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminDashboard(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFB800),
                                Color(0xFFFF8C00),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFB800)
                                    .withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile?.username ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: AppTheme.warning,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                Text(
                  profile?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars,
                          color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${profile?.points ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialText(String? initial) {
    return Center(
      child: Text(
        initial ?? '?',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    final favs = context.read<FavoritesProvider>();
    final notifs = context.read<NotificationsProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(T.get(ctx, 'logout')),
        content: Text(T.get(ctx, 'logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(T.get(ctx, 'cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(T.get(ctx, 'logout')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    favs.clear();
    notifs.clear();
    await auth.signOut();
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text(T.tr('logout_success'))),
    );
  }
}
