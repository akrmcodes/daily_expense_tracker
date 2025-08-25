import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/transaction_model.dart';

class ReportFilters {
  final String? folder;   // null => all folders
  final String? account;  // null => all accounts
  const ReportFilters({this.folder, this.account});

  bool get isAll => folder == null && account == null;
}

class ReportData {
  final List<TransactionModel> items;
  final double totalIncome;
  final double totalExpense;
  final double net;
  ReportData({
    required this.items,
    required this.totalIncome,
    required this.totalExpense,
  }) : net = totalIncome - totalExpense;
}

class ReportService {
  ReportData buildReport(List<TransactionModel> allTx, ReportFilters f) {
    final filtered = allTx.where((t) {
      final okFolder = f.folder == null || t.folder == f.folder;
      final okAccount = f.account == null || t.account == f.account;
      return okFolder && okAccount;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final income = filtered
        .where((t) => t.isIncome)
        .fold<double>(0.0, (s, t) => s + t.amount);

    final expense = filtered
        .where((t) => !t.isIncome)
        .fold<double>(0.0, (s, t) => s + t.amount);

    return ReportData(items: filtered, totalIncome: income, totalExpense: expense);
  }

  String buildCsv(ReportData data) {
    final b = StringBuffer();
    b.writeln('Name,Amount,Type,Date,Folder,Account,Notes');
    for (final t in data.items) {
      final type = t.isIncome ? 'Income' : 'Expense';
      final date = DateFormat('yyyy-MM-dd HH:mm').format(t.date);
      String q(String? s) {
        final v = (s ?? '').replaceAll('"', '""');
        return '"$v"';
      }
      b.writeln([
        q(t.name),
        t.amount.toStringAsFixed(2),
        type,
        q(date),
        q(t.folder),
        q(t.account),
        q(t.notes),
      ].join(','));
    }
    b.writeln();
    b.writeln('Income,${data.totalIncome.toStringAsFixed(2)}');
    b.writeln('Expense,${data.totalExpense.toStringAsFixed(2)}');
    b.writeln('Net,${data.net.toStringAsFixed(2)}');
    return b.toString();
  }

  Future<File> _writeTemp(String filename, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> _writeTempText(String filename, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content, flush: true);
    return file;
  }

  Future<void> exportCsvAndShare(ReportData data) async {
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final name = 'DET_Report_$ts.csv';
    final csv = buildCsv(data);
    final file = await _writeTempText(name, csv);
    await Share.shareXFiles([XFile(file.path)], text: 'تقرير المصروفات');
  }

  Future<void> exportPdfAndShare(ReportData data) async {
    final pdf = pw.Document();
    final df = DateFormat('yyyy-MM-dd HH:mm');

    pw.Widget rowHeader() => pw.Container(
      color: PdfColors.grey300,
      padding: pw.EdgeInsets.all(6),
      child: pw.Row(children: [
        pw.Expanded(flex: 3, child: pw.Text('العملية', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(width: 6),
        pw.Expanded(flex: 2, child: pw.Text('المبلغ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(width: 6),
        pw.Expanded(flex: 2, child: pw.Text('النوع', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(width: 6),
        pw.Expanded(flex: 3, child: pw.Text('التاريخ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(width: 6),
        pw.Expanded(flex: 2, child: pw.Text('المجلد')),
        pw.SizedBox(width: 6),
        pw.Expanded(flex: 2, child: pw.Text('الحساب')),
      ]),
    );

    pw.Widget rowItem(TransactionModel t) => pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(children: [
        pw.Expanded(flex: 3, child: pw.Text(t.name)),
        pw.SizedBox(width: 6),
        pw.Expanded(flex: 2, child: pw.Text(t.amount.toStringAsFixed(2))),
        pw.SizedBox(width: 6),
        pw.Expanded(flex: 2, child: pw.Text(t.isIncome ? 'دخل' : 'مصروف')),
        pw.SizedBox(width: 6),
        pw.Expanded(flex: 3, child: pw.Text(df.format(t.date))),
        pw.SizedBox(width: 6),
        pw.Expanded(flex: 2, child: pw.Text(t.folder)),
        pw.SizedBox(width: 6),
        pw.Expanded(flex: 2, child: pw.Text(t.account)),
      ]),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (ctx) => [
          pw.Text('تقرير المصروفات', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('الدخل: ${data.totalIncome.toStringAsFixed(2)}  |  المصروف: ${data.totalExpense.toStringAsFixed(2)}  |  الصافي: ${data.net.toStringAsFixed(2)}'),
          pw.SizedBox(height: 14),
          rowHeader(),
          pw.Divider(height: 1),
          ...data.items.map(rowItem),
        ],
      ),
    );

    final bytes = await pdf.save();
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = await _writeTemp('DET_Report_$ts.pdf', Uint8List.fromList(bytes));
    await Share.shareXFiles([XFile(file.path)], text: 'تقرير المصروفات (PDF)');
  }
}
