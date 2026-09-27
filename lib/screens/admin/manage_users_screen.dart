import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المستخدمين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<UserProvider>().fetchUsers(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو البريد...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<UserProvider>().fetchUsers(search: '');
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) =>
                  context.read<UserProvider>().fetchUsers(search: v),
            ),
          ),
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.users.isEmpty) {
                  return const Center(child: Text('لا يوجد مستخدمون'));
                }
                return RefreshIndicator(
                  onRefresh: () => provider.fetchUsers(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.users.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(provider.users[index], provider);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(ProfileModel user, UserProvider provider) {
    final currentUserId = context.read<AuthProvider>().userId;
    final isSelf = user.id == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: user.isBanned
                      ? AppTheme.error
                      : (user.isAdmin ? AppTheme.warning : AppTheme.primary),
                  child: Text(
                    user.initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.isAdmin)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.verified,
                                color: AppTheme.warning,
                                size: 18,
                              ),
                            ),
                          if (isSelf)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Text(
                                '(أنت)',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars,
                          color: AppTheme.accent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${user.points}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _onAction(value, user, provider),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'password',
                      child: Row(
                        children: [
                          Icon(Icons.lock_reset,
                              size: 18, color: AppTheme.primary),
                          SizedBox(width: 8),
                          Text('تغيير كلمة المرور'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'points',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('تعديل النقاط'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_admin',
                      enabled: !isSelf,
                      child: Row(
                        children: [
                          Icon(
                            user.isAdmin
                                ? Icons.remove_moderator
                                : Icons.admin_panel_settings,
                            size: 18,
                            color: AppTheme.warning,
                          ),
                          const SizedBox(width: 8),
                          Text(user.isAdmin ? 'إلغاء الأدمن' : 'ترقية لأدمن'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_ban',
                      enabled: !isSelf,
                      child: Row(
                        children: [
                          Icon(
                            user.isBanned ? Icons.check_circle : Icons.block,
                            size: 18,
                            color: AppTheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(user.isBanned ? 'إلغاء الحظر' : 'حظر المستخدم'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (user.isAdmin || user.isBanned)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    if (user.isAdmin)
                      _badge('أدمن', AppTheme.warning, Icons.verified),
                    if (user.isAdmin && user.isBanned)
                      const SizedBox(width: 6),
                    if (user.isBanned)
                      _badge('محظور', AppTheme.error, Icons.block),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // معالج الإجراءات
  // ═══════════════════════════════════════════════
  Future<void> _onAction(
    String action,
    ProfileModel user,
    UserProvider provider,
  ) async {
    switch (action) {
      case 'password':
        await _showChangePasswordDialog(user);
        break;

      case 'points':
        break;

      case 'toggle_admin':
        // ✅ التقاط messenger قبل أي await
        final messenger = ScaffoldMessenger.of(context);
        final wasAdmin = user.isAdmin;

        final confirm = await _confirm(
          title: wasAdmin ? 'إلغاء صلاحية الأدمن' : 'ترقية إلى أدمن',
          message: wasAdmin
              ? 'هل تريد إلغاء صلاحية الأدمن من ${user.username}؟'
              : 'هل تريد ترقية ${user.username} إلى أدمن؟',
        );

        if (confirm != true) return;

        try {
          await provider.setAdmin(user.id, !wasAdmin);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                wasAdmin ? 'تم إلغاء صلاحية الأدمن' : 'تم ترقية المستخدم لأدمن',
              ),
              backgroundColor: AppTheme.success,
            ),
          );
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(Helpers.errorMessage(e)),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        break;

      case 'toggle_ban':
        // ✅ التقاط messenger قبل أي await
        final messenger = ScaffoldMessenger.of(context);
        final wasBanned = user.isBanned;

        final confirm = await _confirm(
          title: wasBanned ? 'إلغاء الحظر' : 'حظر المستخدم',
          message: wasBanned
              ? 'هل تريد إلغاء حظر ${user.username}؟'
              : 'هل تريد حظر ${user.username}؟',
        );

        if (confirm != true) return;

        try {
          await provider.setBanned(user.id, !wasBanned);
          messenger.showSnackBar(
            SnackBar(
              content: Text(wasBanned ? 'تم إلغاء الحظر' : 'تم حظر المستخدم'),
              backgroundColor: AppTheme.success,
            ),
          );
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(Helpers.errorMessage(e)),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        break;
    }
  }

  // ═══════════════════════════════════════════════
  // 🔐 نافذة تغيير كلمة المرور
  // ═══════════════════════════════════════════════
  Future<void> _showChangePasswordDialog(ProfileModel user) async {
    final passwordController = TextEditingController();
    // ✅ التقاط messenger قبل فتح الحوار
    final messenger = ScaffoldMessenger.of(context);

    bool obscure = true;
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تغيير كلمة المرور',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      user.username,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(dialogContext).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppTheme.warning, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '6 أحرف على الأقل',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () async {
                      final newPassword = passwordController.text.trim();
                      if (newPassword.length < 6) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('كلمة المرور قصيرة جداً'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      try {
                        final response = await Supabase.instance.client
                            .functions
                            .invoke('admin-change-password', body: {
                          'user_id': user.id,
                          'new_password': newPassword,
                        });

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }

                        if (response.status == 200) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                '✅ تم تغيير كلمة مرور ${user.username}',
                              ),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        } else {
                          final error =
                              response.data?['error'] ?? 'خطأ غير معروف';
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('فشل: $error'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('خطأ: $e'),
                            backgroundColor: AppTheme.error,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    },
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(isLoading ? 'جارٍ...' : 'تغيير'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}
