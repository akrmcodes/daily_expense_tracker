// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive/hive.dart';

import '../providers/app_state_provider.dart';
import '../models/transaction_model.dart';
import '../models/folder_model.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.read);
});

class BackupService {
  BackupService(this._read);
  final T Function<T>(ProviderListenable<T>) _read;

  static const _appFolderName = 'DailyExpenseTracker';
  static const _customExt = '.detb'; // امتداد مخصص: الملف JSON من الداخل لكنه .detb خارجياً

  String _buildFileName({bool withCustomExt = true}) {
    final ts = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final base = 'expense_backup_$ts.json';
    return withCustomExt ? base.replaceAll('.json', _customExt) : base;
  }

  Future<Directory> _ensureDownloadsAppDir() async {
    Directory? downloadsDir;

    try {
      final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
      if (dirs != null && dirs.isNotEmpty) {
        downloadsDir = dirs.first;
      }
    } catch (_) {
      // تجاهل — نجرّب بديل
    }

    downloadsDir ??= await getApplicationDocumentsDirectory();

    final appDir = Directory('${downloadsDir.path}/$_appFolderName');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  Map<String, dynamic> _collectData() {
    final state = _read(appStateProvider);
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'folders': state.folders
          .map((f) => {
                'key': f.key,
                'name': f.name,
                'parentFolderId': f.parentFolderId,
              })
          .toList(),
      'transactions': state.transactions
          .map((t) => {
                'key': t.key,
                'name': t.name,
                'amount': t.amount,
                'isIncome': t.isIncome,
                'date': t.date.toIso8601String(),
                'folder': t.folder,
                'account': t.account,
                'notes': t.notes,
              })
          .toList(),
    };
  }

  /// تصدير إلى Downloads/DailyExpenseTracker
  Future<File> exportToDownloads({bool shareAfter = true}) async {
    final dir = await _ensureDownloadsAppDir();
    final filePath = '${dir.path}/${_buildFileName()}';

    final jsonStr = const JsonEncoder.withIndent('  ').convert(_collectData());
    final file = File(filePath);
    await file.writeAsString(jsonStr);

    if (shareAfter) {
      await Share.shareXFiles([XFile(file.path)], text: 'نسخة احتياطية');
    }
    return file;
  }

  /// استيراد عبر File Picker — يقبل .detb أو .json
  Future<void> importFromPicker(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['detb', 'json'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single.path;
    if (picked == null) return;

    final file = File(picked);
    await _importFromFile(file);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم استيراد النسخة الاحتياطية بنجاح')),
      );
    }
  }

  Future<void> importFromFilePath(String path) async {
    await _importFromFile(File(path));
  }

  Future<void> _importFromFile(File file) async {
    final txt = await file.readAsString();
    final map = jsonDecode(txt) as Map<String, dynamic>;
    await _restoreFromMap(map);
  }

  Future<void> _restoreFromMap(Map<String, dynamic> data) async {
    final txBox = Hive.box<TransactionModel>('transactions');
    final folderBox = Hive.box<FolderModel>('folders');

    // 1) تفريغ (بدون دمج — سهل وواضح)
    await txBox.clear();
    await folderBox.clear();

    // 2) استعادة المجلدات
    final folders = (data['folders'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map((m) => FolderModel(
              name: m['name'] as String,
              parentFolderId: m['parentFolderId'] as int?,
            ))
        .toList();
    for (final f in folders) {
      await folderBox.add(f);
    }

    // 3) استعادة المعاملات
    final txs = (data['transactions'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map((m) => TransactionModel(
              name: m['name'] as String,
              amount: (m['amount'] as num).toDouble(),
              isIncome: m['isIncome'] as bool,
              date: DateTime.parse(m['date'] as String),
              folder: m['folder'] as String,
              account: m['account'] as String,
              notes: m['notes'] as String?,
            ))
        .toList();
    for (final t in txs) {
      await txBox.add(t);
    }

    // 4) تحديث الحالة
    await _read(appStateProvider.notifier).loadData();
  }
}
