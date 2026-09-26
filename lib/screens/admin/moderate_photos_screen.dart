import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/photo_model.dart';
import '../../providers/categories_provider.dart';
import '../../providers/photo_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class ModeratePhotosScreen extends StatefulWidget {
  const ModeratePhotosScreen({super.key});

  @override
  State<ModeratePhotosScreen> createState() => _ModeratePhotosScreenState();
}

class _ModeratePhotosScreenState extends State<ModeratePhotosScreen> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CategoriesProvider>().load();
      if (mounted) {
        context.read<PhotoProvider>().fetchAdminPhotos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشراف على الصور'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PhotoProvider>().fetchAdminPhotos(
                    category: _selectedCategory,
                  );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── الفلاتر (تصنيفات ديناميكية) ───
          Consumer<CategoriesProvider>(
            builder: (context, cats, _) {
              final categories = cats.categoriesAsMap;
              return SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _selectedCategory == cat['key'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: FilterChip(
                        label: Text(cat['ar']!),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _selectedCategory = cat['key']!);
                          context.read<PhotoProvider>().fetchAdminPhotos(
                                category: cat['key'],
                              );
                        },
                        selectedColor:
                            AppTheme.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.primary,
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // ─── العدد ───
          Consumer<PhotoProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.photo_library,
                        size: 16,
                        color: Theme.of(context).disabledColor),
                    const SizedBox(width: 6),
                    Text(
                      '${provider.adminPhotos.length} صورة',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ─── الشبكة ───
          Expanded(
            child: Consumer<PhotoProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.adminPhotos.isEmpty) {
                  return const Center(child: Text('لا توجد صور'));
                }
                return RefreshIndicator(
                  onRefresh: () => provider.fetchAdminPhotos(
                        category: _selectedCategory,
                      ),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: provider.adminPhotos.length,
                    itemBuilder: (context, index) {
                      final photo = provider.adminPhotos[index];
                      return _buildPhotoCard(photo, provider);
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

  Widget _buildPhotoCard(PhotoModel photo, PhotoProvider provider) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: photo.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) => Container(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: photo.isFree
                          ? AppTheme.success
                          : AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      Helpers.formatPrice(photo.price),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.person, size: 12),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        photo.ownerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      tooltip: 'تعديل',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _showEditDialog(photo, provider),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: AppTheme.error,
                      ),
                      tooltip: 'حذف',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _confirmDelete(photo, provider),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(PhotoModel photo, PhotoProvider provider) async {
    final titleController = TextEditingController(text: photo.title);
    final priceController =
        TextEditingController(text: photo.price.toString());
    String category = photo.category;

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
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
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
                // ✅ التصنيفات الديناميكية
                Consumer<CategoriesProvider>(
                  builder: (context, cats, _) {
                    final categories = cats.categoriesAsMap
                        .where((c) => c['key'] != 'all')
                        .toList();

                    // ⚠️ إذا كان التصنيف الحالي غير موجود في القائمة
                    if (!categories.any((c) => c['key'] == category)) {
                      categories.add({
                        'key': category,
                        'ar': category,
                        'en': category,
                      });
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'التصنيف',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c['key'],
                              child: Text(c['ar']!),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => category = v!),
                    );
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
                  await provider.updatePhoto(
                    photoId: photo.id,
                    title: titleController.text.trim(),
                    category: category,
                    price: double.tryParse(priceController.text) ?? 0,
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم تحديث الصورة'),
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
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(PhotoModel photo, PhotoProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الصورة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: photo.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'هل أنت متأكد من حذف "${photo.title}" نهائياً؟',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await provider.deletePhoto(
        photoId: photo.id,
        imageUrl: photo.imageUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الصورة'),
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
}
