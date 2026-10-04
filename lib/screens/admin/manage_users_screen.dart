import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/points_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/profile_service.dart';
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
          // ─── البحث ───
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

          // ─── القائمة ───
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

  // ═══════════════════════════════════════════════
  // بطاقة المستخدم
  // ═══════════════════════════════════════════════
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
                // ─── الأفاتار ───
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

                // ─── البيانات ───
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

                // ─── النقاط ───
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

                // ═══════════════════════════════════
                // قائمة الإجراءات
                // ═══════════════════════════════════
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _onAction(value, user, provider),
                  itemBuilder: (context) => [
                    // 📧 تغيير البريد
                    const PopupMenuItem(
                      value: 'email',
                      child: Row(
                        children: [
                          Icon(Icons.email,
                              size: 18, color: AppTheme.primary),
                          SizedBox(width: 8),
                          Text('تغيير البريد'),
                        ],
                      ),
                    ),
                    // 🔐 تغيير كلمة المرور
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
                    // ⭐ تعديل النقاط
                    const PopupMenuItem(
                      value: 'points',
                      child: Row(
                        children: [
                          Icon(Icons.stars, size: 18, color: AppTheme.accent),
                          SizedBox(width: 8),
                          Text('تعديل النقاط'),
                        ],
                      ),
                    ),
                    // 👑 ترقية/إلغاء أدمن
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
                    // 🚫 حظر/إلغاء حظر
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
                    // 🗑️ حذف الحساب
                    PopupMenuItem(
                      value: 'delete',
                      enabled: !isSelf,
                      child: const Row(
                        children: [
                          Icon(Icons.delete_forever,
                              size: 18, color: AppTheme.error),
                          SizedBox(width: 8),
                          Text(
                            'حذف الحساب نهائياً',
                            style: TextStyle(
                              color: AppTheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ─── الشارات ───
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

            if (user.isBanned &&
                user.banReason != null &&
                user.banReason!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.error, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'سبب الحظر:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.error,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(user.banReason!,
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
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
      case 'email':
        await _showChangeEmailDialog(user, provider);
        break;

      case 'password':
        await _showChangePasswordDialog(user);
        break;

      case 'points':
        await _showEditPointsDialog(user);
        break;

      case 'toggle_admin':
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
        final messenger = ScaffoldMessenger.of(context);
        final wasBanned = user.isBanned;

        if (wasBanned) {
          final confirm = await _confirm(
            title: 'إلغاء الحظر',
            message: 'تأكيد إلغاء حظر ${user.username}؟',
          );
          if (confirm != true) return;

          try {
            await provider.setBanned(user.id, false);
            messenger.showSnackBar(
              const SnackBar(
                content: Text('تم إلغاء الحظر'),
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
        } else {
          final reason = await _showBanReasonDialog(user);
          if (reason == null) return;

          try {
            await provider.setBanned(user.id, true, reason: reason);
            messenger.showSnackBar(
              SnackBar(
                content: Text('تم حظر ${user.username}'),
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
        }
        break;

      case 'delete':
        await _deleteUser(user, provider);
        break;
    }
  }

  // ═══════════════════════════════════════════════
  // 📧 نافذة تغيير البريد (للأدمن)
  // ═══════════════════════════════════════════════
  // ═══════════════════════════════════════════════
  // 📧 نافذة تغيير البريد (للأدمن — مع كلمة المرور)
  // ═══════════════════════════════════════════════
  Future<void> _showChangeEmailDialog(
    ProfileModel user,
    UserProvider provider,
  ) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final service = ProfileService();
    bool isLoading = false;
    bool obscurePassword = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email,
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
                      'تغيير البريد الإلكتروني',
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // البريد الحالي
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user.email,
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Icon(Icons.arrow_downward,
                      color: AppTheme.primary, size: 20),
                ),
                const SizedBox(height: 8),

                // البريد الجديد
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'البريد الجديد',
                    prefixIcon: Icon(Icons.email),
                    hintText: 'newemail@example.com',
                  ),
                ),
                const SizedBox(height: 12),

                // 🔐 كلمة مرور الأدمن
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: 'كلمة مرور الأدمن',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () => setDialogState(
                        () => obscurePassword = !obscurePassword,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // تنبيه
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.warning, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'سيتم تغيير البريد فوراً في المصادقة والبروفايل',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      final newEmail = emailController.text.trim();
                      final adminPassword = passwordController.text;

                      // ─── التحقق ───
                      if (newEmail.isEmpty || !newEmail.contains('@')) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('أدخل بريداً صحيحاً'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                        return;
                      }

                      if (adminPassword.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('أدخل كلمة مرور الأدمن'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                        return;
                      }

                      if (newEmail.toLowerCase() ==
                          user.email.toLowerCase()) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('البريد نفسه — لم يتغير'),
                            backgroundColor: AppTheme.warning,
                          ),
                        );
                        return;
                      }

                      // ─── تنفيذ ───
                      setDialogState(() => isLoading = true);

                      try {
                        await service.adminChangeEmail(
                          userId: user.id,
                          newEmail: newEmail,
                          adminPassword: adminPassword,
                        );

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }

                        await provider.fetchUsers();

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              '✅ تم تغيير البريد إلى $newEmail',
                            ),
                            backgroundColor: AppTheme.success,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      } catch (e) {
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(Helpers.errorMessage(e)),
                            backgroundColor: AppTheme.error,
                            duration: const Duration(seconds: 4),
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

  // ═══════════════════════════════════════════════
  // 🔐 نافذة تغيير كلمة المرور
  // ═══════════════════════════════════════════════
  Future<void> _showChangePasswordDialog(ProfileModel user) async {
    final passwordController = TextEditingController();
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
                enabled: !isLoading,
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

  // ═══════════════════════════════════════════════
  // 💰 نافذة تعديل النقاط
  // ═══════════════════════════════════════════════
  Future<void> _showEditPointsDialog(ProfileModel user) async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    String action = 'add';
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final amount = int.tryParse(amountController.text) ?? 0;
          int previewPoints;

          switch (action) {
            case 'add':
              previewPoints = user.points + amount;
              break;
            case 'deduct':
              previewPoints = (user.points - amount).clamp(0, 999999999);
              break;
            case 'set':
              previewPoints = amount;
              break;
            default:
              previewPoints = user.points;
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars,
                    color: AppTheme.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تعديل النقاط',
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
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet,
                            color: AppTheme.accent, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'الرصيد الحالي:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Text(
                          '${user.points}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'الإجراء:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          label: 'إضافة',
                          icon: Icons.add_circle,
                          color: AppTheme.success,
                          value: 'add',
                          current: action,
                          onTap: () => setState(() => action = 'add'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _actionButton(
                          label: 'خصم',
                          icon: Icons.remove_circle,
                          color: AppTheme.error,
                          value: 'deduct',
                          current: action,
                          onTap: () => setState(() => action = 'deduct'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _actionButton(
                          label: 'تعيين',
                          icon: Icons.edit,
                          color: AppTheme.primary,
                          value: 'set',
                          current: action,
                          onTap: () => setState(() => action = 'set'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ',
                      prefixIcon: Icon(Icons.numbers),
                      hintText: 'مثال: 500',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLength: 100,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'السبب (اختياري)',
                      prefixIcon: Icon(Icons.notes),
                      hintText: 'مثال: مكافأة تشجيعية',
                    ),
                  ),
                  if (amount > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up,
                              color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'الرصيد بعد التعديل:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$previewPoints',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              TextButton(
                onPressed:
                    isLoading ? null : () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => _submitPointsEdit(
                          dialogContext: dialogContext,
                          user: user,
                          amount: amount,
                          action: action,
                          reason: reasonController.text.trim(),
                          messenger: messenger,
                          setLoading: (v) => setState(() => isLoading = v),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: action == 'deduct'
                      ? AppTheme.error
                      : (action == 'set'
                          ? AppTheme.primary
                          : AppTheme.success),
                ),
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
                label: Text(isLoading ? 'جارٍ...' : 'تأكيد'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // تنفيذ تعديل النقاط
  // ═══════════════════════════════════════════════
  Future<void> _submitPointsEdit({
    required BuildContext dialogContext,
    required ProfileModel user,
    required int amount,
    required String action,
    required String reason,
    required ScaffoldMessengerState messenger,
    required Function(bool) setLoading,
  }) async {
    if (amount <= 0 && action != 'set') {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('أدخل مبلغاً صحيحاً'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    if (action == 'set' && amount < 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('لا يمكن تعيين قيمة سالبة'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setLoading(true);

    try {
      final pointsProvider = context.read<PointsProvider>();
      final userProvider = context.read<UserProvider>();

      final finalReason = reason.isEmpty ? _defaultReason(action) : reason;

      int newBalance;

      switch (action) {
        case 'add':
          newBalance = await pointsProvider.adminGrant(
            userId: user.id,
            amount: amount,
            reason: finalReason,
          );
          break;
        case 'deduct':
          newBalance = await pointsProvider.adminDeduct(
            userId: user.id,
            amount: amount,
            reason: finalReason,
          );
          break;
        case 'set':
        default:
          newBalance = await pointsProvider.setUserPoints(
            userId: user.id,
            newValue: amount,
            reason: finalReason,
          );
          break;
      }

      userProvider.updateUserPoints(user.id, newBalance);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ تم التحديث • الرصيد الجديد: $newBalance'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(Helpers.errorMessage(e)),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  String _defaultReason(String action) {
    switch (action) {
      case 'add':
        return 'مكافأة إدارية';
      case 'deduct':
        return 'خصم إداري';
      case 'set':
        return 'تعيين إداري';
      default:
        return 'تعديل إداري';
    }
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required String value,
    required String current,
    required VoidCallback onTap,
  }) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 🗑️ حذف الحساب نهائياً
  // ═══════════════════════════════════════════════
  Future<void> _deleteUser(
    ProfileModel user,
    UserProvider provider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // ─── تأكيد أول ───
    final firstConfirm = await showDialog<bool>(
      context: navigator.context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppTheme.error, size: 28),
            SizedBox(width: 8),
            Text(
              'تحذير خطير!',
              style: TextStyle(color: AppTheme.error),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سيتم حذف حساب "${user.username}" نهائياً، ومعها:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• الحساب بالكامل'),
            const Text('• جميع صوره من Storage'),
            const Text('• جميع سجلاته وبياناته'),
            const Text('• جميع بلاغاته وتقييماته'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline,
                      color: AppTheme.error, size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'لا يمكن التراجع عن هذا الإجراء!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;
    if (!mounted) return;

    // ─── حوار ثاني ───
    final finalConfirm = await showDialog<bool>(
      context: navigator.context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد نهائي'),
        content: Text('هل أنت متأكد 100% من حذف "${user.username}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('حذف نهائي'),
          ),
        ],
      ),
    );

    if (finalConfirm != true) return;

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'admin-delete-user',
        body: {'user_id': user.id},
      );

      if (response.status == 200) {
        await provider.fetchUsers();
        messenger.showSnackBar(
          SnackBar(
            content: Text('✅ تم حذف حساب ${user.username} نهائياً'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        final error = response.data?['error'] ?? 'خطأ غير معروف';
        messenger.showSnackBar(
          SnackBar(
            content: Text('فشل: $error'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<String?> _showBanReasonDialog(ProfileModel user) async {
    final reasonController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final quickReasons = <String>[
      'سبب 1',
      'سبب 2',
      'سبب 3',
    ];

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.block,
                  color: AppTheme.error, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('حظر المستخدم',
                      style: TextStyle(fontSize: 16)),
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'السبب',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: quickReasons
                    .map((r) => ActionChip(
                          label: Text(r,
                              style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            reasonController.text = r;
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error),
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('أدخل السبب'),
                    backgroundColor: AppTheme.error,
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, reason);
            },
            icon: const Icon(Icons.block, size: 18),
            label: const Text('حظر'),
          ),
        ],
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
