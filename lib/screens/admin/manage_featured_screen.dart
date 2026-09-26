import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/photo_model.dart';
import '../../providers/featured_provider.dart';
import '../../providers/photo_provider.dart';
import '../../utils/app_theme.dart';

class ManageFeaturedScreen extends StatefulWidget {
  const ManageFeaturedScreen({super.key});

  @override
  State<ManageFeaturedScreen> createState() => _ManageFeaturedScreenState();
}

class _ManageFeaturedScreenState extends State<ManageFeaturedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeaturedProvider>().loadFeatured();
      context.read<PhotoProvider>().fetchPhotos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الصور المميزة'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'المميزة', icon: Icon(Icons.star)),
              Tab(text: 'إضافة', icon: Icon(Icons.add_circle_outline)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFeaturedTab(),
            _buildAddTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedTab() {
    return Consumer<FeaturedProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.featured.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.featured.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد صور مميزة',
                      style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('اذهب لتبويب "إضافة" لإضافة صور جديدة',
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadFeatured(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.featured.length,
            itemBuilder: (context, index) {
              final item = provider.featured[index];
              final photo = item.photo;
              if (photo == null) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: photo.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(photo.title,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'الترتيب: ${item.displayOrder} • ${photo.ownerName}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_upward,
                            color: AppTheme.primary, size: 20),
                        tooltip: 'رفع الترتيب',
                        onPressed: () {
                          provider.updateOrder(
                              item.id, item.displayOrder - 1);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward,
                            color: AppTheme.primary, size: 20),
                        tooltip: 'خفض الترتيب',
                        onPressed: () {
                          provider.updateOrder(
                              item.id, item.displayOrder + 1);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: AppTheme.error, size: 20),
                        tooltip: 'إزالة',
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('إزالة من المميزة'),
                              content: Text(
                                  'هل تريد إزالة "${photo.title}" من المميزة؟'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('إلغاء'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.error),
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  child: const Text('إزالة'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await provider.removeFeatured(item.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAddTab() {
    return Consumer2<PhotoProvider, FeaturedProvider>(
      builder: (context, photos, featured, _) {
        if (photos.isLoading && photos.photos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final featuredIds = featured.featured.map((f) => f.photoId).toSet();
        final available = photos.photos
            .where((p) => !featuredIds.contains(p.id))
            .toList();

        if (available.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'كل الصور مميزة بالفعل!\nأضف صوراً جديدة أولاً.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: available.length,
          itemBuilder: (context, index) {
            final photo = available[index];
            return _buildAddCard(photo, featured);
          },
        );
      },
    );
  }

  Widget _buildAddCard(PhotoModel photo, FeaturedProvider featured) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CachedNetworkImage(
              imageUrl: photo.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              photo.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  await featured.addFeatured(
                    photo.id,
                    order: featured.featured.length,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ أُضيفت للمميزة'),
                        backgroundColor: AppTheme.success,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ: $e'),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('إضافة',
                  style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                minimumSize: const Size(0, 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
