// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../models/folder_model.dart';
import '../models/transaction_model.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

class BackupService {
  Future<String> exportAllToTempFile() async {
    final folderBox = Hive.box<FolderModel>('folders');
    final txBox = Hive.box<TransactionModel>('transactions');

    final folders = folderBox.values.toList();
    final txs = txBox.values.toList();

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'folders': folders.map(_folderToMap).toList(),
      'transactions': txs.map(_txToMap).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/expense_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(jsonStr, flush: true);
    return file.path; // نرجّع المسار للواجهة
  }

  Future<void> shareFile(String path) async {
    final xfile = XFile(path, mimeType: 'application/json');
    await Share.shareXFiles([xfile], text: 'نسخة احتياطية من بيانات التطبيق');
  }

  Future<ImportResult> importFromJsonWithPicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) {
      return ImportResult(cancelled: true);
    }
    final path = result.files.single.path;
    if (path == null) return ImportResult(cancelled: true);

    final file = File(path);
    final jsonStr = await file.readAsString();
    return importFromJsonString(jsonStr);
  }

  Future<ImportResult> importFromJsonString(String jsonStr) async {
    try {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final folders = (map['folders'] as List?) ?? [];
      final transactions = (map['transactions'] as List?) ?? [];

      final folderBox = Hive.box<FolderModel>('folders');
      final txBox = Hive.box<TransactionModel>('transactions');

      int foldersAdded = 0;
      int txAdded = 0;

      final existingFolders = folderBox.values.toList();
      bool folderExists(FolderModel f) {
        return existingFolders.any(
          (e) => e.name == f.name && e.parentFolderId == f.parentFolderId,
        );
      }

      for (final f in folders) {
        final folder = _folderFromMap(Map<String, dynamic>.from(f));
        if (!folderExists(folder)) {
          await folderBox.add(folder);
          existingFolders.add(folder);
          foldersAdded++;
        }
      }

      final existingTx = txBox.values.toList();
      bool txExists(TransactionModel t) {
        return existingTx.any((e) =>
            e.name == t.name &&
            e.amount == t.amount &&
            e.isIncome == t.isIncome &&
            e.date.millisecondsSinceEpoch == t.date.millisecondsSinceEpoch &&
            e.folder == t.folder &&
            e.account == t.account &&
            (e.notes ?? '') == (t.notes ?? ''));
      }

      for (final t in transactions) {
        final tx = _txFromMap(Map<String, dynamic>.from(t));
        if (!txExists(tx)) {
          await txBox.add(tx);
          existingTx.add(tx);
          txAdded++;
        }
      }

      return ImportResult(
        cancelled: false,
        foldersAdded: foldersAdded,
        transactionsAdded: txAdded,
      );
    } catch (e, st) {
      if (kDebugMode) print('Import error: $e\n$st');
      return ImportResult(cancelled: false, error: e.toString());
    }
  }

  Map<String, dynamic> _folderToMap(FolderModel f) => {
        'name': f.name,
        'parentFolderId': f.parentFolderId,
      };

  FolderModel _folderFromMap(Map<String, dynamic> m) {
    return FolderModel(
      name: m['name'] as String,
      parentFolderId: (m['parentFolderId'] as num?)?.toInt(),
    );
    }

  Map<String, dynamic> _txToMap(TransactionModel t) => {
        'name': t.name,
        'amount': t.amount,
        'isIncome': t.isIncome,
        'date': t.date.millisecondsSinceEpoch,
        'folder': t.folder,
        'account': t.account,
        'notes': t.notes,
      };

  TransactionModel _txFromMap(Map<String, dynamic> m) {
    return TransactionModel(
      name: m['name'] as String,
      amount: (m['amount'] as num).toDouble(),
      isIncome: m['isIncome'] as bool,
      date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
      folder: m['folder'] as String,
      account: m['account'] as String,
      notes: (m['notes'] as String?)?.trim().isEmpty == true
          ? null
          : m['notes'] as String?,
    );
  }
}

class ImportResult {
  final bool cancelled;
  final int foldersAdded;
  final int transactionsAdded;
  final String? error;

  ImportResult({
    required this.cancelled,
    this.foldersAdded = 0,
    this.transactionsAdded = 0,
    this.error,
  });
}
