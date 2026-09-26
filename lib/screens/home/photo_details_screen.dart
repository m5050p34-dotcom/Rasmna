import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:provider/provider.dart';

import '../../models/photo_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/photo_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../profile/photographer_screen.dart';

class PhotoDetailsScreen extends StatefulWidget {
  final PhotoModel photo;
  const PhotoDetailsScreen({super.key, required this.photo});

  @override
  State<PhotoDetailsScreen> createState() => _PhotoDetailsScreenState();
}

class _PhotoDetailsScreenState extends State<PhotoDetailsScreen> {
  final _photoService = PhotoService();
  bool _isPurchasing = false;
  bool _isDownloading = false;
  bool? _hasPurchased;

  bool get _isOwner =>
      context.read<AuthProvider>().userId == widget.photo.userId;

  bool get _canDownload =>
      widget.photo.isFree || _isOwner || (_hasPurchased ?? false);

  bool get _isTransparent =>
      widget.photo.format == 'png' || widget.photo.format == 'webp';

  @override
  void initState() {
    super.initState();
    _checkPurchaseStatus();
  }

  Future<void> _checkPurchaseStatus() async {
    if (_isOwner || widget.photo.isFree) {
      if (mounted) setState(() => _hasPurchased = true);
      return;
    }
    try {
      final purchased = await _photoService.hasPurchased(widget.photo.id);
      if (mounted) setState(() => _hasPurchased = purchased);
    } catch (_) {
      if (mounted) setState(() => _hasPurchased = false);
    }
  }

  void _openFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenPhotoViewer(
          imageUrl: widget.photo.imageUrl,
          title: widget.photo.title,
        ),
      ),
    );
  }

  void _openPhotographerProfile() {
    if (_isOwner) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotographerScreen(userId: widget.photo.userId),
      ),
    );
  }

  Future<void> _purchase() async {
    final auth = context.read<AuthProvider>();
    final profile = auth.profile;
    if (profile == null) return;

    if (profile.points < widget.photo.price) {
      _showSnack(
        '💰 رصيدك غير كافٍ. تحتاج ${widget.photo.price.toInt()} نقطة',
        AppTheme.warning,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الشراء'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'هل تريد شراء "${widget.photo.title}" مقابل '
              '${widget.photo.price.toInt()} نقطة؟',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet,
                      color: AppTheme.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'رصيدك: ${profile.points} نقطة',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
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
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('شراء'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isPurchasing = true);
    try {
      await _photoService.purchasePhoto(widget.photo.id);
      await auth.refreshProfile();
      if (mounted) {
        setState(() => _hasPurchased = true);
        _showSnack('🎉 تم الشراء بنجاح! يمكنك التحميل الآن', AppTheme.success);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(Helpers.errorMessage(e), AppTheme.error);
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  // ═══════════════════════════════════════════════
  // 📥 تحميل الصورة (يدعم الشفافية)
  // ═══════════════════════════════════════════════
  Future<void> _download() async {
    if (!_canDownload) {
      _showSnack('🔒 يجب شراء الصورة أولاً للتحميل', AppTheme.warning);
      return;
    }

    setState(() => _isDownloading = true);
    try {
      final response = await http.get(Uri.parse(widget.photo.imageUrl));
      if (response.statusCode != 200) {
        throw Exception('فشل التحميل (${response.statusCode})');
      }

      final format = widget.photo.format.isNotEmpty
          ? widget.photo.format.toLowerCase()
          : 'jpg';
      final isTrans = format == 'png' || format == 'webp';

      final safeTitle = widget.photo.title
          .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '_')
          .trim();
      final fileName =
          'Rasmna_${safeTitle}_${DateTime.now().millisecondsSinceEpoch}';

      final Uint8List bytes = response.bodyBytes;
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: fileName,
      );

      if (result == null || result['isSuccess'] != true) {
        throw Exception('فشل الحفظ: ${result?['errorMessage']}');
      }

      if (mounted) {
        _showSnack(
          isTrans
              ? '✅ تم حفظ الصورة (${format.toUpperCase()} شفاف) في المعرض'
              : '✅ تم حفظ الصورة في معرض الصور',
          AppTheme.success,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack('فشل التحميل: ${Helpers.errorMessage(e)}', AppTheme.error);
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    final isFav = context.watch<FavoritesProvider>().isFavorited(photo.id);
    final format = photo.format.isNotEmpty ? photo.format.toUpperCase() : 'JPG';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? AppTheme.secondary : Colors.white,
                ),
                onPressed: () async {
                  try {
                    await context
                        .read<FavoritesProvider>()
                        .toggleFavorite(photo.id);
                    if (mounted) {
                      _showSnack(
                        isFav ? 'أُزيلت من المفضلة' : 'أُضيفت إلى المفضلة ❤️',
                        isFav ? Colors.grey.shade700 : AppTheme.secondary,
                      );
                    }
                  } catch (_) {}
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'photo_${photo.id}',
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: photo.imageUrl,
                    fit: _isTransparent ? BoxFit.contain : BoxFit.cover,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── العنوان + شارة الشفافية ───
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          photo.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_isTransparent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.success, AppTheme.primary],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'شفاف',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ─── المصور (قابل للضغط) + التصنيف ───
                  Row(
                    children: [
                      InkWell(
                        onTap: _openPhotographerProfile,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.primary,
                                backgroundImage: (photo.owner?.avatarUrl !=
                                            null &&
                                        photo.owner!.avatarUrl!.isNotEmpty)
                                    ? CachedNetworkImageProvider(
                                        photo.owner!.avatarUrl!)
                                    : null,
                                child: (photo.owner?.avatarUrl == null ||
                                        photo.owner!.avatarUrl!.isEmpty)
                                    ? Text(
                                        photo.owner?.initial ?? '?',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    photo.ownerName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'اضغط لعرض الملف الشخصي',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              if (!_isOwner)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: AppTheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppConstants.photoCategories.firstWhere(
                            (c) => c['key'] == photo.category,
                            orElse: () =>
                                {'ar': photo.category, 'en': photo.category},
                          )['ar']!,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _openFullscreen,
                      icon: const Icon(Icons.fullscreen, size: 24),
                      label: const Text(
                        'معاينة كاملة الشاشة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(
                          color: AppTheme.primary,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── بطاقة السعر ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: photo.isFree
                            ? [AppTheme.success, AppTheme.success]
                            : [AppTheme.primary, AppTheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          photo.isFree ? Icons.download : Icons.stars,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              photo.isFree
                                  ? 'مجاني للتحميل'
                                  : '${photo.price.toInt()} نقطة',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _isTransparent
                                  ? '$format • بدون خلفية (شفاف)'
                                  : '$format • عالية الجودة',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ─── قسم الشراء/التحميل ───
                  if (_isOwner)
                    _ownerSection()
                  else if (photo.isFree)
                    _downloadButton()
                  else if (_hasPurchased == true)
                    _purchasedSection()
                  else
                    _purchaseSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info, color: AppTheme.warning),
              SizedBox(width: 8),
              Expanded(child: Text('هذه صورتك — يمكنك تحميلها بحرية')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _downloadButton(),
      ],
    );
  }

  Widget _purchasedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.success),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✅ اشتريت هذه الصورة — يمكنك التحميل الآن',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _downloadButton(),
      ],
    );
  }

  Widget _purchaseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _isPurchasing ? null : _purchase,
            icon: _isPurchasing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.shopping_cart, size: 22),
            label: Text(
              _isPurchasing
                  ? 'جارٍ الشراء...'
                  : 'شراء بـ ${widget.photo.price.toInt()} نقطة',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () => _showSnack(
              '🔒 يجب شراء الصورة أولاً للتحميل',
              AppTheme.warning,
            ),
            icon: const Icon(Icons.lock, size: 22),
            label: const Text(
              'تحميل (مقفل - يتطلب شراء)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade400,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _downloadButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
        onPressed: _isDownloading ? null : _download,
        icon: _isDownloading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.download, size: 22),
        label: Text(
          _isDownloading ? 'جارٍ التحميل...' : 'تحميل الصورة',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _FullScreenPhotoViewer extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _FullScreenPhotoViewer({
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 6.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white, size: 64),
            ),
          ),
        ),
      ),
    );
  }
}
