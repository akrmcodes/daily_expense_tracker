import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';

final inMemoryTransactionsProvider =
    StateProvider<List<TransactionModel>>((ref) => []);
