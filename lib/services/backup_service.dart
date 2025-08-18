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
  static const _customExt = '.detb';

  String _buildFileName({bool withCustomExt = true}) {
    // مثال: expense_backup_2025-01-15_21-30-05.detb
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
    } catch (_) {}

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
                'name': f.name,
                'parentFolderId': f.parentFolderId,
              })
          .toList(),
    'transactions': state.transactions
          .map((t) => {
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

  /// حفظ في Downloads/DailyExpenseTracker + مشاركة اختيارية
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

  /// احفظ في مكان يختاره المستخدم (حوار حفظ)
  Future<File?> exportWithPicker() async {
    final suggested = _buildFileName();
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'اختر مكان الحفظ',
      fileName: suggested,
      type: FileType.custom,
      allowedExtensions: ['detb', 'json'],
    );
    if (savePath == null) return null;

    final jsonStr = const JsonEncoder.withIndent('  ').convert(_collectData());
    final file = File(savePath);
    await file.create(recursive: true);
    await file.writeAsString(jsonStr);
    return file;
  }

  /// استيراد عبر منتقي الملفات ثم استبدال/دمج حسب `merge`
  Future<void> importFromPicker(BuildContext context, {required bool merge}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['detb', 'json'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single.path;
    if (picked == null) return;

    final file = File(picked);
    await _importFromFile(file, merge: merge);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Text(merge ? 'تم الدمج بنجاح' : 'تم الاستبدال بنجاح'),
        ),
      );
    }
  }

  Future<void> _importFromFile(File file, {required bool merge}) async {
    final txt = await file.readAsString();
    final map = jsonDecode(txt) as Map<String, dynamic>;
    await _restoreFromMap(map, merge: merge);
  }

  Future<void> _restoreFromMap(Map<String, dynamic> data, {required bool merge}) async {
    final txBox = Hive.box<TransactionModel>('transactions');
    final folderBox = Hive.box<FolderModel>('folders');

    if (!merge) {
      // استبدال كلي
      await txBox.clear();
      await folderBox.clear();
    }

    // --- استعادة/دمج المجلدات ---
    final existingFolders = folderBox.values.toList();
    final existingFolderKey = <String, FolderModel>{
      for (final f in existingFolders) _folderKey(f.name, f.parentFolderId): f
    };

    final folders = (data['folders'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map((m) => FolderModel(
              name: m['name'] as String,
              parentFolderId: m['parentFolderId'] as int?,
            ))
        .toList();

    for (final f in folders) {
      final key = _folderKey(f.name, f.parentFolderId);
      if (!existingFolderKey.containsKey(key)) {
        await folderBox.add(f);
        existingFolderKey[key] = f;
      }
    }

    // --- استعادة/دمج المعاملات ---
    final existingTx = txBox.values.toList();
    final existingSig = <String>{for (final t in existingTx) _txSignature(t)};

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
      final sig = _txSignature(t);
      if (!existingSig.contains(sig)) {
        await txBox.add(t);
        existingSig.add(sig);
      }
    }

    await _read(appStateProvider.notifier).loadData();
  }

  // مفاتيح/تواقيع للمطابقة
  String _folderKey(String name, int? parentId) => '${name.trim()}|${parentId ?? -1}';

  String _txSignature(TransactionModel t) {
    final n = (t.notes ?? '').trim();
    return [
      t.name.trim(),
      t.amount.toStringAsFixed(4),
      t.isIncome ? '1' : '0',
      t.date.toIso8601String(),
      t.folder.trim(),
      t.account.trim(),
      n,
    ].join('|');
  }
}
