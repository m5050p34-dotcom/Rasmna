import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/icon_model.dart';
import '../../services/icon_store_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class ManageIconsScreen extends StatefulWidget {
  const ManageIconsScreen({super.key});

  @override
  State<ManageIconsScreen> createState() => _ManageIconsScreenState();
}

class _ManageIconsScreenState extends State<ManageIconsScreen> {
  final _service = IconStoreService();
  List<IconModel> _icons = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.getAllIcons(onlyActive: false);
      if (mounted) {
        setState(() {
          _icons = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = Helpers.errorMessage(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأيقونات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'تنظيف المنتهية',
            onPressed: _cleanupExpired,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('أيقونة جديدة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _icons.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _icons.length,
                        itemBuilder: (context, i) =>
                            _buildIconTile(_icons[i]),
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_emotions_outlined,
                size: 64,
                color: Theme.of(context).disabledColor),
            const SizedBox(height: 12),
            const Text('لا توجد أيقونات بعد'),
            const SizedBox(height: 8),
            const Text(
              'اضغط "أيقونة جديدة" لإضافة أول أيقونة',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconTile(IconModel icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // الصورة
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: icon.isActive
                      ? AppTheme.primary.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: icon.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // التفاصيل
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          icon.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (!icon.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'معطّلة',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (icon.description != null &&
                      icon.description!.isNotEmpty)
                    Text(
                      icon.description!,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.stars,
                          size: 14, color: AppTheme.accent),
                      const SizedBox(width: 4),
                      Text(
                        '${icon.price}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${icon.durationDays} يوم',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // القائمة
            PopupMenuButton<String>(
              onSelected: (v) => _handleMenu(v, icon),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('تعديل'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: ListTile(
                    leading: Icon(icon.isActive
                        ? Icons.visibility_off
                        : Icons.visibility),
                    title: Text(icon.isActive ? 'تعطيل' : 'تفعيل'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: AppTheme.error),
                    title: Text('حذف',
                        style: TextStyle(color: AppTheme.error)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenu(String action, IconModel icon) async {
    switch (action) {
      case 'edit':
        _openEditor(icon: icon);
        break;
      case 'toggle':
        await _toggleActive(icon);
        break;
      case 'delete':
        await _confirmDelete(icon);
        break;
    }
  }

  Future<void> _toggleActive(IconModel icon) async {
    try {
      await _service.updateIcon(iconId: icon.id, isActive: !icon.isActive);
      await _load();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _confirmDelete(IconModel icon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الأيقونة'),
        content: Text('هل أنت متأكد من حذف "${icon.name}"؟\n'
            'لن يتمكن المستخدمون من رؤيتها في المتجر.'),
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
    if (confirmed != true) return;

    try {
      await _service.deleteIcon(icon.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الأيقونة'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
      await _load();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _cleanupExpired() async {
    try {
      final count = await _service.cleanupExpiredIcons();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تنظيف $count أيقونة منتهية'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(Helpers.errorMessage(e)),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  void _openEditor({IconModel? icon}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _IconEditorScreen(icon: icon),
      ),
    );
    if (result == true) await _load();
  }
}

// ═══════════════════════════════════════════════════════════
// 🖊️ شاشة إضافة/تعديل أيقونة
// ═══════════════════════════════════════════════════════════
class _IconEditorScreen extends StatefulWidget {
  final IconModel? icon;
  const _IconEditorScreen({this.icon});

  @override
  State<_IconEditorScreen> createState() => _IconEditorScreenState();
}

class _IconEditorScreenState extends State<_IconEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '100');
  final _daysCtrl = TextEditingController(text: '30');
  final _orderCtrl = TextEditingController(text: '0');

  final _service = IconStoreService();
  File? _imageFile;
  String? _existingImageUrl;
  bool _saving = false;
  bool _isActive = true;

  bool get _isEditing => widget.icon != null;

  @override
  void initState() {
    super.initState();
    final ic = widget.icon;
    if (ic != null) {
      _nameCtrl.text = ic.name;
      _descCtrl.text = ic.description ?? '';
      _priceCtrl.text = ic.price.toString();
      _daysCtrl.text = ic.durationDays.toString();
      _orderCtrl.text = ic.displayOrder.toString();
      _existingImageUrl = ic.imageUrl;
      _isActive = ic.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _daysCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null && _existingImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب اختيار صورة للأيقونة'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await _service.updateIcon(
          iconId: widget.icon!.id,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          price: int.parse(_priceCtrl.text.trim()),
          durationDays: int.parse(_daysCtrl.text.trim()),
          displayOrder: int.parse(_orderCtrl.text.trim()),
          isActive: _isActive,
          newImageFile: _imageFile,
        );
      } else {
        await _service.createIcon(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          imageFile: _imageFile!,
          price: int.parse(_priceCtrl.text.trim()),
          durationDays: int.parse(_daysCtrl.text.trim()),
          displayOrder: int.parse(_orderCtrl.text.trim()),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'تم تحديث الأيقونة' : 'تم إنشاء الأيقونة'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Helpers.errorMessage(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل أيقونة' : 'أيقونة جديدة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // اختيار الصورة
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_imageFile!, fit: BoxFit.contain),
                        )
                      : _existingImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: CachedNetworkImage(
                                imageUrl: _existingImageUrl!,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: AppTheme.primary
                                      .withValues(alpha: 0.6),
                                ),
                                const SizedBox(height: 8),
                                const Text('اضغط لاختيار صورة'),
                                const SizedBox(height: 4),
                                const Text(
                                  'PNG شفاف مُفضّل (512×512)',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'أدخل اسماً';
                  if (v.trim().length < 2) return 'الاسم قصير جداً';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'السعر (نقاط)',
                        prefixIcon: Icon(Icons.stars),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 0) return 'رقم غير صحيح';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _daysCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المدة (يوم)',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) return 'رقم غير صحيح';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _orderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ترتيب الظهور',
                  prefixIcon: Icon(Icons.sort),
                  helperText: 'الأصغر يظهر أولاً',
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 0) return 'رقم غير صحيح';
                  return null;
                },
              ),

              if (_isEditing) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('الأيقونة فعّالة'),
                  subtitle: const Text('عند التعطيل، لن تظهر في المتجر'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving
                      ? 'جارٍ الحفظ...'
                      : (_isEditing ? 'حفظ التعديلات' : 'إنشاء الأيقونة')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
