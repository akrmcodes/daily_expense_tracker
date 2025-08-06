import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../models/transaction_provider.dart';
import '../widgets/balances_card.dart';
import '../widgets/folder_list.dart';
import '../views/add_transaction_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        return Scaffold(
          appBar: AppBar(title: const Text('متتبع المصاريف'), centerTitle: true),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BalanceCard(transactions: transactions),
                const SizedBox(height: 20),
                FolderList(
                  transactions: transactions,
                  onFolderTap: (folderName) {
                    // الانتقال لتفاصيل المجلد
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddTransactionScreen(
                    allTransactions: transactions,
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('خطأ: $error')),
      ),
    );
  }
}
