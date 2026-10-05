import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:provider/provider.dart';

import '../../models/photo_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/photo_provider.dart';
import '../../services/photo_service.dart';
import '../../services/reports_service.dart';
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
  final _reportsService = ReportsService();
  final _pageController = PageController();

  List<PhotoModel> _groupImages = [];
  int _currentIndex = 0;
  bool _groupLoading = false;

  bool _isPurchasing = false;
  bool _isDownloading = false;
  bool? _hasPurchased;
  bool _hasReported = false;

  PhotoModel get _currentPhoto =>
      _groupImages.isEmpty ? widget.photo : _groupImages[_currentIndex];

  bool get _isOwner =>
      context.read<AuthProvider>().userId == widget.photo.userId;

  bool get _canDownload =>
      widget.photo.isFree || _isOwner || (_hasPurchased ?? false);

  bool get _isTransparent {
    final f = _currentPhoto.format;
    return f == 'png' || f == 'webp';
  }

  bool get _isMultiGroup => _groupImages.length > 1;

  @override
  void initState() {
    super.initState();
    _loadGroupIfNeeded();
    _checkPurchaseStatus();
    _checkReportedStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════
  // 📥 تحميل صور المجموعة إن وُجدت
  // ═══════════════════════════════════════════════
  Future<void> _loadGroupIfNeeded() async {
    if (!widget.photo.isPartOfGroup) {
      _groupImages = [widget.photo];
      return;
    }

    setState(() => _groupLoading = true);
    try {
      final images = await context
          .read<PhotoProvider>()
          .getGroupPhotos(widget.photo.groupId!);

      if (mounted) {
        setState(() {
          _groupImages = images.isEmpty ? [widget.photo] : images;
          _currentIndex = images.indexWhere((p) => p.id == widget.photo.id);
          if (_currentIndex < 0) _currentIndex = 0;
          _groupLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _groupImages = [widget.photo];
          _groupLoading = false;
        });
      }
    }
  }

  Future<void> _checkPurchaseStatus() async {
    if (_isOwner || widget.photo.isFree) {
      if (mounted) setState(() => _hasPurchased = true);
      return;
    }
    try {
      final purchased = widget.photo.isPartOfGroup
          ? await _photoService.hasPurchasedGroup(widget.photo.groupId!)
          : await _photoService.hasPurchased(widget.photo.id);
      if (mounted) setState(() => _hasPurchased = purchased);
    } catch (_) {
      if (mounted) setState(() => _hasPurchased = false);
    }
  }

  Future<void> _checkReportedStatus() async {
    try {
      final reported = await _reportsService.hasReported(widget.photo.id);
      if (mounted) setState(() => _hasReported = reported);
    } catch (_) {}
  }

  void _openFullscreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenPhotoViewer(
          images: _groupImages,
          initialIndex: _currentIndex,
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

  // ═══════════════════════════════════════════════
  // 🛒 الشراء
  // ═══════════════════════════════════════════════
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
            if (_isMultiGroup) ...[
              Row(
                children: [
                  const Icon(Icons.collections, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${_groupImages.length} صور في هذه المجموعة',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
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
      if (widget.photo.isPartOfGroup) {
        await _photoService.purchasePhotoGroup(widget.photo.groupId!);
      } else {
        await _photoService.purchasePhoto(widget.photo.id);
      }
      await auth.refreshProfile();
      if (mounted) {
        setState(() => _hasPurchased = true);
        _showSnack('🎉 تم الشراء بنجاح! يمكنك التحميل الآن', AppTheme.success);
      }
    } catch (e) {
      if (mounted) _showSnack(Helpers.errorMessage(e), AppTheme.error);
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  // ═══════════════════════════════════════════════
  // ⬇️ التحميل
  // ═══════════════════════════════════════════════
  Future<void> _download() async {
    if (!_canDownload) {
      _showSnack('🔒 يجب شراء الصورة أولاً للتحميل', AppTheme.warning);
      return;
    }

    setState(() => _isDownloading = true);
    try {
      final imagesToDownload =
          _isMultiGroup ? _groupImages : [_currentPhoto];

      for (int i = 0; i < imagesToDownload.length; i++) {
        final photo = imagesToDownload[i];
        final response = await http.get(Uri.parse(photo.imageUrl));
        if (response.statusCode != 200) continue;
        final safeTitle = photo.title
            .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '_')
            .trim();
        final fileName =
            'Rasmna_${safeTitle}_${DateTime.now().millisecondsSinceEpoch}';

        final Uint8List bytes = response.bodyBytes;
        await ImageGallerySaverPlus.saveImage(
          bytes,
          quality: 100,
          name: fileName,
        );
      }

      if (mounted) {
        _showSnack(
          _isMultiGroup
              ? '✅ تم حفظ ${imagesToDownload.length} صور في المعرض'
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

  // ═══════════════════════════════════════════════
  // 🚨 الإبلاغ
  // ═══════════════════════════════════════════════
  Future<void> _showReportDialog() async {
    final reasons = [
      'محتوى مخالف',
      'انتهاك حقوق الملكية',
      'محتوى غير لائق',
      'معلومة مضللة',
      'إعلان مزعج',
      'أخرى',
    ];

    String? selectedReason;
    final detailsController = TextEditingController();
    bool isSubmitting = false;
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
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
                child: const Icon(Icons.flag,
                    color: AppTheme.error, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('الإبلاغ عن الصورة',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اختر سبب الإبلاغ:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ...reasons.map(
                  (reason) => InkWell(
                    onTap: isSubmitting
                        ? null
                        : () => setDialogState(
                            () => selectedReason = reason),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedReason == reason
                                    ? AppTheme.error
                                    : Colors.grey.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: selectedReason == reason
                                ? Center(
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selectedReason == reason
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: selectedReason == reason
                                    ? AppTheme.error
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  maxLength: 200,
                  enabled: !isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'تفاصيل (اختياري)',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: selectedReason == null || isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      try {
                        await _reportsService.submitReport(
                          photoId: widget.photo.id,
                          reason: selectedReason!,
                          details: detailsController.text.trim().isEmpty
                              ? null
                              : detailsController.text.trim(),
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, false);
                        }
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(Helpers.errorMessage(e)),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
              ),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, size: 18),
              label: Text(isSubmitting ? 'جارٍ...' : 'إرسال'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      if (mounted) setState(() => _hasReported = true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ تم إرسال البلاغ. شكراً لك!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    final isFav = context.watch<FavoritesProvider>().isFavorited(photo.id);
    final current = _currentPhoto;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            actions: [
              if (!_isOwner)
                IconButton(
                  icon: Icon(
                    _hasReported ? Icons.flag : Icons.outlined_flag,
                    color: _hasReported ? AppTheme.error : Colors.white,
                  ),
                  onPressed: _hasReported ? null : _showReportDialog,
                ),
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
              background: _groupLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isMultiGroup
                      ? _buildImagePager()
                      : _buildSingleImage(current),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isMultiGroup) ...[
                    _buildThumbnails(),
                    const SizedBox(height: 16),
                  ],
                  _buildTitleRow(current),
                  const SizedBox(height: 12),
                  _buildOwnerRow(photo),
                  const SizedBox(height: 20),
                  _buildPreviewButton(),
                  const SizedBox(height: 20),
                  if (_isOwner)
                    _ownerSection()
                  else if (photo.isFree)
                    _downloadButton()
                  else if (_hasPurchased == true)
                    _purchasedSection()
                  else
                    _purchaseSection(),
                  const SizedBox(height: 20),
                  _buildPhotoInfoCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 🖼️ PageView للصور المتعددة
  // ═══════════════════════════════════════════════
  Widget _buildImagePager() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _groupImages.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (context, index) {
            final img = _groupImages[index];
            final isTrans =
                img.format == 'png' || img.format == 'webp';
            return GestureDetector(
              onTap: _openFullscreen,
              child: Hero(
                tag: 'photo_${img.id}',
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: img.imageUrl,
                    fit: isTrans ? BoxFit.contain : BoxFit.cover,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            );
          },
        ),
        // عداد
        Positioned(
          top: 60,
          right: 16,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentIndex + 1} / ${_groupImages.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleImage(PhotoModel photo) {
    final isTrans = photo.format == 'png' || photo.format == 'webp';
    return GestureDetector(
      onTap: _openFullscreen,
      child: Hero(
        tag: 'photo_${photo.id}',
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: photo.imageUrl,
            fit: isTrans ? BoxFit.contain : BoxFit.cover,
            placeholder: (_, __) =>
                const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 📸 شريط الصور المصغّرة
  // ═══════════════════════════════════════════════
  Widget _buildThumbnails() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _groupImages.length,
        itemBuilder: (context, index) {
          final isSelected = index == _currentIndex;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: _groupImages[index].imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleRow(PhotoModel photo) {
    final isTrans = photo.format == 'png' || photo.format == 'webp';
    return Row(
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
        if (isTrans)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
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
    );
  }

  Widget _buildOwnerRow(PhotoModel photo) {
    return Row(
      children: [
        InkWell(
          onTap: _openPhotographerProfile,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primary,
                  backgroundImage:
                      (photo.owner?.avatarUrl != null &&
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
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
  }

  Widget _buildPreviewButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: _openFullscreen,
        icon: const Icon(Icons.fullscreen, size: 24),
        label: const Text(
          'معاينة كاملة الشاشة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primary,
          side: const BorderSide(color: AppTheme.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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
        SizedBox(
          width: double.infinity,
          height: 54,
          child: _downloadButton(),
        ),
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
            border: Border.all(
                color: AppTheme.success.withValues(alpha: 0.3)),
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
        // ✅ الأزرار في Row: التحميل (أخضر) + المعاينة (أزرق)
        Row(
          children: [
            Expanded(child: _downloadButton()),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _openFullscreen,
                  icon: const Icon(Icons.fullscreen, size: 22),
                  label: const Text(
                    'معاينة كاملة',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _purchaseSection() {
    return Row(
      children: [
        // ✅ التحميل أولاً (يسار بصرياً)
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _showSnack(
                '🔒 يجب شراء الصورة أولاً للتحميل',
                AppTheme.warning,
              ),
              icon: const Icon(Icons.lock, size: 20),
              label: const Text(
                'تحميل',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // ✅ الشراء ثانياً (يمين بصرياً)
        Expanded(
          child: SizedBox(
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
                  : const Icon(Icons.shopping_cart, size: 20),
              label: Text(
                _isPurchasing
                    ? 'جارٍ...'
                    : _isMultiGroup
                        ? 'شراء ${_groupImages.length} صور'
                        : 'شراء بـ ${widget.photo.price.toInt()} نقطة',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _downloadButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _isDownloading ? null : _download,
        icon: _isDownloading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.download, size: 20),
        label: Text(
          _isDownloading
              ? 'جارٍ...'
              : _isMultiGroup
                  ? 'تحميل ${_groupImages.length} صور'
                  : 'تحميل الصورة',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 📅 بطاقة المعلومات السفلية
  // ═══════════════════════════════════════════════
  Widget _buildPhotoInfoCard() {
    final photo = widget.photo;
    final format = photo.format.isNotEmpty
        ? photo.format.toUpperCase()
        : 'JPG';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_today,
                    color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تاريخ النشر',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(photo.createdAt),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
              height: 1,
              color: AppTheme.primary.withValues(alpha: 0.1)),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.image_outlined,
                    color: AppTheme.secondary, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الصيغة',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(
                    _isTransparent ? '$format • شفاف' : '$format • عالي',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: photo.isFree
                        ? [AppTheme.success, AppTheme.success]
                        : [AppTheme.primary, AppTheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      photo.isFree ? Icons.download_done : Icons.stars,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      photo.isFree
                          ? 'مجاني'
                          : '${photo.price.toInt()} نقطة',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
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
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ═══════════════════════════════════════════════
// 🖼️ عارض كامل الشاشة (يدعم مجموعة صور)
// ═══════════════════════════════════════════════
class _FullScreenPhotoViewer extends StatefulWidget {
  final List<PhotoModel> images;
  final int initialIndex;
  final String title;

  const _FullScreenPhotoViewer({
    required this.images,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<_FullScreenPhotoViewer> createState() =>
      _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ═══════════════════════════════════════
          // عرض الصور (بالسحب بين الصور المتعددة)
          // ═══════════════════════════════════════
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => Navigator.pop(context),
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 6.0,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: widget.images[index].imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // ═══════════════════════════════════════
          // زر الإغلاق (فوق يسار)
          // ═══════════════════════════════════════
          Positioned(
            top: 40,
            left: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════
          // عداد الصور (فقط إذا كانت متعددة)
          // ═══════════════════════════════════════
          if (widget.images.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_index + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
