import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/photo_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/photo_provider.dart';
import '../../services/follows_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/translations.dart';
import '../../widgets/photo_card.dart';
import '../home/photo_details_screen.dart';
import '../upload/upload_screen.dart';
import 'edit_profile_screen.dart';
import 'followers_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _followsService = FollowsService();
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final uid = auth.userId;

      // ✅ تنظيف الأيقونة المنتهية محلياً (إن وُجدت)
      auth.clearExpiredIconLocally();

      if (uid != null) {
        context.read<PhotoProvider>().fetchUserPhotos(uid);
        _loadFollowStats(uid);
      }
    });
  }

  Future<void> _loadFollowStats(String userId) async {
    try {
      final stats = await _followsService.getPhotographerStats(userId);
      if (mounted) {
        setState(() {
          _followersCount = stats.followersCount;
          _followingCount = stats.followingCount;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(T.get(context, 'my_profile')),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: T.get(context, 'edit_profile'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final profile = auth.profile;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () async {
              final photoProvider = context.read<PhotoProvider>();
              await auth.refreshProfile();
              if (auth.userId != null && mounted) {
                await photoProvider.fetchUserPhotos(auth.userId!);
                await _loadFollowStats(auth.userId!);
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ═══════════════════════════════════
                  // رأس الملف
                  // ═══════════════════════════════════
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // ─── الأفاتار ───
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              (profile.avatarUrl != null &&
                                      profile.avatarUrl!.isNotEmpty)
                                  ? CachedNetworkImageProvider(
                                      profile.avatarUrl!)
                                  : null,
                          child: (profile.avatarUrl == null ||
                                  profile.avatarUrl!.isEmpty)
                              ? Text(
                                  profile.initial,
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // ═══════════════════════════════════
                        // ✅ الاسم + الآيقونة النشطة
                        // ═══════════════════════════════════
                        _buildNameWithIcon(context, profile),

                        // ─── النبذة ───
                        if (profile.bio != null &&
                            profile.bio!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              profile.bio!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // ─── النقاط ───
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars,
                                  color: Colors.amber, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                '${profile.points} ${T.get(context, 'points')}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ─── متابعون + يتابع ───
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatButton(
                              icon: Icons.people,
                              label: 'متابعون',
                              count: _followersCount,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FollowersScreen(
                                      userId: profile.id,
                                      showFollowers: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withValues(alpha: 0.3),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 24),
                            ),
                            _buildStatButton(
                              icon: Icons.person_add,
                              label: 'يتابع',
                              count: _followingCount,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FollowersScreen(
                                      userId: profile.id,
                                      showFollowers: false,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        // ─── شارة ADMIN ───
                        if (profile.isAdmin)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.warning, AppTheme.accent],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ═══════════════════════════════════
                  // صوري
                  // ═══════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          T.get(context, 'my_photos'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UploadScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(T.get(context, 'add')),
                        ),
                      ],
                    ),
                  ),

                  Consumer<PhotoProvider>(
                    builder: (context, photos, _) {
                      if (photos.userPhotos.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('لا توجد صور بعد'),
                        );
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: photos.userPhotos.length,
                        itemBuilder: (context, index) {
                          final photo = photos.userPhotos[index];
                          return PhotoCard(
                            photo: photo,
                            showFavoriteButton: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PhotoDetailsScreen(photo: photo),
                                ),
                              );
                            },
                            onEdit: () => _showEditPhotoDialog(photo),
                            onDelete: () => _confirmDeletePhoto(photo),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ✅ بناء الاسم مع الآيقونة النشطة
  // ═══════════════════════════════════════════════
  Widget _buildNameWithIcon(BuildContext context, dynamic profile) {
    final hasIcon = profile.activeIconUrl != null &&
        (profile.activeIconUrl as String).isNotEmpty &&
        profile.activeIconExpiresAt != null &&
        (profile.activeIconExpiresAt as DateTime).isAfter(DateTime.now());

    final expiringSoon = hasIcon &&
        profile.activeIconDaysRemaining <= 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasIcon)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Tooltip(
              message: expiringSoon
                  ? 'آيقونتك ستنتهي خلال ${profile.activeIconDaysRemaining} يوم'
                  : 'آيقونة نشطة • ${profile.activeIconDaysRemaining} يوم متبقٍ',
              child: SizedBox(
                width: 36,
                height: 36,
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: profile.activeIconUrl as String,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox.shrink(),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        Flexible(
          child: Text(
            profile.username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatButton({
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditPhotoDialog(PhotoModel photo) async {
    // ✅ التقاط context قبل أي await
    final photoProvider = context.read<PhotoProvider>();
    final catProvider = context.read<CategoriesProvider>();
    final messenger = ScaffoldMessenger.of(context);

    // ✅ تأكد من تحميل التصنيفات
    if (catProvider.enabled.isEmpty) {
      try {
        await catProvider.load();
      } catch (_) {}
    }

    // ✅ التحقق من mounted بعد await
    if (!mounted) return;

    // ✅ اقرأ التصنيفات من CategoriesProvider (بعد await مضمون)
    final dynamicCategories = catProvider.categoriesAsMap
        .where((c) => c['key'] != 'all')
        .toList();

    // احتياط: إذا القائمة فارغة → استخدم الافتراضية
    final fallbackCategories = AppConstants.photoCategories
        .where((c) => c['key'] != 'all')
        .toList();

    final listToUse = dynamicCategories.isEmpty
        ? fallbackCategories
        : dynamicCategories;

    final titleController = TextEditingController(text: photo.title);
    final priceController =
        TextEditingController(text: photo.price.toString());
    String category = photo.category;

    // تأكد أن التصنيف الحالي موجود في القائمة
    final isValidCategory =
        listToUse.any((c) => c['key'] == category);

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('تعديل الصورة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: photo.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: isValidCategory ? category : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'التصنيف',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: listToUse
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['key'],
                          child: Text(
                            c['ar'] ?? c['en'] ?? c['key'] ?? '',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => category = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'السعر (0 = مجاني)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await photoProvider.updatePhoto(
                    photoId: photo.id,
                    title: titleController.text.trim(),
                    category: category,
                    price: double.tryParse(priceController.text) ?? 0,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث الصورة'),
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
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeletePhoto(PhotoModel photo) async {
    final photoProvider = context.read<PhotoProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الصورة'),
        content: Text('هل أنت متأكد من حذف "${photo.title}" نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await photoProvider.deletePhoto(
        photoId: photo.id,
        imageUrl: photo.imageUrl,
      );
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('تم حذف الصورة'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(Helpers.errorMessage(e)),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}
