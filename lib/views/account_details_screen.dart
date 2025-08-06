import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/app_state_provider.dart';
import 'add_transaction_screen.dart';

class AccountDetailsScreen extends ConsumerWidget {
  final String folderName;
  final String accountName;

  const AccountDetailsScreen({Key? key, required this.folderName, required this.accountName}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(appStateProvider );
    final accountTransactions = transactions
        .where((t) => t.folder == folderName && t.account == accountName)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('تفاصيل $accountName')),
      body: ListView.builder(
        itemCount: accountTransactions.length,
        itemBuilder: (context, index) {
          final t = accountTransactions[index];
          return ListTile(
            title: Text(t.name),
            subtitle: Text(DateFormat.yMd('ar').format(t.date)),
            trailing: Text(
              '${t.isIncome ? '+' : '-'}${t.amount}',
              style: TextStyle(color: t.isIncome ? Colors.green : Colors.red),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(
                folderName: folderName,
                accountName: accountName,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}