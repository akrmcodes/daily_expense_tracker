import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';

class FolderState extends StateNotifier<List<TransactionModel>> {
  FolderState() : super([]);

  void addFolder(String folderName) {
    // نضيف مجلد بدون معاملات (كمجرد معرف فارغ)
    state = [...state, ..._generatePlaceholder(folderName)];
  }

  void addTransaction(TransactionModel transaction) {
    state = [...state, transaction];
  }

  List<String> getAllFolders() {
    return state.map((t) => t.folder).toSet().toList();
  }

  List<TransactionModel> getTransactionsByFolder(String folderName) {
    return state.where((t) => t.folder == folderName).toList();
  }

  List<TransactionModel> _generatePlaceholder(String folderName) {
    return []; // لا نضيف معاملة فعلية، فقط نتأكد أن الاسم محفوظ في القائمة من خلال إضافة لاحقة
  }
}

final folderProvider =
    StateNotifierProvider<FolderState, List<TransactionModel>>((ref) {
  return FolderState();
});
