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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    // ─── خلفية رقعة الشطرنج للصور الشفافة ───
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

                    // ─── الصورة ───
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

                    // ═══════════════════════════════════
                    // 🎨 شارة الشفافية
                    // ═══════════════════════════════════
                    if (_isTransparent)
                      Positioned(
                        top: 40,
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
                                color:
                                    Colors.black.withValues(alpha: 0.2),
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

                    // ─── زر القلب (يسار أعلى) ───
                    if (showFavoriteButton)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Selector<FavoritesProvider, bool>(
                          selector: (_, favs) =>
                              favs.isFavorited(photo.id),
                          builder: (context, isFav, _) {
                            return GestureDetector(
                              onTap: () async {
                                try {
                                  final favs =
                                      context.read<FavoritesProvider>();
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
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFav
                                      ? AppTheme.secondary
                                      : Colors.white,
                                  size: 18,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // ─── شارة السعر (يمين أعلى) ───
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: photo.isFree
                              ? AppTheme.success
                              : AppTheme.primary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          Helpers.formatPrice(photo.price),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
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
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 13,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  photo.ownerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (onEdit != null || onDelete != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (onEdit != null)
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: onEdit,
                              ),
                            if (onDelete != null) ...[
                              const SizedBox(width: 8),
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
}
