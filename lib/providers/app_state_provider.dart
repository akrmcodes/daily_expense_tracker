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
}
