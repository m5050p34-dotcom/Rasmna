import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
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

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController(text: '0');

  File? _imageFile;
  String? _format;
  String? _category;
  bool _isFree = false;
  bool _isTransparent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cats = context.read<CategoriesProvider>();
      await cats.load();
      if (mounted && cats.enabled.isNotEmpty) {
        setState(() => _category = cats.enabled.first.key);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 100, // بدون ضغط من picker (نضغط بأنفسنا)
      );
      if (picked == null) return;

      final file = File(picked.path);
      final ext = p.extension(picked.path).replaceAll('.', '').toLowerCase();
      final isPng = ext == 'png';
      final isWebp = ext == 'webp';

      setState(() {
        _imageFile = file;
        _format = ext.isEmpty ? 'jpg' : ext;
        _isTransparent = isPng || isWebp;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<void> _upload() async {
    // ─── التحقق من الصورة ───
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(T.get(context, 'must_pick_image')),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    // ─── التحقق من التصنيف (إجباري) ───
    if (_category == null || _category!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(T.get(context, 'must_pick_category')),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final photos = context.read<PhotoProvider>();

    try {
      await photos.uploadPhoto(
        file: _imageFile!,
        // العنوان اختياري - نستخدم "بدون عنوان" إذا فاضي
        title: _titleController.text.trim().isEmpty
            ? 'بدون عنوان'
            : _titleController.text.trim(),
        category: _category!,
        price: _isFree ? 0 : double.tryParse(_priceController.text) ?? 0,
        format: _format ?? 'jpg',
        userId: auth.userId!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(T.get(context, 'upload_success')),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Helpers.errorMessage(e)),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(T.get(context, 'upload_new_photo'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ═══════════════════════════════════
              // اختيار الصورة
              // ═══════════════════════════════════
              GestureDetector(
                onTap: _showPickOptions,
                child: Container(
                  height: 240,
                  decoration: BoxDecoration(
                    // نمط رقعة الشطرنج لعرض الشفافية
                    color: _isTransparent
                        ? null
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    gradient: _isTransparent
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFE0E0E0),
                              Color(0xFFF5F5F5),
                              Color(0xFFE0E0E0),
                              Color(0xFFF5F5F5),
                            ],
                            stops: [0.0, 0.25, 0.5, 0.75],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: _imageFile != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                _imageFile!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                              ),
                            ),
                            // ─── شارة "شفافة" ───
                            if (_isTransparent)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome,
                                          color: Colors.white, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'PNG شفاف',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 64,
                              color: AppTheme.primary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 12),
                            const Text('اضغط لاختيار صورة'),
                            const SizedBox(height: 4),
                            Text(
                              'JPG, PNG, WEBP, GIF • يدعم الشفافية',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).disabledColor,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // ═══════════════════════════════════
              // عنوان الصورة (اختياري)
              // ═══════════════════════════════════
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: T.get(context, 'photo_title'),
                  prefixIcon: const Icon(Icons.title),
                  helperText: 'اختياري - يُسمّى "بدون عنوان" إذا تركت فارغاً',
                  helperMaxLines: 2,
                ),
                // لا يوجد validator (اختياري)
              ),

              const SizedBox(height: 16),

              // ═══════════════════════════════════
              // التصنيف (إجباري)
              // ═══════════════════════════════════
              Consumer<CategoriesProvider>(
                builder: (context, cats, _) {
                  if (cats.isLoading && cats.enabled.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
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

                  if (_category == null ||
                      !categories.any((c) => c['key'] == _category)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _category = categories.first['key']);
                      }
                    });
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: InputDecoration(
                      labelText: T.get(context, 'category'),
                      prefixIcon: const Icon(Icons.category_outlined),
                      helperText: 'إجباري',
                      helperStyle: const TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.bold,
                      ),
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
                        return T.get(context, 'must_pick_category');
                      }
                      return null;
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // ═══════════════════════════════════
              // مجانية؟
              // ═══════════════════════════════════
              SwitchListTile(
                title: Text(T.get(context, 'make_free')),
                subtitle: Text(T.get(context, 'free_hint')),
                value: _isFree,
                onChanged: (v) => setState(() => _isFree = v),
              ),

              // ═══════════════════════════════════
              // السعر
              // ═══════════════════════════════════
              if (!_isFree)
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: T.get(context, 'price_points'),
                    prefixIcon: const Icon(Icons.attach_money),
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
                ),

              const SizedBox(height: 32),

              // ═══════════════════════════════════
              // زر الرفع
              // ═══════════════════════════════════
              Consumer<PhotoProvider>(
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
                            : T.get(context, 'publish_photo'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
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
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(T.get(context, 'from_camera')),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}
