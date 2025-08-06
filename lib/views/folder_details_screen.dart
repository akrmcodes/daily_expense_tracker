import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../widgets/balances_card.dart';
import '../widgets/account_list.dart';
import 'add_transaction_screen.dart';

class FolderDetailsScreen extends StatelessWidget {
  final String folderName;
  final List<TransactionModel> allTransactions;

  const FolderDetailsScreen({
    Key? key,
    required this.folderName,
    required this.allTransactions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final folderTransactions = allTransactions
        .where((t) => t.folder == folderName)
        .toList();

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
              onAccountTap: (accountName) {
                // لاحقًا: فتح شاشة تفاصيل الحساب
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
                allTransactions:
                    allTransactions, // أو أي قائمة معاملات موجودة لديك
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
