import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/edit_points_dialog.dart';

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
              onSubmitted: (v) => context.read<UserProvider>().fetchUsers(search: v),
            ),
          ),

          // ─── الفلاتر ───
          Consumer<UserProvider>(
            builder: (context, provider, _) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _filterChip('الكل', UserFilter.all, provider),
                    const SizedBox(width: 8),
                    _filterChip('الأدمن', UserFilter.admins, provider),
                    const SizedBox(width: 8),
                    _filterChip('المحظورون', UserFilter.banned, provider),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),

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

  Widget _filterChip(String label, UserFilter filter, UserProvider provider) {
    final isSelected = provider.filter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.fetchUsers(filter: filter),
      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primary,
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

                // ─── قائمة الإجراءات ───
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) => _onAction(value, user, provider),
                  itemBuilder: (context) => [
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
                            user.isAdmin ? Icons.remove_moderator : Icons.admin_panel_settings,
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

            // ─── شارات الحالة ───
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

  Future<void> _onAction(
    String action,
    ProfileModel user,
    UserProvider provider,
  ) async {
    switch (action) {
      case 'points':
        await showEditPointsDialog(context, user);
        break;
      case 'toggle_admin':
        final confirm = await _confirm(
          title: user.isAdmin ? 'إلغاء صلاحية الأدمن' : 'ترقية إلى أدمن',
          message: user.isAdmin
              ? 'هل تريد إلغاء صلاحية الأدمن من ${user.username}؟'
              : 'هل تريد ترقية ${user.username} إلى أدمن؟',
        );
        if (confirm == true) {
          try {
            await provider.setAdmin(user.id, !user.isAdmin);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(user.isAdmin
                      ? 'تم إلغاء صلاحية الأدمن'
                      : 'تم ترقية المستخدم لأدمن'),
                  backgroundColor: AppTheme.success,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(Helpers.errorMessage(e)),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
          }
        }
        break;
      case 'toggle_ban':
        final confirm = await _confirm(
          title: user.isBanned ? 'إلغاء الحظر' : 'حظر المستخدم',
          message: user.isBanned
              ? 'هل تريد إلغاء حظر ${user.username}؟'
              : 'هل تريد حظر ${user.username}؟ لن يستطيع استخدام التطبيق.',
        );
        if (confirm == true) {
          try {
            await provider.setBanned(user.id, !user.isBanned);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(user.isBanned
                      ? 'تم إلغاء الحظر'
                      : 'تم حظر المستخدم'),
                  backgroundColor: AppTheme.success,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(Helpers.errorMessage(e)),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
          }
        }
        break;
    }
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
