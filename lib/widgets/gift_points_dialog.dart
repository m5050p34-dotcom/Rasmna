import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/profile_model.dart';
import '../utils/app_theme.dart';

// ═══════════════════════════════════════════════
// نتيجة نافذة الهدية
// ═══════════════════════════════════════════════
class GiftDialogResult {
  final int amount;
  final String? message;

  GiftDialogResult({required this.amount, this.message});
}

// ═══════════════════════════════════════════════
// نافذة إرسال هدية
// ═══════════════════════════════════════════════
Future<GiftDialogResult?> showGiftPointsDialog({
  required BuildContext context,
  required ProfileModel recipient,
  required int currentBalance,
}) {
  return showDialog<GiftDialogResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _GiftPointsDialog(
      recipient: recipient,
      currentBalance: currentBalance,
    ),
  );
}

class _GiftPointsDialog extends StatefulWidget {
  final ProfileModel recipient;
  final int currentBalance;

  const _GiftPointsDialog({
    required this.recipient,
    required this.currentBalance,
  });

  @override
  State<_GiftPointsDialog> createState() => _GiftPointsDialogState();
}

class _GiftPointsDialogState extends State<_GiftPointsDialog> {
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();

  static const int _minAmount = 20;
  static const double _commissionRate = 0.5;

  int get _amount => int.tryParse(_amountController.text) ?? 0;
  int get _commission => (_amount * _commissionRate).round();
  int get _recipientGets => _amount - _commission;
  bool get _isValid =>
      _amount >= _minAmount && _amount <= widget.currentBalance;

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _quickAmount(int value) {
    _amountController.text = value.toString();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.all(20),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ═══════════════════════════════════
            // رأس: أيقونة + اسم المستقبل
            // ═══════════════════════════════════
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      AppTheme.accent.withValues(alpha: 0.15),
                  backgroundImage: (widget.recipient.avatarUrl != null &&
                          widget.recipient.avatarUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(
                          widget.recipient.avatarUrl!)
                      : null,
                  child: (widget.recipient.avatarUrl == null ||
                          widget.recipient.avatarUrl!.isEmpty)
                      ? Text(
                          widget.recipient.initial,
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎁 إرسال هدية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'إلى: ${widget.recipient.username}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ═══════════════════════════════════
            // رصيدك الحالي
            // ═══════════════════════════════════
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars,
                      color: AppTheme.accent, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'رصيدك:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.currentBalance} نقطة',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ═══════════════════════════════════
            // حقل المبلغ
            // ═══════════════════════════════════
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: 'المبلغ (نقاط)',
                hintText: '0',
                prefixIcon: const Icon(Icons.card_giftcard),
                helperText: 'الحد الأدنى $_minAmount نقطة',
                errorText: _amount > 0 && _amount < _minAmount
                    ? 'الحد الأدنى $_minAmount نقطة'
                    : _amount > widget.currentBalance
                        ? 'رصيدك غير كافٍ'
                        : null,
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 8),

            // ─── أزرار سريعة ───
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _quickAmountBtn(50),
                const SizedBox(width: 6),
                _quickAmountBtn(100),
                const SizedBox(width: 6),
                _quickAmountBtn(200),
                const SizedBox(width: 6),
                _quickAmountBtn(500),
              ],
            ),

            const SizedBox(height: 16),

            // ═══════════════════════════════════
            // رسالة (اختياري)
            // ═══════════════════════════════════
            TextField(
              controller: _messageController,
              maxLength: 100,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'رسالة (اختياري)',
                hintText: 'مثال: شكراً لك!',
                prefixIcon: Icon(Icons.message_outlined),
              ),
            ),

            // ═══════════════════════════════════
            // ملخص التحويل
            // ═══════════════════════════════════
            if (_amount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    _summaryRow(
                      'سترسل',
                      '$_amount نقطة',
                      AppTheme.error,
                    ),
                    const SizedBox(height: 6),
                    _summaryRow(
                      'سيستلم ${widget.recipient.username}',
                      '$_recipientGets نقطة',
                      AppTheme.success,
                    ),
                    const SizedBox(height: 6),
                    _summaryRow(
                      'عمولة الإدارة (50%)',
                      '$_commission نقطة',
                      AppTheme.warning,
                    ),
                    const Divider(height: 20),
                    _summaryRow(
                      'رصيدك بعد الإرسال',
                      '${widget.currentBalance - _amount} نقطة',
                      AppTheme.primary,
                      bold: true,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: _isValid
              ? () {
                  Navigator.pop(
                    context,
                    GiftDialogResult(
                      amount: _amount,
                      message: _messageController.text.trim().isEmpty
                          ? null
                          : _messageController.text.trim(),
                    ),
                  );
                }
              : null,
          icon: const Icon(Icons.send, size: 18),
          label: const Text('إرسال'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
          ),
        ),
      ],
    );
  }

  Widget _quickAmountBtn(int value) {
    final isDisabled = value > widget.currentBalance;
    return OutlinedButton(
      onPressed: isDisabled ? null : () => _quickAmount(value),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: const Size(0, 32),
        side: BorderSide(
          color: isDisabled
              ? Colors.grey.withValues(alpha: 0.3)
              : AppTheme.accent.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        '+$value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDisabled ? Colors.grey : AppTheme.accent,
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
    Color color, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
