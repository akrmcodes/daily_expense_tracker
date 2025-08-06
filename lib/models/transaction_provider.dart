import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:rxdart/rxdart.dart';
import '../models/transaction_model.dart';

final transactionBoxProvider = Provider<Box<TransactionModel>>((ref) {
  return Hive.box<TransactionModel>('transactions');
});

final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final box = ref.watch(transactionBoxProvider);
  return box.watch().map((_) => box.values.toList()).startWith(box.values.toList());
});
