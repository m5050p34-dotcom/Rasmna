import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/profile_model.dart';
import '../providers/points_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';

enum PointsAction { add, deduct, set }

Future<void> showEditPointsDialog(
  BuildContext context,
  ProfileModel user,
) async {
  await showDialog(
    context: context,
    builder: (_) => _EditPointsDialog(user: user),
  );
}

class _EditPointsDialog extends StatefulWidget {
  final ProfileModel user;

  const _EditPointsDialog({required this.user});

  @override
  State<_EditPointsDialog> createState() => _EditPointsDialogState();
}

class _EditPointsDialogState extends State<_EditPointsDialog> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  PointsAction _action = PointsAction.add;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  int get _amount => int.tryParse(_amountController.text) ?? 0;

  int get _previewPoints {
    switch (_action) {
      case PointsAction.add:
        return widget.user.points + _amount;
      case PointsAction.deduct:
        return (widget.user.points - _amount).clamp(0, 999999999);
      case PointsAction.set:
        return _amount;
    }
  }

  Future<void> _submit() async {
    if (_amount <= 0 && _action != PointsAction.set) {
      _showError('الرجاء إدخال مبلغ صحيح');
      return;
    }
    if (_action == PointsAction.set && _amount < 0) {
      _showError('لا يمكن تعيين قيمة سالبة');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pointsProvider = context.read<PointsProvider>();
      final userProvider = context.read<UserProvider>();
      final reason = _reasonController.text.trim().isEmpty
          ? _defaultReason()
          : _reasonController.text.trim();

      int newBalance;
      switch (_action) {
        case PointsAction.add:
          newBalance = await pointsProvider.adminGrant(
            userId: widget.user.id,
            amount: _amount,
            reason: reason,
          );
          break;
        case PointsAction.deduct:
          newBalance = await pointsProvider.adminDeduct(
            userId: widget.user.id,
            amount: _amount,
            reason: reason,
          );
          break;
        case PointsAction.set:
          newBalance = await pointsProvider.setUserPoints(
            userId: widget.user.id,
            newValue: _amount,
            reason: reason,
          );
          break;
      }

      userProvider.updateUserPoints(widget.user.id, newBalance);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث النقاط. الرصيد الجديد: $newBalance'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(Helpers.errorMessage(e));
      }
    }
  }

  String _defaultReason() {
    switch (_action) {
      case PointsAction.add:
        return 'مكافأة إدارية';
      case PointsAction.deduct:
        return 'خصم إداري';
      case PointsAction.set:
        return 'تعيين إداري';
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.stars, color: AppTheme.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'تعديل نقاط ${widget.user.username}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── الرصيد الحالي ───
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet,
                      color: AppTheme.accent),
                  const SizedBox(width: 8),
                  Text(
                    'الرصيد الحالي: ${widget.user.points} نقطة',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── اختيار الإجراء ───
            const Text(
              'الإجراء:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    'إضافة',
                    Icons.add_circle,
                    AppTheme.success,
                    PointsAction.add,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    'خصم',
                    Icons.remove_circle,
                    AppTheme.error,
                    PointsAction.deduct,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    'تعيين',
                    Icons.edit,
                    AppTheme.primary,
                    PointsAction.set,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── المبلغ ───
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                prefixIcon: Icon(Icons.numbers),
                hintText: 'مثال: 500',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // ─── السبب ───
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'السبب (اختياري)',
                prefixIcon: Icon(Icons.notes),
                hintText: 'مثال: مكافأة تشجيعية',
              ),
            ),
            const SizedBox(height: 16),

            // ─── الرصيد بعد التعديل ───
            if (_amount > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up,
                        color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'الرصيد بعد التعديل: $_previewPoints نقطة',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _submit,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check),
          label: Text(_isLoading ? 'جارٍ...' : 'تأكيد'),
        ),
      ],
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    PointsAction action,
  ) {
    final isSelected = _action == action;
    return GestureDetector(
      onTap: () => setState(() => _action = action),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
