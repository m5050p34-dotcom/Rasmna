import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/banner_model.dart';
import '../../providers/banner_provider.dart';
import '../../utils/app_theme.dart';

class ManageBannersScreen extends StatefulWidget {
  const ManageBannersScreen({super.key});

  @override
  State<ManageBannersScreen> createState() => _ManageBannersScreenState();
}

class _ManageBannersScreenState extends State<ManageBannersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BannerProvider>().loadAll(adminMode: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة البانرات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'الإعدادات',
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<BannerProvider>().loadAll(adminMode: true),
          ),
        ],
      ),
      body: Consumer<BannerProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.banners.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.banners.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined,
                        size: 80, color: Colors.grey.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    const Text('لا توجد بانرات',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('أضف صورتك الأولى لتظهر في أعلى السوق',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).disabledColor)),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadAll(adminMode: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.banners.length,
              itemBuilder: (context, i) =>
                  _buildBannerCard(provider.banners[i], provider),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
        label: const Text('إضافة بانر',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildBannerCard(BannerModel banner, BannerProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: banner.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ),
              if (!banner.isActive)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.6),
                    child: const Center(
                      child: Text('معطل',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'الترتيب: ${banner.displayOrder}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // 🆕 شارة الرابط
              if (banner.hasValidExternalLink)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'رابط',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title ?? 'بدون عنوان',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (banner.hasValidExternalLink) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.open_in_new,
                          size: 12, color: AppTheme.success),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          banner.linkUrl!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => provider.updateBanner(banner.id, {
                          'is_active': !banner.isActive,
                        }),
                        icon: Icon(
                          banner.isActive
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 18,
                        ),
                        label: Text(banner.isActive ? 'مفعّل' : 'معطل',
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.arrow_upward,
                          color: AppTheme.primary),
                      tooltip: 'رفع',
                      onPressed: () => provider.updateBanner(banner.id, {
                        'display_order': banner.displayOrder - 1,
                      }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward,
                          color: AppTheme.primary),
                      tooltip: 'خفض',
                      onPressed: () => provider.updateBanner(banner.id, {
                        'display_order': banner.displayOrder + 1,
                      }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.accent),
                      tooltip: 'تعديل',
                      onPressed: () =>
                          _showEditDialog(context, banner, provider),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppTheme.error),
                      tooltip: 'حذف',
                      onPressed: () =>
                          _confirmDelete(context, banner, provider),
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

  Future<void> _confirmDelete(
    BuildContext context,
    BannerModel banner,
    BannerProvider provider,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف البانر'),
        content: const Text('هل أنت متأكد من حذف هذا البانر؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await provider.deleteBanner(banner.id, banner.imageUrl);
    }
  }

  // ═══════════════════════════════════════════════
  // إضافة بانر جديد
  // ═══════════════════════════════════════════════
  void _showAddDialog(BuildContext parentContext) {
    final titleCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: '0');
    final linkCtrl = TextEditingController();
    File? pickedFile;
    final provider = parentContext.read<BannerProvider>();

    showDialog(
      context: parentContext,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إضافة بانر جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── صورة البانر ───
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                        source: ImageSource.gallery, imageQuality: 85);
                    if (picked != null) {
                      setDialogState(() => pickedFile = File(picked.path));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(ctx).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: pickedFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child:
                                Image.file(pickedFile!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 40, color: AppTheme.primary),
                              SizedBox(height: 8),
                              Text('اختر صورة البانر',
                                  style: TextStyle(fontSize: 13)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // ─── العنوان ───
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'العنوان (اختياري)',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 8),

                // ─── 🆕 الرابط ───
                TextField(
                  controller: linkCtrl,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'الرابط (اختياري)',
                    hintText: 'https://example.com',
                    prefixIcon: Icon(Icons.link),
                    helperText: 'اتركه فارغاً إذا لم تريد رابطاً',
                    helperMaxLines: 2,
                  ),
                ),
                const SizedBox(height: 8),

                // ─── الترتيب ───
                TextField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الترتيب',
                    prefixIcon: Icon(Icons.sort),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton.icon(
              onPressed: pickedFile == null
                  ? null
                  : () async {
                      final navigator = Navigator.of(ctx);
                      final messenger =
                          ScaffoldMessenger.of(parentContext);

                      // 🆕 تنظيف الرابط
                      final rawLink = linkCtrl.text.trim();
                      String? linkUrl;
                      if (rawLink.isNotEmpty) {
                        if (rawLink.startsWith('http://') ||
                            rawLink.startsWith('https://')) {
                          linkUrl = rawLink;
                        } else {
                          linkUrl = 'https://$rawLink';
                        }
                      }

                      try {
                        await provider.addBanner(
                          file: pickedFile!,
                          title: titleCtrl.text.trim().isEmpty
                              ? null
                              : titleCtrl.text.trim(),
                          linkUrl: linkUrl,
                          displayOrder: int.tryParse(orderCtrl.text) ?? 0,
                        );
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('✅ تمت إضافة البانر'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('خطأ: $e'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // تعديل بانر
  // ═══════════════════════════════════════════════
  void _showEditDialog(
    BuildContext parentContext,
    BannerModel banner,
    BannerProvider provider,
  ) {
    final titleCtrl = TextEditingController(text: banner.title ?? '');
    final orderCtrl =
        TextEditingController(text: banner.displayOrder.toString());
    final linkCtrl = TextEditingController(text: banner.linkUrl ?? '');

    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل البانر'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: linkCtrl,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'الرابط',
                  hintText: 'https://example.com',
                  prefixIcon: Icon(Icons.link),
                  helperText: 'اتركه فارغاً لإزالة الرابط',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: orderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الترتيب',
                  prefixIcon: Icon(Icons.sort),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);

              // 🆕 تنظيف الرابط
              final rawLink = linkCtrl.text.trim();
              String? linkUrl;
              if (rawLink.isNotEmpty) {
                if (rawLink.startsWith('http://') ||
                    rawLink.startsWith('https://')) {
                  linkUrl = rawLink;
                } else {
                  linkUrl = 'https://$rawLink';
                }
              }

              await provider.updateBanner(banner.id, {
                'title': titleCtrl.text.trim().isEmpty
                    ? null
                    : titleCtrl.text.trim(),
                'link_url': linkUrl,
                'display_order': int.tryParse(orderCtrl.text) ?? 0,
              });
              navigator.pop();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // إعدادات البانر
  // ═══════════════════════════════════════════════
  void _showSettingsDialog() {
    final provider = context.read<BannerProvider>();
    final intervalCtrl = TextEditingController(
      text: provider.settings.bannerIntervalSeconds.toString(),
    );
    final heightCtrl = TextEditingController(
      text: provider.settings.bannerHeight.toString(),
    );
    bool showDots = provider.settings.showBannerDots;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('إعدادات البانر'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: intervalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'مدة التقليب (بالثواني)',
                  prefixIcon: Icon(Icons.timer),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: heightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الارتفاع (بكسل)',
                  prefixIcon: Icon(Icons.height),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('إظهار النقاط'),
                value: showDots,
                onChanged: (v) => setDialogState(() => showDots = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(ctx);
                await provider.updateSetting(
                    'banner_interval_seconds', intervalCtrl.text);
                await provider.updateSetting(
                    'banner_height', heightCtrl.text);
                await provider.updateSetting(
                    'show_banner_dots', showDots.toString());
                navigator.pop();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
