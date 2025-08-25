import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // ← مهم لتنسيق التاريخ

import '../providers/app_state_provider.dart';
import '../models/transaction_model.dart';
import '../widgets/balance_card.dart';
import '../widgets/app/section_title.dart';
import '../services/report_service.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _selectedFolder;
  String? _selectedAccount;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final tx = state.transactions;
    final folders = state.folders.map((f) => f.name).toSet().toList()..sort();

    final accounts = _buildAccountsList(tx, folder: _selectedFolder);

    final service = ReportService();
    final data = service.buildReport(
      tx,
      ReportFilters(folder: _selectedFolder, account: _selectedAccount),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('الفلاتر'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFolder,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'المجلد',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('كل المجلدات'),
                    ),
                    ...folders.map(
                      (name) =>
                          DropdownMenuItem(value: name, child: Text(name)),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _selectedFolder = v;
                      _selectedAccount = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedAccount,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'الحساب',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('كل الحسابات'),
                    ),
                    ...accounts.map(
                      (name) =>
                          DropdownMenuItem(value: name, child: Text(name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedAccount = v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          BalanceCard(income: data.totalIncome, expense: data.totalExpense),

          const SizedBox(height: 16),
          const SectionTitle('المعاملات'),
          _buildTable(context, data.items),

          const SizedBox(height: 16),
          const SectionTitle('تصدير'),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.table_view),
                  label: const Text('CSV (Excel)'),
                  onPressed: data.items.isEmpty
                      ? null
                      : () async {
                          try {
                            final ok = await service.saveCsvWithPicker(data);
                            if (!mounted) return;
                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم حفظ CSV بنجاح'),
                                ),
                              );
                            } else {
                              // المستخدم ألغى → نحفظ في Downloads كخطة بديلة
                              final f = await service.saveCsvToDownloads(data);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تم الحفظ في: ${f.path}'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('فشل حفظ CSV: $e')),
                            );
                          }
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                  onPressed: data.items.isEmpty
                      ? null
                      : () async {
                          try {
                            final ok = await service.savePdfWithPicker(data);
                            if (!mounted) return;
                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم حفظ PDF بنجاح'),
                                ),
                              );
                            } else {
                              // المستخدم ألغى → نحفظ في Downloads كخطة بديلة
                              final f = await service.savePdfToDownloads(data);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تم الحفظ في: ${f.path}'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('فشل حفظ PDF: $e')),
                            );
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _buildAccountsList(
    List<TransactionModel> all, {
    String? folder,
  }) {
    final filtered = folder == null
        ? all
        : all.where((t) => t.folder == folder).toList();
    final accounts =
        filtered
            .map((t) => t.account)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return accounts;
  }

  Widget _buildTable(BuildContext context, List<TransactionModel> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Opacity(
            opacity: 0.7,
            child: Text(
              'لا توجد بيانات',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(1.6),
        },
        border: TableBorder.all(color: cs.outlineVariant.withOpacity(.3)),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(color: cs.surfaceContainerHighest),
            children: const [
              _Cell('العملية'),
              _Cell('المبلغ'),
              _Cell('النوع'),
              _Cell('التاريخ'),
            ],
          ),
          ...items.map(
            (t) => TableRow(
              children: [
                _Cell(t.name),
                _Cell(t.amount.toStringAsFixed(2), alignEnd: true),
                _Cell(t.isIncome ? 'دخل' : 'مصروف'),
                _Cell(DateFormat('yyyy-MM-dd HH:mm').format(t.date)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool alignEnd;
  const _Cell(this.text, {this.alignEnd = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Align(
        alignment: alignEnd
            ? Alignment.centerLeft
            : Alignment.centerRight, // RTL
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// مجرد غلاف padding كي نخفف تكرار الكود
class _Pad extends StatelessWidget {
  final Widget child;
  const _Pad({required this.child});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: child,
    );
  }
}

/// Text قابل لإعادة الاستخدام مع ellipsis (سنمرر له via Inherited النص المطلوب)
class _EllipsisText extends StatelessWidget {
  const _EllipsisText();
  @override
  Widget build(BuildContext context) {
    // هذا مجرد placeholder؛ لو تحب نعيد الجدول بسرعة لنسخة أبسط:
    return const Text(
      '—', // سيتم استبداله بالنسخة الأبسط أدناه (انظر الملاحظة)
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
