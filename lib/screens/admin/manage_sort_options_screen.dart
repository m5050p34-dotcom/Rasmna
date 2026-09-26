import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sort_option_model.dart';
import '../../providers/sort_provider.dart';
import '../../utils/app_theme.dart';

class ManageSortOptionsScreen extends StatefulWidget {
  const ManageSortOptionsScreen({super.key});

  @override
  State<ManageSortOptionsScreen> createState() =>
      _ManageSortOptionsScreenState();
}

class _ManageSortOptionsScreenState extends State<ManageSortOptionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SortProvider>().fetchSortOptions(adminMode: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة خيارات الفرز'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<SortProvider>()
                .fetchSortOptions(adminMode: true),
          ),
        ],
      ),
      body: Consumer<SortProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.allSorts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.allSorts.isEmpty) {
            return const Center(child: Text('لا توجد خيارات فرز'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.allSorts.length,
            itemBuilder: (context, i) =>
                _buildCard(provider.allSorts[i], provider),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCard(SortOptionModel sort, SortProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  sort.isDefault ? Icons.star : Icons.sort,
                  color: sort.isDefault ? AppTheme.accent : AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sort.labelAr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        sort.labelEn,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      Text(
                        'المفتاح: ${sort.key}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: sort.enabled,
                  onChanged: (v) => provider.updateSortOption(
                    sort.id,
                    {'enabled': v},
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                if (!sort.isDefault)
                  TextButton.icon(
                    onPressed: () => provider.setAsDefault(sort.id),
                    icon: const Icon(Icons.star_border, size: 18),
                    label: const Text('تعيين كافتراضي'),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'افتراضي',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.primary),
                  onPressed: () => _showEditDialog(sort),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.error),
                  onPressed: sort.isDefault
                      ? null
                      : () => _confirmDelete(sort, provider),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      SortOptionModel sort, SortProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف خيار الفرز'),
        content: Text('هل تريد حذف "${sort.labelAr}"؟'),
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
    if (ok == true) await provider.deleteSortOption(sort.id);
  }

  void _showAddDialog() {
    final keyCtrl = TextEditingController();
    final arCtrl = TextEditingController();
    final enCtrl = TextEditingController();
    final orderCtrl = TextEditingController(text: '99');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة خيار فرز'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyCtrl,
                decoration: const InputDecoration(
                  labelText: 'المفتاح (بالإنجليزية)',
                  hintText: 'مثل: popular',
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
              await context.read<SortProvider>().createSortOption(
                    key: keyCtrl.text.trim(),
                    labelAr: arCtrl.text.trim(),
                    labelEn: enCtrl.text.trim(),
                    displayOrder: int.tryParse(orderCtrl.text) ?? 99,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(SortOptionModel sort) {
    final arCtrl = TextEditingController(text: sort.labelAr);
    final enCtrl = TextEditingController(text: sort.labelEn);
    final orderCtrl =
        TextEditingController(text: sort.displayOrder.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل: ${sort.labelAr}'),
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
              await context.read<SortProvider>().updateSortOption(sort.id, {
                'label_ar': arCtrl.text.trim(),
                'label_en': enCtrl.text.trim(),
                'display_order':
                    int.tryParse(orderCtrl.text) ?? sort.displayOrder,
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
