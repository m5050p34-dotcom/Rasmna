import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/photo_model.dart';
import '../providers/favorites_provider.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';

class PhotoCard extends StatelessWidget {
  final PhotoModel photo;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showFavoriteButton;

  const PhotoCard({
    super.key,
    required this.photo,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showFavoriteButton = true,
  });

  bool get _isTransparent =>
      photo.format == 'png' || photo.format == 'webp';

  // ✅ التحقق المبسّط: يكفي وجود رابط غير فارغ
  bool get _ownerHasIcon {
    final url = photo.owner?.activeIconUrl;
    return url != null && url.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAvatar = photo.owner?.avatarUrl != null &&
        photo.owner!.avatarUrl!.isNotEmpty;

    // 🔍 Log للتشخيص
    debugPrint(
      '🖼️ CARD: ${photo.title} | owner=${photo.owner?.username} | '
      'iconUrl=${photo.owner?.activeIconUrl} | hasIcon=$_ownerHasIcon',
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════
              // الصورة
              // ═══════════════════════════════════
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isTransparent
                              ? null
                              : (isDark
                                  ? const Color(0xFF252540)
                                  : const Color(0xFFF1F2F8)),
                          gradient: _isTransparent
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isDark
                                      ? const [
                                          Color(0xFF2A2A4A),
                                          Color(0xFF353560),
                                          Color(0xFF2A2A4A),
                                          Color(0xFF353560),
                                        ]
                                      : const [
                                          Color(0xFFE8E8E8),
                                          Color(0xFFF8F8F8),
                                          Color(0xFFE8E8E8),
                                          Color(0xFFF8F8F8),
                                        ],
                                  stops: const [0.0, 0.25, 0.5, 0.75],
                                )
                              : null,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: photo.imageUrl,
                        fit: _isTransparent ? BoxFit.contain : BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 200),
                        placeholder: (_, __) => const SizedBox.shrink(),
                        errorWidget: (_, __, ___) => Container(
                          color: isDark
                              ? const Color(0xFF252540)
                              : const Color(0xFFF1F2F8),
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 32,
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // شارة "متعددة"
                    if (photo.isPartOfGroup)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.collections,
                                  color: Colors.white, size: 11),
                              SizedBox(width: 3),
                              Text(
                                'متعددة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // شارة PNG
                    if (_isTransparent)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.success, AppTheme.primary],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 9),
                              SizedBox(width: 3),
                              Text(
                                'PNG',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ═══════════════════════════════════
              // البيانات
              // ═══════════════════════════════════
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ─── العنوان ───
                      Text(
                        photo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A2E),
                        ),
                      ),

                      // ─── الصف: Avatar + Icon + Name ───
                      Row(
                        children: [
                          // Avatar
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: ClipOval(
                              child: hasAvatar
                                  ? CachedNetworkImage(
                                      imageUrl: photo.owner!.avatarUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => _avatarInitial(),
                                      errorWidget: (_, __, ___) =>
                                          _avatarInitial(),
                                    )
                                  : _avatarInitial(),
                            ),
                          ),
                          const SizedBox(width: 5),

                          // ✅ الأيقونة (إن وُجدت)
                          if (_ownerHasIcon) ...[
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: photo.owner!.activeIconUrl!,
                                  fit: BoxFit.cover,
                                  fadeInDuration: Duration.zero,
                                  placeholder: (_, __) => _iconFallback(),
                                  errorWidget: (_, __, ___) => _iconFallback(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],

                          // Name
                          Expanded(
                            child: Text(
                              photo.ownerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ─── الصف: السعر + القلب ───
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: photo.isFree
                                      ? [
                                          AppTheme.success,
                                          AppTheme.success
                                              .withValues(alpha: 0.75),
                                        ]
                                      : [
                                          AppTheme.primary,
                                          AppTheme.secondary,
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    photo.isFree
                                        ? Icons.download_rounded
                                        : Icons.stars_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      Helpers.formatPrice(photo.price),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (showFavoriteButton) ...[
                            const SizedBox(width: 6),
                            Selector<FavoritesProvider, bool>(
                              selector: (_, favs) =>
                                  favs.isFavorited(photo.id),
                              builder: (context, isFav, _) {
                                return GestureDetector(
                                  onTap: () async {
                                    try {
                                      final favs = context
                                          .read<FavoritesProvider>();
                                      await favs.toggleFavorite(photo.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isFav
                                                  ? 'أُزيلت من المفضلة'
                                                  : 'أُضيفت إلى المفضلة ❤️',
                                            ),
                                            duration: const Duration(
                                                milliseconds: 900),
                                            backgroundColor: isFav
                                                ? Colors.grey.shade700
                                                : AppTheme.secondary,
                                          ),
                                        );
                                      }
                                    } catch (_) {}
                                  },
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: isFav
                                          ? AppTheme.secondary
                                              .withValues(alpha: 0.15)
                                          : (isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.08)
                                              : Colors.grey
                                                  .withValues(alpha: 0.12)),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isFav
                                            ? AppTheme.secondary
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      isFav
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFav
                                          ? AppTheme.secondary
                                          : (isDark
                                              ? Colors.white70
                                              : Colors.black54),
                                      size: 16,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                          if (onEdit != null || onDelete != null) ...[
                            if (onEdit != null)
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: onEdit,
                              ),
                            if (onDelete != null) ...[
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 16, color: AppTheme.error),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: onDelete,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarInitial() {
    return Container(
      color: AppTheme.primary,
      alignment: Alignment.center,
      child: Text(
        photo.owner?.initial ?? '?',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // ✅ بديل عند فشل تحميل الأيقونة — مربع بنفسجي صغير
  Widget _iconFallback() {
    return Container(
      color: AppTheme.secondary.withValues(alpha: 0.4),
      alignment: Alignment.center,
      child: const Icon(
        Icons.stars,
        size: 10,
        color: Colors.white,
      ),
    );
  }
}
