import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/transaction_model.dart';

final transactionBoxProvider = Provider<Box<TransactionModel>>((ref) {
  return Hive.box<TransactionModel>('transactions');
});

final appStateProvider = StateNotifierProvider<TransactionNotifier, List<TransactionModel>>((ref) {
  final box = ref.watch(transactionBoxProvider);
  return TransactionNotifier(box);
});

class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  final Box<TransactionModel> _box;

  TransactionNotifier(this._box) : super(_box.values.toList());

  void addTransaction(TransactionModel transaction) async {
    await _box.add(transaction);
    state = _box.values.toList();
  }

  void deleteTransaction(TransactionModel transaction) async {
    await transaction.delete();
    state = _box.values.toList();
  }

  void updateTransaction(TransactionModel transaction) async {
    await transaction.save();
    state = _box.values.toList();
  }

  List<String> getFolders() {
    return state.map((t) => t.folder).toSet().toList();
  }

  List<TransactionModel> getTransactionsForFolder(String folder) {
    return state.where((t) => t.folder == folder).toList();
  }

  List<String> getAccountsInFolder(String folder) {
    return getTransactionsForFolder(folder).map((t) => t.account).toSet().toList();
  }

  List<TransactionModel> getTransactionsForAccount(String folder, String account) {
    return getTransactionsForFolder(folder).where((t) => t.account == account).toList();
  }
}