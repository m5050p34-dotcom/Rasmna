import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_version_model.dart';
import '../../services/app_version_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class ManageUpdatesScreen extends StatefulWidget {
  const ManageUpdatesScreen({super.key});

  @override
  State<ManageUpdatesScreen> createState() => _ManageUpdatesScreenState();
}

class _ManageUpdatesScreenState extends State<ManageUpdatesScreen> {
  final _service = AppVersionService();
  List<AppVersionModel> _versions = [];
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
      final list = await _service.getAllVersions();
      if (mounted) {
        setState(() {
          _versions = list;
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
        title: const Text('إدارة التحديثات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('تحديث جديد'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _versions.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _versions.length,
                        itemBuilder: (context, i) =>
                            _buildVersionTile(_versions[i], i == 0),
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
            Icon(Icons.system_update,
                size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 12),
            const Text(
              'لا توجد تحديثات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'أضف تحديثاً جديداً لنشره للمستخدمين',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionTile(AppVersionModel v, bool isLatest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isLatest ? AppTheme.success : AppTheme.primary)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update,
                    color: isLatest ? AppTheme.success : AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            v.versionName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                          if (isLatest) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.success
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'الأحدث',
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
                      Text(
                        'Code: ${v.versionCode}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).disabledColor,
                          fontFamily: 'monospace',
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) => _handleAction(action, v),
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
                        leading: Icon(v.isActive
                            ? Icons.visibility_off
                            : Icons.visibility),
                        title: Text(v.isActive ? 'تعطيل' : 'تفعيل'),
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
            const SizedBox(height: 10),
            Row(
              children: [
                if (v.isMandatory)
                  _chip('إلزامي', AppTheme.error, Icons.warning_amber),
                if (v.isMandatory && !v.isActive) const SizedBox(width: 4),
                if (!v.isActive)
                  _chip('معطّل', Colors.grey, Icons.visibility_off),
              ],
            ),
            if (v.changelog.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  v.changelog,
                  style: const TextStyle(fontSize: 12, height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(String action, AppVersionModel v) async {
    switch (action) {
      case 'edit':
        _openEditor(version: v);
        break;
      case 'toggle':
        try {
          await _service.updateVersion(v.id, {'is_active': !v.isActive});
          await _load();
        } catch (e) {
          _showError(e);
        }
        break;
      case 'delete':
        await _confirmDelete(v);
        break;
    }
  }

  Future<void> _confirmDelete(AppVersionModel v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التحديث'),
        content: Text('هل تريد حذف الإصدار ${v.versionName}؟'),
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
      await _service.deleteVersion(v.id);
      await _load();
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

  Future<void> _openEditor({AppVersionModel? version}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _VersionEditorScreen(version: version),
      ),
    );
    if (result == true) await _load();
  }
}

// ═══════════════════════════════════════════════════════════
// شاشة إضافة/تعديل إصدار
// ═══════════════════════════════════════════════════════════
class _VersionEditorScreen extends StatefulWidget {
  final AppVersionModel? version;

  const _VersionEditorScreen({this.version});

  @override
  State<_VersionEditorScreen> createState() => _VersionEditorScreenState();
}

class _VersionEditorScreenState extends State<_VersionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _changelogCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _service = AppVersionService();

  bool _isMandatory = false;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEditing => widget.version != null;

  @override
  void initState() {
    super.initState();
    final v = widget.version;
    if (v != null) {
      _nameCtrl.text = v.versionName;
      _codeCtrl.text = v.versionCode.toString();
      _changelogCtrl.text = v.changelog;
      _urlCtrl.text = v.downloadUrl;
      _isMandatory = v.isMandatory;
      _isActive = v.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _changelogCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final version = AppVersionModel(
        id: widget.version?.id ?? '',
        versionName: _nameCtrl.text.trim(),
        versionCode: int.parse(_codeCtrl.text.trim()),
        changelog: _changelogCtrl.text.trim(),
        downloadUrl: _urlCtrl.text.trim(),
        isMandatory: _isMandatory,
        isActive: _isActive,
        createdAt: widget.version?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await _service.updateVersion(widget.version!.id, version.toJson());
      } else {
        await _service.createVersion(version);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'تم تحديث السجل' : 'تم إنشاء التحديث'),
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
        title: Text(_isEditing ? 'تعديل تحديث' : 'تحديث جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم الإصدار',
                        prefixIcon: Icon(Icons.tag),
                        hintText: '1.0.1',
                      ),
                      textDirection: TextDirection.ltr,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'مطلوب';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'رقم الإصدار',
                        prefixIcon: Icon(Icons.confirmation_number),
                        hintText: '2',
                      ),
                      textDirection: TextDirection.ltr,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1) return 'رقم صحيح';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _changelogCtrl,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'ميزات التحديث',
                  prefixIcon: Icon(Icons.list_alt),
                  hintText: 'اكتب كل ميزة في سطر جديد',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'أدخل الميزات';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _urlCtrl,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'رابط التحميل',
                  prefixIcon: Icon(Icons.link),
                  hintText: 'https://...',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'مطلوب';
                  if (!v.trim().startsWith('http')) return 'يجب أن يبدأ بـ http';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                title: const Text('تحديث إلزامي'),
                subtitle: const Text(
                    'لن يستطيع المستخدم استخدام التطبيق قبل التحديث'),
                value: _isMandatory,
                onChanged: (v) => setState(() => _isMandatory = v),
              ),
              SwitchListTile(
                title: const Text('نشط'),
                subtitle: const Text('عند التعطيل لن يظهر للمستخدمين'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
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
                      : (_isEditing ? 'حفظ' : 'إنشاء')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
