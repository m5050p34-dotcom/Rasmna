import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/banner_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/photo_provider.dart';
import '../../providers/sort_provider.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../utils/app_theme.dart';
import '../../utils/translations.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/bottom_banner_ad.dart';
import '../../services/update_checker_service.dart';
import '../../widgets/main_drawer.dart';
import '../../widgets/update_dialog.dart';
import '../../widgets/photo_card.dart';
import '../upload/upload_screen.dart';
import 'photo_details_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAll();
      await _checkForUpdate();
    });
  }

  // ═══════════════════════════════════════════════
  // ✅ فحص التحديثات عند كل فتح للسوق
  // ═══════════════════════════════════════════════
  Future<void> _checkForUpdate() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      final checker = UpdateCheckerService();
      final version = await checker.shouldShowUpdate();

      if (version == null || !mounted) return;

      // عرض الديالوج
      await UpdateDialog.show(context, version);

      // إذا اختياري → احفظ أنه رآه
      if (!version.isMandatory) {
        await checker.markAsSeen(version.versionCode);
      }
    } catch (e) {
      debugPrint('Update check error: $e');
    }
  }

  Future<void> _loadAll() async {
    final photoProvider = context.read<PhotoProvider>();
    final bannerProvider = context.read<BannerProvider>();
    final sortProvider = context.read<SortProvider>();
    final catProvider = context.read<CategoriesProvider>();
    final notifProvider = context.read<NotificationsProvider>();

    try {
      await catProvider.load();
    } catch (_) {}
    try {
      await photoProvider.fetchPhotos();
    } catch (_) {}
    try {
      await sortProvider.fetchSortOptions();
    } catch (_) {}
    try {
      await bannerProvider.loadAll();
    } catch (_) {}
    try {
      await notifProvider.loadAll();
      notifProvider.subscribeRealtime();
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(T.get(context, 'app_name')),
        actions: [
          // ─── 🔍 البحث ───
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),

          // ─── 🔔 الإشعارات ───
          Consumer<NotificationsProvider>(
            builder: (context, provider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    tooltip: 'الإشعارات',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (provider.hasUnread)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                Theme.of(context).appBarTheme.backgroundColor ??
                                    Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          provider.unreadCount > 9
                              ? '9+'
                              : '${provider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // ─── ➕ رفع صورة (جديد) ───
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'رفع صورة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UploadScreen(),
                ),
              );
            },
          ),

          const SizedBox(width: 4),
        ],
      ),
      drawer: const MainDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: BannerCarousel()),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: Consumer2<PhotoProvider, CategoriesProvider>(
                        builder: (context, photo, cats, _) {
                          final categories = cats.categoriesAsMap;
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final isSel =
                                  photo.selectedCategory == cat['key'];
                              final isArabic = Localizations.localeOf(context)
                                      .languageCode ==
                                  'ar';
                              final label = isArabic
                                  ? cat['ar']!
                                  : cat['en'] ?? cat['ar']!;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                                child: FilterChip(
                                  label: Text(label),
                                  selected: isSel,
                                  onSelected: (_) => photo.fetchPhotos(
                                      category: cat['key']),
                                  selectedColor: AppTheme.primary
                                      .withValues(alpha: 0.15),
                                  checkmarkColor: AppTheme.primary,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Consumer<SortProvider>(
                      builder: (context, provider, _) {
                        if (provider.enabledSorts.isEmpty) {
                          return const SizedBox(width: 8);
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.sort),
                            tooltip: T.get(context, 'sort'),
                            onSelected: (key) {
                              provider.setCurrentSort(key);
                              context
                                  .read<PhotoProvider>()
                                  .fetchPhotos(sortBy: key);
                            },
                            itemBuilder: (_) => provider.enabledSorts
                                .map(
                                  (s) => PopupMenuItem<String>(
                                    value: s.key,
                                    child: Row(
                                      children: [
                                        if (provider.currentSort == s.key)
                                          const Icon(Icons.check,
                                              size: 18,
                                              color: AppTheme.primary)
                                        else
                                          const SizedBox(width: 18),
                                        const SizedBox(width: 8),
                                        Text(s.labelAr),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Consumer<PhotoProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.photos.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(T.get(context, 'loading')),
                        ],
                      ),
                    ),
                  );
                }

                if (provider.photos.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 64,
                              color: Theme.of(context).disabledColor,
                            ),
                            const SizedBox(height: 16),
                            Text(T.get(context, 'no_photos_yet')),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _loadAll,
                              icon: const Icon(Icons.refresh),
                              label: Text(T.get(context, 'retry')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final photo = provider.photos[index];
                        return PhotoCard(
                          photo: photo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PhotoDetailsScreen(photo: photo),
                              ),
                            );
                          },
                        );
                      },
                      childCount: provider.photos.length,
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
      bottomNavigationBar: const BottomBannerAd(),
    );
  }

  void _showSearchDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(T.get(dialogContext, 'search')),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '${T.get(dialogContext, 'search')}...',
            prefixIcon: const Icon(Icons.search),
          ),
          onSubmitted: (value) {
            parentContext.read<PhotoProvider>().search(value);
            Navigator.pop(dialogContext);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(T.get(dialogContext, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              parentContext
                  .read<PhotoProvider>()
                  .search(_searchController.text);
              Navigator.pop(dialogContext);
            },
            child: Text(T.get(dialogContext, 'search')),
          ),
        ],
      ),
    );
  }
}
