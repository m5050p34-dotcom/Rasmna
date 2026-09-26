import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/photo_category_model.dart';
import '../../providers/categories_provider.dart';
import '../../utils/app_theme.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesProvider>().load(adminMode: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة التصنيفات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<CategoriesProvider>().load(adminMode: true),
          ),
        ],
      ),
      body: Consumer<CategoriesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.all.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.all.isEmpty) {
            return const Center(child: Text('لا توجد تصنيفات'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.all.length,
            itemBuilder: (context, i) =>
                _buildCard(provider.all[i], provider),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('تصنيف جديد',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCard(PhotoCategoryModel cat, CategoriesProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.category, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.labelAr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${cat.labelEn} • المفتاح: ${cat.key}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      Text(
                        'الترتيب: ${cat.displayOrder}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: cat.enabled,
                  onChanged: (v) => provider.update(cat.id, {'enabled': v}),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward,
                      color: AppTheme.primary, size: 20),
                  tooltip: 'رفع',
                  onPressed: () => provider.update(cat.id, {
                    'display_order': cat.displayOrder - 1,
                  }),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward,
                      color: AppTheme.primary, size: 20),
                  tooltip: 'خفض',
                  onPressed: () => provider.update(cat.id, {
                    'display_order': cat.displayOrder + 1,
                  }),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.accent),
                  tooltip: 'تعديل',
                  onPressed: () => _showEditDialog(cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.error),
                  tooltip: 'حذف',
                  onPressed: () => _confirmDelete(cat, provider),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      PhotoCategoryModel cat, CategoriesProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التصنيف'),
        content: Text('هل تريد حذف "${cat.labelAr}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) await provider.delete(cat.id);
  }

  void _showAddDialog() {
    final keyCtrl = TextEditingController();
    final arCtrl = TextEditingController();
    final enCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: '99');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة تصنيف جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyCtrl,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'المفتاح (إنجليزي)',
                  hintText: 'مثل: mountains',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: arCtrl,
                decoration: const InputDecoration(labelText: 'الاسم بالعربية'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: enCtrl,
                textDirection: TextDirection.ltr,
                decoration:
                    const InputDecoration(labelText: 'الاسم بالإنجليزية'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: orderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ترتيب العرض'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (keyCtrl.text.trim().isEmpty ||
                  arCtrl.text.trim().isEmpty ||
                  enCtrl.text.trim().isEmpty) {
                return;
              }
              final provider = context.read<CategoriesProvider>();
              final navigator = Navigator.of(ctx);
              await provider.create(
                key: keyCtrl.text.trim(),
                labelAr: arCtrl.text.trim(),
                labelEn: enCtrl.text.trim(),
                displayOrder: int.tryParse(orderCtrl.text) ?? 99,
              );
              navigator.pop();
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(PhotoCategoryModel cat) {
    final arCtrl = TextEditingController(text: cat.labelAr);
    final enCtrl = TextEditingController(text: cat.labelEn);
    final orderCtrl = TextEditingController(text: cat.displayOrder.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل: ${cat.labelAr}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: arCtrl,
              decoration: const InputDecoration(labelText: 'الاسم بالعربية'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: enCtrl,
              textDirection: TextDirection.ltr,
              decoration:
                  const InputDecoration(labelText: 'الاسم بالإنجليزية'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: orderCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ترتيب العرض'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<CategoriesProvider>();
              final navigator = Navigator.of(ctx);
              await provider.update(cat.id, {
                'label_ar': arCtrl.text.trim(),
                'label_en': enCtrl.text.trim(),
                'display_order':
                    int.tryParse(orderCtrl.text) ?? cat.displayOrder,
              });
              navigator.pop();
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
