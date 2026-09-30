import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/report_model.dart';
import '../../services/reports_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({super.key});

  @override
  State<ViewReportsScreen> createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  final _service = ReportsService();
  List<ReportModel> _reports = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final reports = await _service.getAllReports(
        filterStatus: _filter,
      );
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warning;
      case 'resolved':
        return AppTheme.success;
      case 'dismissed':
        return Colors.grey;
      default:
        return AppTheme.primary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'resolved':
        return 'تم الحل';
      case 'dismissed':
        return 'تم التجاهل';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البلاغات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // الفلاتر
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _filterChip('الكل', 'all'),
                _filterChip('قيد الانتظار', 'pending'),
                _filterChip('تم الحل', 'resolved'),
                _filterChip('تم التجاهل', 'dismissed'),
              ],
            ),
          ),

          // القائمة
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reports.isEmpty
                    ? const Center(child: Text('لا توجد بلاغات'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _reports.length,
                          itemBuilder: (context, i) =>
                              _buildReportCard(_reports[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _filter = value);
          _load();
        },
        selectedColor: AppTheme.primary.withValues(alpha: 0.2),
        checkmarkColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    final color = _statusColor(report.status);
    final photo = report.photo;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── الحالة ───
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(report.status),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  Helpers.timeAgo(report.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ─── الصورة ───
            if (photo != null)
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: photo.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photo.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'بواسطة: ${photo.ownerName}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),

            // ─── السبب ───
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag,
                          color: AppTheme.error, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'السبب: ${report.reason}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                  if (report.details != null && report.details!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        report.details!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (report.reporter != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'المُبلغ: ${report.reporter!.username}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ─── الأزرار ───
            if (report.isPending) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(
                        report,
                        'dismissed',
                        'تم التجاهل',
                      ),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('تجاهل'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(
                        report,
                        'resolved',
                        'تم الحل',
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('حل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ─── ملاحظات الأدمن ───
            if (report.adminNotes != null &&
                report.adminNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ملاحظة: ${report.adminNotes}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(
    ReportModel report,
    String status,
    String statusLabel,
  ) async {
    final notesController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد: $statusLabel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل تريد $statusLabel هذا البلاغ؟'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLength: 200,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                hintText: 'سبب القرار...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.updateReportStatus(
        reportId: report.id,
        status: status,
        adminNotes: notesController.text.trim(),
      );
      await _load();
      messenger.showSnackBar(
        SnackBar(
          content: Text('تم $statusLabel بنجاح'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(Helpers.errorMessage(e)),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}
