import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/transaction_model.dart';

final appStateProvider = StateNotifierProvider<AppStateNotifier, List<TransactionModel>>((ref) {
  return AppStateNotifier();
});

class AppStateNotifier extends StateNotifier<List<TransactionModel>> {
  AppStateNotifier() : super([]) {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final box = Hive.box<TransactionModel>('transactions');
    state = box.values.toList();
  }

  void addTransaction(TransactionModel transaction) async {
    final box = Hive.box<TransactionModel>('transactions');
    await box.add(transaction);
    state = [...state, transaction];
  }

  void deleteTransaction(TransactionModel transaction) async {
    await transaction.delete();
    state = state.where((t) => t.key != transaction.key).toList();
  }
  void addAccount(String folder, String account) {
  final newTransaction = TransactionModel(
    name: "",
    amount: 0,
    isIncome: true,
    date: DateTime.now(),
    folder: folder,
    account: account,
  );
  final box = Hive.box<TransactionModel>('transactions');
  box.add(newTransaction);
  state = [...state, newTransaction];
}
  
}