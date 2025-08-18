import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/transaction_model.dart';
import '../models/folder_model.dart';


/// الحالة العامة للتطبيق تشمل المعاملات والمجلدات
class AppState {
  final List<TransactionModel> transactions;
  final List<FolderModel> folders;

  AppState({
    required this.transactions,
    required this.folders,
  });
}

/// مزود الحالة باستخدام Riverpod
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

/// مدير الحالة
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState(transactions: [], folders: [])) {
    _loadData();
  }

  Future<void> loadData() async => _loadData();
  
  Future<void> _loadData() async {
    final transactionBox = Hive.box<TransactionModel>('transactions');
    final folderBox = Hive.box<FolderModel>('folders');

    final transactions = transactionBox.values.toList();
    final folders = folderBox.values.toList();

    state = AppState(transactions: transactions, folders: folders);
  }

  void addTransaction(TransactionModel transaction) async {
    final box = Hive.box<TransactionModel>('transactions');
    await box.add(transaction);
    final updated = [...state.transactions, transaction];
    state = AppState(transactions: updated, folders: state.folders);
  }

  void deleteTransaction(TransactionModel transaction) async {
    await transaction.delete();
    final updated = state.transactions.where((t) => t.key != transaction.key).toList();
    state = AppState(transactions: updated, folders: state.folders);
  }

  Future<void> addFolder(FolderModel folder) async {
    final box = Hive.box<FolderModel>('folders');

    // 🟣 إضافة المجلد في Hive
    await box.add(folder);

    // ✅ إعادة تحميل المجلدات المحدثة
    final updatedFolders = box.values.toList();

    // 🔁 تحديث الحالة
    state = AppState(
      transactions: state.transactions,
      folders: updatedFolders,
    );
  }

  void addAccount(String folderName, String accountName) async {
    final box = Hive.box<TransactionModel>('transactions');
    final dummy = TransactionModel(
      name: 'حساب $accountName',
      amount: 0,
      isIncome: true,
      date: DateTime.now(),
      folder: folderName,
      account: accountName,
      notes: 'تم إنشاء الحساب',
    );
    await box.add(dummy);
    final updated = [...state.transactions, dummy];
    state = AppState(transactions: updated, folders: state.folders);
  }
    // ====== Transactions ======

  Future<void> updateTransaction(int key, TransactionModel updated) async {
    final box = Hive.box<TransactionModel>('transactions');
    await box.put(key, updated);
    final refreshed = box.values.toList();
    state = AppState(transactions: refreshed, folders: state.folders);
  }

  Future<void> deleteTransactionByKey(int key) async {
    final box = Hive.box<TransactionModel>('transactions');
    await box.delete(key);
    final refreshed = box.values.toList();
    state = AppState(transactions: refreshed, folders: state.folders);
  }

  // ====== Folders ======

  /// يحذف المجلد فقط إذا لم يكن يحتوي معاملات ولا مجلدات فرعية.
  /// يعيد true لو تم الحذف، false لو المجلد غير فارغ.
  Future<bool> deleteFolderIfEmpty(int folderKey) async {
    final folderBox = Hive.box<FolderModel>('folders');
    final folder = state.folders.firstWhere((f) => f.key == folderKey);

    // تحقق من المجلدات الفرعية
    final hasSubfolders = state.folders.any((f) => f.parentFolderId == folderKey);

    // تحقق من المعاملات المنتمية لهذا المجلد بالاسم
    final hasTransactions = state.transactions.any((t) => t.folder == folder.name);

    if (hasSubfolders || hasTransactions) return false;

    await folderBox.delete(folderKey);
    final refreshedFolders = folderBox.values.toList();
    state = AppState(transactions: state.transactions, folders: refreshedFolders);
    return true;
  }

  Future<void> renameFolder(int folderKey, String newName) async {
    final folderBox = Hive.box<FolderModel>('folders');
    final folder = state.folders.firstWhere((f) => f.key == folderKey);
    // ننشئ كائن جديد بنفس parent لكن باسم جديد
    final updated = FolderModel(name: newName, parentFolderId: folder.parentFolderId);
    await folderBox.put(folderKey, updated);

    // لو أردت تعكس الاسم الجديد على المعاملات المرتبطة بهذا المجلد:
    final txBox = Hive.box<TransactionModel>('transactions');
    final txList = txBox.values.toList();
    for (var i = 0; i < txList.length; i++) {
      final tx = txList[i];
      if (tx.folder == folder.name) {
        // ننشئ نسخة محدثة باسم المجلد الجديد
        final newTx = TransactionModel(
          name: tx.name,
          amount: tx.amount,
          isIncome: tx.isIncome,
          date: tx.date,
          folder: newName,
          account: tx.account,
          notes: tx.notes,
        );
        await txBox.put(tx.key as int, newTx);
      }
    }

    state = AppState(
      transactions: txBox.values.toList(),
      folders: folderBox.values.toList(),
    );
  }
  
    // ====== Folders: حذف شامل (Cascade) ======
  Future<void> deleteFolderCascade(int folderKey) async {
    final folderBox = Hive.box<FolderModel>('folders');
    final txBox = Hive.box<TransactionModel>('transactions');

    final folder = state.folders.firstWhere((f) => f.key == folderKey);

    // 1) حذف معاملات هذا المجلد
    final txKeysToDelete = state.transactions
        .where((t) => t.folder == folder.name)
        .map((t) => t.key as int)
        .toList();
    if (txKeysToDelete.isNotEmpty) {
      await txBox.deleteAll(txKeysToDelete);
    }

    // 2) حذف المجلدات الفرعية بشكل recursive
    final subfolders = state.folders
        .where((f) => f.parentFolderId == folderKey)
        .toList();
    for (final sub in subfolders) {
      await deleteFolderCascade(sub.key as int);
    }

    // 3) حذف المجلد نفسه
    await folderBox.delete(folderKey);

    // 4) تحديث الحالة
    state = AppState(
      transactions: txBox.values.toList(),
      folders: folderBox.values.toList(),
    );
  }

  // ====== Accounts: عمليات على مستوى الحساب (غير مخزَّن ككيان مستقل) ======

  bool isAccountEmpty(String folderName, String accountName) {
    return !state.transactions.any(
      (t) => t.folder == folderName && t.account == accountName,
    );
  }

  Future<bool> deleteAccountIfEmpty(String folderName, String accountName) async {
    final txBox = Hive.box<TransactionModel>('transactions');

    // إذا كان فارغ فعلاً، ممكن يكون فيه dummy قديم وقت إنشاء الحساب — نحذفه إن وجد
    final dummies = state.transactions
        .where((t) =>
            t.folder == folderName &&
            t.account == accountName &&
            t.amount == 0 &&
            (t.notes ?? '').contains('تم إنشاء الحساب'))
        .map((t) => t.key as int)
        .toList();

    if (dummies.isNotEmpty) {
      await txBox.deleteAll(dummies);
    }

    state = AppState(
      transactions: txBox.values.toList(),
      folders: state.folders,
    );
    return true;
  }

  Future<void> deleteAccountCascade(String folderName, String accountName) async {
    final txBox = Hive.box<TransactionModel>('transactions');
    final keys = state.transactions
        .where((t) => t.folder == folderName && t.account == accountName)
        .map((t) => t.key as int)
        .toList();

    if (keys.isNotEmpty) {
      await txBox.deleteAll(keys);
    }

    state = AppState(
      transactions: txBox.values.toList(),
      folders: state.folders,
    );
  }

  Future<void> renameAccount(
      String folderName, String oldAccountName, String newAccountName) async {
    final txBox = Hive.box<TransactionModel>('transactions');

    for (final tx in txBox.values) {
      if (tx.folder == folderName && tx.account == oldAccountName) {
        final newTx = TransactionModel(
          name: tx.name,
          amount: tx.amount,
          isIncome: tx.isIncome,
          date: tx.date,
          folder: tx.folder,
          account: newAccountName,
          notes: tx.notes,
        );
        await txBox.put(tx.key as int, newTx);
      }
    }

    state = AppState(
      transactions: txBox.values.toList(),
      folders: state.folders,
    );
  }


}
