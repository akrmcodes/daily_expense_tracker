import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/transaction_model.dart';

class ReportFilters {
  final String? folder; // null => كل المجلدات
  final String? account; // null => كل الحسابات
  const ReportFilters({this.folder, this.account});
}

class ReportData {
  final List<TransactionModel> items;
  final double totalIncome;
  final double totalExpense;
  double get net => totalIncome - totalExpense;

  ReportData({
    required this.items,
    required this.totalIncome,
    required this.totalExpense,
  });
}

class ReportService {
  // ===== بناء بيانات التقرير =====
  ReportData buildReport(List<TransactionModel> allTx, ReportFilters f) {
    final filtered = allTx.where((t) {
      final okFolder = f.folder == null || t.folder == f.folder;
      final okAccount = f.account == null || t.account == f.account;
      return okFolder && okAccount;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final income = filtered
        .where((t) => t.isIncome)
        .fold<double>(0.0, (s, t) => s + t.amount);

    final expense = filtered
        .where((t) => !t.isIncome)
        .fold<double>(0.0, (s, t) => s + t.amount);

    return ReportData(
      items: filtered,
      totalIncome: income,
      totalExpense: expense,
    );
  }

  // ===== CSV =====
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

      b.writeln(
        [
          q(t.name),
          t.amount.toStringAsFixed(2),
          type,
          q(date),
          q(t.folder),
          q(t.account),
          q(t.notes),
        ].join(','),
      );
    }
    b.writeln();
    b.writeln('Income,${data.totalIncome.toStringAsFixed(2)}');
    b.writeln('Expense,${data.totalExpense.toStringAsFixed(2)}');
    b.writeln('Net,${data.net.toStringAsFixed(2)}');
    return b.toString();
  }

  // اسم ملف مقترح: DET_Report_yyyyMMdd_HHmmss.ext
  String _suggestedName(String ext) {
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'DET_Report_$ts.$ext';
  }

  /// محاولة الحفظ باختيار المكان (CSV) — تُعالج Android/iOS بتمرير bytes.
  Future<bool> saveCsvWithPicker(ReportData data) async {
    final name = _suggestedName('csv');
    final csv = buildCsv(data);
    final bytes = Uint8List.fromList(utf8.encode(csv));

    // على Android/iOS يجب تمرير bytes لـ SAF
    if (Platform.isAndroid || Platform.isIOS) {
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'اختر مكان الحفظ (CSV)',
        fileName: name,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes, // << مهم على الجوال
      );
      return savedPath != null;
    }

    // على سطح المكتب: نكتب يدويًا في المسار المُختار
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'اختر مكان الحفظ (CSV)',
      fileName: name,
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (path == null) return false;

    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return true;
  }

  // ===== PDF =====

  Future<({pw.Font base, pw.Font bold})> _loadArabicFonts() async {
    final baseData = await rootBundle.load(
      'assets/fonts/NotoNaskhArabic-Regular.ttf',
    );
    final boldData = await rootBundle.load(
      'assets/fonts/NotoNaskhArabic-Bold.ttf',
    );
    return (base: pw.Font.ttf(baseData), bold: pw.Font.ttf(boldData));
  }

  Future<Uint8List> _buildPdfBytes(ReportData data) async {
    final pdf = pw.Document();
    final fonts = await _loadArabicFonts();
    final df = DateFormat('yyyy-MM-dd HH:mm');

    final theme = pw.ThemeData.withFont(base: fonts.base, bold: fonts.bold);

    pw.Widget headerRow() => pw.Container(
      padding: pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: pw.BoxDecoration(color: PdfColors.grey300),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              'العملية',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              'المبلغ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              'النوع',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              'التاريخ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(flex: 2, child: pw.Text('المجلد')),
          pw.SizedBox(width: 6),
          pw.Expanded(flex: 2, child: pw.Text('الحساب')),
        ],
      ),
    );

    pw.Widget txRow(TransactionModel t) => pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Text(t.name, textAlign: pw.TextAlign.right),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              t.amount.toStringAsFixed(2),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              t.isIncome ? 'دخل' : 'مصروف',
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            flex: 3,
            child: pw.Text(df.format(t.date), textAlign: pw.TextAlign.right),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            flex: 2,
            child: pw.Text(t.folder, textAlign: pw.TextAlign.right),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            flex: 2,
            child: pw.Text(t.account, textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  'تقرير المصروفات',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'الدخل: ${data.totalIncome.toStringAsFixed(2)}    المصروف: ${data.totalExpense.toStringAsFixed(2)}    الصافي: ${data.net.toStringAsFixed(2)}',
                ),
                pw.SizedBox(height: 14),
                headerRow(),
                pw.Divider(height: 1),
                ...data.items.map(txRow),
              ],
            ),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    return Uint8List.fromList(bytes);
  }

  /// محاولة الحفظ باختيار المكان (PDF) — تُعالج Android/iOS بتمرير bytes.
  Future<bool> savePdfWithPicker(ReportData data) async {
    final name = _suggestedName('pdf');
    final bytes = await _buildPdfBytes(data);

    if (Platform.isAndroid || Platform.isIOS) {
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'اختر مكان الحفظ (PDF)',
        fileName: name,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes, // << مهم على الجوال
      );
      return savedPath != null;
    }

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'اختر مكان الحفظ (PDF)',
      fileName: name,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (path == null) return false;

    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return true;
  }

  // ===== Fallback للحفظ في Downloads/DailyExpenseTracker =====

  Future<Directory> _ensureDownloadsAppDir() async {
    Directory? downloadsDir;
    try {
      final dirs = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      if (dirs != null && dirs.isNotEmpty) downloadsDir = dirs.first;
    } catch (_) {}
    downloadsDir ??= await getApplicationDocumentsDirectory();

    final appDir = Directory('${downloadsDir.path}/DailyExpenseTracker');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  Future<File> saveCsvToDownloads(ReportData data) async {
    final dir = await _ensureDownloadsAppDir();
    final name = _suggestedName('csv');
    final path = '${dir.path}/$name';
    final csv = buildCsv(data);
    final bytes = Uint8List.fromList(utf8.encode(csv));
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> savePdfToDownloads(ReportData data) async {
    final dir = await _ensureDownloadsAppDir();
    final name = _suggestedName('pdf');
    final path = '${dir.path}/$name';
    final bytes = await _buildPdfBytes(data);
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
