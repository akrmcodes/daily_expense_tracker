import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/app_state_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to   = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appStateProvider);

    final txInRange = app.transactions.where((t) {
      final d = t.date;
      return !d.isBefore(_from) && !d.isAfter(_to);
    }).toList();

    final totalIncome = txInRange.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.amount);
    final totalExpense= txInRange.where((t) => !t.isIncome).fold<double>(0, (s, t) => s + t.amount);
    final net = totalIncome - totalExpense;

    // تجميع حسب المجلد/الحساب
    final Map<String, double> byFolder = {};
    final Map<String, double> byAccount = {};
    for (final t in txInRange) {
      final delta = t.isIncome ? t.amount : -t.amount;
      byFolder[t.folder]  = (byFolder[t.folder]  ?? 0) + delta;
      final accKey = '${t.folder} / ${t.account}';
      byAccount[accKey]   = (byAccount[accKey]   ?? 0) + delta;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DateRangePicker(
            from: _from,
            to: _to,
            onChanged: (f, t) => setState(() { _from = f; _to = t; }),
          ),

          const SizedBox(height: 12),
          _SummaryCard(totalIncome: totalIncome, totalExpense: totalExpense, net: net),

          const SizedBox(height: 16),
          Text('حسب المجلد', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _kvTable(context, byFolder),

          const SizedBox(height: 16),
          Text('حسب الحساب', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _kvTable(context, byAccount),

          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.ios_share),
            label: const Text('تصدير CSV ومشاركته'),
            onPressed: () async {
              await _exportCsvAndShare(
                context: context,
                from: _from,
                to: _to,
                rows: txInRange.map((t) => [
                  DateFormat('yyyy-MM-dd').format(t.date),
                  t.folder,
                  t.account,
                  t.name,
                  t.isIncome ? 'دخل' : 'مصروف',
                  t.amount.toStringAsFixed(2),
                  t.notes ?? '',
                ]).toList(),
              );
            },
          )
        ],
      ),
    );
  }

  Future<void> _exportCsvAndShare({
    required BuildContext context,
    required DateTime from,
    required DateTime to,
    required List<List<String>> rows,
  }) async {
    // رأس CSV
    final buffer = StringBuffer();
    buffer.writeln('date,folder,account,name,type,amount,notes');
    for (final r in rows) {
      buffer.writeln(r.map(_csvEscape).join(','));
    }

    final tmp = await getTemporaryDirectory();
    final name = 'report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${tmp.path}/$name');
    await file.writeAsString(buffer.toString(), flush: true);

    await Share.shareXFiles([XFile(file.path)], text: 'تقرير المعاملات ($name)');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إنشاء ${file.path}')),
      );
    }
  }

  String _csvEscape(String s) {
    final needQuotes = s.contains(',') || s.contains('"') || s.contains('\n');
    var out = s.replaceAll('"', '""');
    if (needQuotes) out = '"$out"';
    return out;
  }

  Widget _kvTable(BuildContext context, Map<String, double> map) {
    if (map.isEmpty) {
      return Opacity(
        opacity: 0.7,
        child: Text('لا يوجد بيانات في النطاق المحدد', style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: entries.map((e) {
          final color = e.value >= 0 ? Colors.green : Colors.red;
          return ListTile(
            title: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(e.value.toStringAsFixed(2), style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          );
        }).toList(),
      ),
    );
  }
}

class _DateRangePicker extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final void Function(DateTime from, DateTime to) onChanged;
  const _DateRangePicker({required this.from, required this.to, required this.onChanged, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('y/MM/dd', 'ar');
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.date_range),
        title: Text('الفترة: ${fmt.format(from)} → ${fmt.format(to)}'),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(now.year - 5),
            lastDate: DateTime(now.year + 5),
            initialDateRange: DateTimeRange(start: from, end: to),
            locale: const Locale('ar'),
            builder: (context, child) => Theme(data: Theme.of(context), child: child!),
          );
          if (picked != null) onChanged(picked.start, picked.end);
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double net;
  const _SummaryCard({required this.totalIncome, required this.totalExpense, required this.net, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final netColor = net >= 0 ? Colors.green : Colors.red;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _metric(context, 'الدخل', '+${totalIncome.toStringAsFixed(2)}', Colors.green),
            const SizedBox(width: 12),
            _metric(context, 'المصروف', '-${totalExpense.toStringAsFixed(2)}', Colors.red),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('الصافي', style: Theme.of(context).textTheme.titleMedium),
                Text(net.toStringAsFixed(2), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: netColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(BuildContext ctx, String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(ctx).textTheme.bodyMedium),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
