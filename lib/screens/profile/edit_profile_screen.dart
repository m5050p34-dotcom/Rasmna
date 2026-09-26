import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

const int kUsernameChangeCost = 50;
const int kAvatarChangeCost = 50;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _service = ProfileService();

  File? _newAvatarFile;
  bool _isSaving = false;
  String _originalUsername = '';
  bool _hadAvatarBefore = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    if (profile != null) {
      _originalUsername = profile.username;
      _usernameController.text = profile.username;
      _bioController.text = profile.bio ?? '';
      _hadAvatarBefore = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  bool get _usernameChanged {
    final newName = _usernameController.text.trim();
    return newName.isNotEmpty &&
        newName.toLowerCase() != _originalUsername.toLowerCase();
  }

  bool get _avatarChanged => _newAvatarFile != null;

  int get _avatarCost => _hadAvatarBefore ? kAvatarChangeCost : 0;

  int get _currentPoints => context.read<AuthProvider>().profile?.points ?? 0;

  int get _totalCost =>
      (_usernameChanged ? kUsernameChangeCost : 0) + _avatarCost;

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null) return;

      // إذا كانت هناك صورة سابقة → تأكيد
      if (_hadAvatarBefore) {
        final confirmed = await _showAvatarChangeConfirmation();
        if (confirmed != true) return;
      }

      setState(() => _newAvatarFile = File(picked.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<bool?> _showAvatarChangeConfirmation() {
    final canAfford = _currentPoints >= kAvatarChangeCost;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (canAfford ? AppTheme.warning : AppTheme.error)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                canAfford ? Icons.camera_alt : Icons.warning_amber_rounded,
                color: canAfford ? AppTheme.warning : AppTheme.error,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('تغيير الصورة الرمزية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (canAfford ? AppTheme.warning : AppTheme.error)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (canAfford ? AppTheme.warning : AppTheme.error)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    canAfford
                        ? 'سيتم خصم $kAvatarChangeCost نقطة لتغيير الصورة'
                        : 'رصيدك غير كافٍ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: canAfford ? AppTheme.warning : AppTheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars,
                          color: AppTheme.accent, size: 16),
                      const SizedBox(width: 4),
                      Text('رصيدك: $_currentPoints نقطة',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  if (canAfford) ...[
                    const SizedBox(height: 4),
                    Text(
                      'الرصيد بعد الخصم: ${_currentPoints - kAvatarChangeCost} نقطة',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.success),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: canAfford ? () => Navigator.pop(ctx, true) : null,
            icon: const Icon(Icons.check, size: 18),
            label: Text(canAfford
                ? 'تأكيد ($kAvatarChangeCost نقطة)'
                : 'رصيد غير كافٍ'),
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('من المعرض'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('من الكاميرا'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAvatar(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final userId = auth.userId;
    if (userId == null) return;

    if (_totalCost > _currentPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('رصيدك غير كافٍ. تحتاج $_totalCost نقطة'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_usernameChanged) {
      final confirmed = await _showUsernameChangeConfirmation();
      if (confirmed != true) return;
    }

    setState(() => _isSaving = true);
    try {
      int totalSpent = 0;

      // 1) الصورة (تخصم 50 إن كانت موجودة سابقاً)
      if (_avatarChanged) {
        final avatarResult = await _service.changeAvatar(
          userId: userId,
          file: _newAvatarFile!,
        );
        totalSpent += avatarResult.pointsSpent;
      }

      // 2) الاسم (يخصم 50)
      if (_usernameChanged) {
        final nameResult = await _service.changeUsername(
          userId: userId,
          newUsername: _usernameController.text.trim(),
        );
        totalSpent += nameResult.pointsSpent;
      }

      // 3) النبذة
      await _service.updateProfile(userId, {
        'bio': _bioController.text.trim(),
      });

      await auth.refreshProfile();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(totalSpent > 0
                ? '✅ تم التحديث • خُصمت $totalSpent نقطة'
                : '✅ تم تحديث الملف الشخصي'),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 3),
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
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool?> _showUsernameChangeConfirmation() {
    final newName = _usernameController.text.trim();
    final canAfford = _currentPoints >= kUsernameChangeCost;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (canAfford ? AppTheme.warning : AppTheme.error)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                canAfford ? Icons.edit : Icons.warning_amber_rounded,
                color: canAfford ? AppTheme.warning : AppTheme.error,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('تغيير الاسم',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNameBox(_originalUsername, true),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: Icon(Icons.arrow_downward,
                    color: AppTheme.primary, size: 20),
              ),
            ),
            _buildNameBox(newName, false),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (canAfford ? AppTheme.warning : AppTheme.error)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (canAfford ? AppTheme.warning : AppTheme.error)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        canAfford ? Icons.info_outline : Icons.error_outline,
                        color: canAfford ? AppTheme.warning : AppTheme.error,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          canAfford
                              ? 'سيتم خصم $kUsernameChangeCost نقطة'
                              : 'رصيدك غير كافٍ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                canAfford ? AppTheme.warning : AppTheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.stars,
                          color: AppTheme.accent, size: 16),
                      const SizedBox(width: 4),
                      Text('رصيدك: $_currentPoints نقطة',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: canAfford ? () => Navigator.pop(ctx, true) : null,
            icon: const Icon(Icons.check, size: 18),
            label: Text(canAfford
                ? 'تأكيد ($kUsernameChangeCost نقطة)'
                : 'رصيد غير كافٍ'),
          ),
        ],
      ),
    );
  }

  Widget _buildNameBox(String name, bool isOld) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOld
            ? Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5)
            : AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: isOld
            ? null
            : Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isOld ? Icons.person_outline : Icons.person,
            size: 18,
            color: isOld ? Colors.grey : AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                decoration: isOld ? TextDecoration.lineThrough : null,
                fontWeight: isOld ? null : FontWeight.bold,
                color: isOld ? Colors.grey : AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final currentPoints = profile?.points ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('تعديل الملف الشخصي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── الصورة الرمزية ───
              Center(
                child: GestureDetector(
                  onTap: _showAvatarOptions,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.2),
                        backgroundImage: _newAvatarFile != null
                            ? FileImage(_newAvatarFile!)
                            : (profile?.avatarUrl != null &&
                                    profile!.avatarUrl!.isNotEmpty)
                                ? CachedNetworkImageProvider(profile.avatarUrl!)
                                : null,
                        child: (_newAvatarFile == null &&
                                (profile?.avatarUrl == null ||
                                    profile!.avatarUrl!.isEmpty))
                            ? Text(
                                profile?.initial ?? '?',
                                style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _hadAvatarBefore
                      ? 'تغيير الصورة يخصم $kAvatarChangeCost نقطة'
                      : 'الصورة الأولى مجانية',
                  style: TextStyle(
                    fontSize: 12,
                    color: _hadAvatarBefore
                        ? AppTheme.warning
                        : AppTheme.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ─── الرصيد ───
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppTheme.accent.withValues(alpha: 0.15),
                    AppTheme.warning.withValues(alpha: 0.15),
                  ]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars,
                        color: AppTheme.accent, size: 24),
                    const SizedBox(width: 10),
                    const Text('رصيدك:',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 6),
                    Text(
                      '$currentPoints نقطة',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                          fontSize: 16),
                    ),
                    const Spacer(),
                    if (_totalCost > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-$_totalCost',
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── الاسم ───
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'اسم المستخدم',
                  prefixIcon: const Icon(Icons.person),
                  suffixIcon: _usernameChanged
                      ? const Icon(Icons.edit, color: AppTheme.warning)
                      : null,
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'أدخل اسماً';
                  if (v.trim().length < 3) return 'الاسم قصير جداً';
                  if (v.trim().length > 50) return 'الاسم طويل جداً';
                  return null;
                },
              ),

              if (_usernameChanged) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppTheme.warning, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تغيير الاسم يخصم $kUsernameChangeCost نقطة',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ─── النبذة ───
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'نبذة عنك (اختياري)',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 8),

              // ─── البريد ───
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        profile?.email ?? '',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const Icon(Icons.lock, size: 16),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ─── زر الحفظ ───
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(_totalCost > 0 ? Icons.paid : Icons.save),
                  label: Text(
                    _isSaving
                        ? 'جارٍ الحفظ...'
                        : _totalCost > 0
                            ? 'حفظ (مع خصم $_totalCost نقطة)'
                            : 'حفظ التغييرات',
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
