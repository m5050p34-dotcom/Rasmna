import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../providers/categories_provider.dart';
import '../../providers/photo_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../utils/translations.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _SelectedImage {
  final File file;
  final String format;
  final String id;

  _SelectedImage({
    required this.file,
    required this.format,
    required this.id,
  });
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController(text: '0');

  final List<_SelectedImage> _images = [];
  String? _category;
  bool _isFree = false;

  static const int _maxImages = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await context.read<CategoriesProvider>().load();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════
  // اختيار صور متعددة
  // ═══════════════════════════════════════════════
  Future<void> _pickImages({required bool fromCamera}) async {
    if (_images.length >= _maxImages) {
      _snack('الحد الأقصى $_maxImages صور', AppTheme.warning);
      return;
    }

    try {
      final picker = ImagePicker();
      final remaining = _maxImages - _images.length;

      if (fromCamera) {
        final picked = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 90,
        );
        if (picked == null) return;
        debugPrint('Camera picked: \${picked.path}');
        _addImage(picked);
      } else {
        debugPrint('Opening multi-image picker...');
        final picked = await picker.pickMultiImage(imageQuality: 90);
        debugPrint('Picker returned \${picked.length} images');

        if (picked.isEmpty) return;

        final toAdd = picked.take(remaining).toList();
        for (final img in toAdd) {
          _addImage(img);
        }

        if (picked.length > remaining) {
          _snack(
            'تم إضافة $remaining فقط (الحد الأقصى $_maxImages)',
            AppTheme.warning,
          );
        }
      }
    } catch (e) {
      debugPrint('Picker error: \$e');
      _snack('خطأ في الاختيار: \$e', AppTheme.error);
    }
  }

  void _addImage(XFile picked) {
    final ext = p.extension(picked.path).replaceAll('.', '').toLowerCase();
    final uniqueId =
        '\${DateTime.now().microsecondsSinceEpoch}_\${_images.length}_\${picked.path.hashCode}';

    setState(() {
      _images.add(_SelectedImage(
        file: File(picked.path),
        format: ext.isEmpty ? 'jpg' : ext,
        id: uniqueId,
      ));
    });
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
  }

  bool _isTransparent(String format) =>
      format == 'png' || format == 'webp';

  // ═══════════════════════════════════════════════
  // رفع الصور
  // ═══════════════════════════════════════════════
  Future<void> _upload() async {
    if (_images.isEmpty) {
      _snack('الرجاء اختيار صورة واحدة على الأقل', AppTheme.warning);
      return;
    }

    if (_category == null || _category!.isEmpty) {
      _snack('الرجاء اختيار تصنيف للصورة قبل الرفع', AppTheme.warning);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final photos = context.read<PhotoProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await photos.uploadPhotoGroup(
        files: _images.map((i) => i.file).toList(),
        formats: _images.map((i) => i.format).toList(),
        title: _titleController.text.trim().isEmpty
            ? 'بدون عنوان'
            : _titleController.text.trim(),
        category: _category!,
        price: _isFree ? 0 : double.tryParse(_priceController.text) ?? 0,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _images.length > 1
                ? 'تم نشر \${_images.length} صور بنجاح'
                : 'تم رفع الصور بنجاح',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(Helpers.errorMessage(e)),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(T.get(context, 'upload_new_photo')),
        actions: [
          if (_images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\${_images.length} / \$_maxImages',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagesSection(),
              const SizedBox(height: 20),
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 16),
              _buildFreeSwitch(),
              if (!_isFree) ...[
                const SizedBox(height: 12),
                _buildPriceField(),
              ],
              const SizedBox(height: 32),
              _buildUploadButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // قسم الصور
  // ═══════════════════════════════════════════════
  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library_outlined,
                size: 20, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Text(
              'الصور',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_images.isNotEmpty)
              Text(
                'اسحب للترتيب',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).disabledColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_images.isEmpty)
          _buildEmptyPicker()
        else ...[
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _images.length,
            // ignore: deprecated_member_use
            onReorder: _reorder,
            itemBuilder: (context, index) => _buildImageTile(index),
          ),
          const SizedBox(height: 10),
          if (_images.length < _maxImages) _buildAddMoreButton(),
        ],
      ],
    );
  }

  Widget _buildEmptyPicker() {
    return GestureDetector(
      onTap: _showPickOptions,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 64,
              color: AppTheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            const Text(
              'اضغط لاختيار صور',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'يمكنك اختيار حتى $_maxImages صور',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMoreButton() {
    return OutlinedButton.icon(
      onPressed: _showPickOptions,
      icon: const Icon(Icons.add_photo_alternate_outlined),
      label: Text('إضافة صور أخرى (\${_images.length}/\$_maxImages)'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primary,
        side: const BorderSide(color: AppTheme.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildImageTile(int index) {
    final img = _images[index];
    final isCover = index == 0;
    final isTrans = _isTransparent(img.format);

    return Container(
      key: ValueKey(img.id),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCover
              ? AppTheme.primary
              : AppTheme.primary.withValues(alpha: 0.15),
          width: isCover ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.drag_indicator,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 70,
                  height: 70,
                  color: isTrans ? Colors.grey.shade200 : Colors.transparent,
                  child: Image.file(img.file, fit: BoxFit.cover),
                ),
              ),
              if (isCover)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'الغلاف',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#\${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (isTrans) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PNG',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppTheme.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  p.basename(img.file.path),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).disabledColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeImage(index),
            icon: const Icon(Icons.delete_outline,
                color: AppTheme.error, size: 20),
            tooltip: 'حذف',
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: T.get(context, 'photo_title'),
        prefixIcon: const Icon(Icons.title),
        helperText: 'اختياري',
        helperMaxLines: 2,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Consumer<CategoriesProvider>(
      builder: (context, cats, _) {
        if (cats.isLoading && cats.enabled.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('جارٍ تحميل التصنيفات...'),
              ],
            ),
          );
        }

        final categories = cats.categoriesAsMap
            .where((c) => c['key'] != 'all')
            .toList();

        if (categories.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.warning.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber,
                    color: AppTheme.warning, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'لا توجد تصنيفات متاحة. تواصل مع الأدمن.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }

        final isValidSelection = _category != null &&
            categories.any((c) => c['key'] == _category);
        if (!isValidSelection && _category != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _category = null);
          });
        }

        return DropdownButtonFormField<String>(
          initialValue: isValidSelection ? _category : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: T.get(context, 'category'),
            prefixIcon: const Icon(Icons.category_outlined),
            hintText: 'غير مصنف — اختر تصنيفاً',
            hintStyle: TextStyle(
              color: AppTheme.warning.withValues(alpha: 0.9),
              fontWeight: FontWeight.bold,
            ),
            helperText: 'إجباري',
            helperStyle: const TextStyle(
              color: AppTheme.error,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            enabledBorder: _category == null
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.warning.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  )
                : null,
          ),
          items: categories
              .map(
                (c) => DropdownMenuItem(
                  value: c['key'],
                  child: Text(c['ar']!),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _category = v),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'يجب اختيار تصنيف';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildFreeSwitch() {
    return SwitchListTile(
      title: Text(T.get(context, 'make_free')),
      subtitle: Text(T.get(context, 'free_hint')),
      value: _isFree,
      onChanged: (v) => setState(() => _isFree = v),
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: T.get(context, 'price_points'),
        prefixIcon: const Icon(Icons.attach_money),
        helperText: _images.length > 1
            ? 'السعر لكل الصور (\${_images.length} صور)'
            : null,
      ),
      validator: (v) {
        if (_isFree) return null;
        if (v == null || v.isEmpty) {
          return T.get(context, 'enter_price');
        }
        final price = double.tryParse(v);
        if (price == null) return 'أدخل رقماً صحيحاً';
        if (price < 0) return 'السعر لا يمكن أن يكون سالباً';
        return null;
      },
    );
  }

  Widget _buildUploadButton() {
    return Consumer<PhotoProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: provider.isLoading ? null : _upload,
            icon: provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_upload),
            label: Text(
              provider.isLoading
                  ? T.get(context, 'uploading')
                  : _images.length > 1
                      ? 'نشر \${_images.length} صور'
                      : T.get(context, 'publish_photo'),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  void _showPickOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(T.get(context, 'from_gallery')),
              subtitle: const Text('يمكنك اختيار عدة صور'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImages(fromCamera: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(T.get(context, 'from_camera')),
              subtitle: const Text('صورة واحدة'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImages(fromCamera: true);
              },
            ),
          ],
        ),
      ),
    );
  }
}
