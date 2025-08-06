import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';
import '../widgets/balances_card.dart';
import '../widgets/account_list.dart';
import 'add_transaction_screen.dart';

class FolderDetailsScreen extends ConsumerWidget {
  final String folderName;
  const FolderDetailsScreen({Key? key, required this.folderName}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folderTransactions = ref.watch(appStateProvider.notifier).getTransactionsForFolder(folderName);

    return Scaffold(
      appBar: AppBar(title: Text(folderName), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BalanceCard(transactions: folderTransactions),
            const SizedBox(height: 24),
            AccountList(
              transactions: folderTransactions,
              onAccountTap: (accountName) {},
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(folderName: folderName),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
