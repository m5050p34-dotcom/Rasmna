import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/photo_model.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/points_provider.dart';
import '../../services/follows_service.dart';
import '../../services/profile_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/gift_points_dialog.dart';
import '../../widgets/photo_card.dart';
import '../home/photo_details_screen.dart';

class PhotographerScreen extends StatefulWidget {
  final String userId;
  const PhotographerScreen({super.key, required this.userId});

  @override
  State<PhotographerScreen> createState() => _PhotographerScreenState();
}

class _PhotographerScreenState extends State<PhotographerScreen> {
  final _profileService = ProfileService();
  final _followsService = FollowsService();

  ProfileModel? _profile;
  List<PhotoModel> _photos = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _profileService.getProfile(widget.userId);
      final photos =
          await _profileService.getPhotographerPhotos(widget.userId);
      final stats = await _followsService.getPhotographerStats(widget.userId);

      if (mounted) {
        setState(() {
          _profile = profile;
          _photos = photos;
          _stats = {
            'photos_count': stats.photosCount,
            'followers_count': stats.followersCount,
            'following_count': stats.followingCount,
          };
          _isFollowing = stats.isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    if (currentUserId == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكنك متابعة نفسك')),
      );
      return;
    }

    setState(() => _isFollowLoading = true);
    try {
      final nowFollowing = await _followsService.toggleFollow(widget.userId);
      if (mounted) {
        setState(() => _isFollowing = nowFollowing);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nowFollowing ? '✅ تتابع الآن هذا المصور' : 'أُلغيت المتابعة',
            ),
            duration: const Duration(seconds: 1),
            backgroundColor:
                nowFollowing ? AppTheme.success : Colors.grey.shade700,
          ),
        );
        _load();
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
    } finally {
      if (mounted) setState(() => _isFollowLoading = false);
    }
  }

  // ═══════════════════════════════════════════════
  // 🎁 فتح نافذة إرسال هدية
  // ═══════════════════════════════════════════════
  Future<void> _openGiftDialog() async {
    if (_profile == null) return;

    final auth = context.read<AuthProvider>();
    final pointsProvider = context.read<PointsProvider>();

    final result = await showGiftPointsDialog(
      context: context,
      recipient: _profile!,
      currentBalance: auth.profile?.points ?? 0,
    );

    if (result == null) return;

    // تنفيذ التحويل
    try {
      final transferResult = await pointsProvider.transferPoints(
        recipientId: _profile!.id,
        amount: result.amount,
        message: result.message,
      );

      await auth.refreshProfile();

      if (!mounted) return;

      _showSuccessDialog(transferResult);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Helpers.errorMessage(e)),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessDialog(dynamic result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppTheme.success, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('تم التحويل! 🎁'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('أرسلت', '${result.sentAmount} نقطة', AppTheme.error),
            _row('استلم', '${result.recipientReceived} نقطة', AppTheme.success),
            _row('عمولة الإدارة', '${result.commission} نقطة', AppTheme.warning),
            const Divider(height: 24),
            _row('رصيدك الجديد', '${result.newSenderBalance} نقطة',
                AppTheme.primary),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تمام'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('المصور')),
        body: const Center(child: Text('المستخدم غير موجود')),
      );
    }

    final profile = _profile!;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnProfile = currentUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(title: Text(profile.username)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ═══════════════════════════════════
              // رأس المصور
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
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          (profile.avatarUrl != null &&
                                  profile.avatarUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(profile.avatarUrl!)
                              : null,
                      child: (profile.avatarUrl == null ||
                              profile.avatarUrl!.isEmpty)
                          ? Text(
                              profile.initial,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
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

                    // ─── الإحصائيات ───
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _statItem('${_stats?['photos_count'] ?? 0}', 'صورة'),
                        Container(
                          height: 30,
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.3),
                          margin: const EdgeInsets.symmetric(horizontal: 30),
                        ),
                        _statItem(
                            '${_stats?['followers_count'] ?? 0}', 'متابع'),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ═══════════════════════════════════
                    // أزرار: متابعة + هدية (للمستخدمين الآخرين)
                    // ═══════════════════════════════════
                    if (!isOwnProfile)
                      Row(
                        children: [
                          // زر المتابعة
                          Expanded(
                            flex: 3,
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _isFollowLoading ? null : _toggleFollow,
                                icon: _isFollowLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        _isFollowing
                                            ? Icons.person_remove
                                            : Icons.person_add,
                                      ),
                                label: Text(
                                  _isFollowing ? 'إلغاء المتابعة' : 'متابعة',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isFollowing
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.white,
                                  foregroundColor: _isFollowing
                                      ? Colors.white
                                      : AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 🎁 زر الهدية
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _openGiftDialog,
                                icon: const Icon(Icons.card_giftcard, size: 20),
                                label: const Text(
                                  'هدية',
                                  style: TextStyle(fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppTheme.accent.withValues(alpha: 0.9),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // ─── صور المصور ───
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library,
                        color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'صور المصور (${_photos.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              if (_photos.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.photo_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('لا توجد صور'),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return PhotoCard(
                      photo: photo,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PhotoDetailsScreen(photo: photo),
                          ),
                        );
                      },
                    );
                  },
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
