import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';

class AccountDetailsScreen extends ConsumerWidget {
  final String folderName;
  final String accountName;

  const AccountDetailsScreen({
    Key? key,
    required this.folderName,
    required this.accountName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    final accountTransactions = appState.transactions
        .where((t) => t.folder == folderName && t.account == accountName)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final totalIncome = accountTransactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = accountTransactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    final netBalance = totalIncome - totalExpense;

    double runningBalance = 0;

    return Scaffold(
      appBar: AppBar(title: Text('تفاصيل $accountName')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.grey[900],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("الدخل: +${totalIncome.toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.green)),
                    Text("المصروف: -${totalExpense.toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.red)),
                    const Divider(),
                    Text("الرصيد الصافي: ${netBalance.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text("المعاملات:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: accountTransactions.length,
                itemBuilder: (_, i) {
                  final t = accountTransactions[i];
                  final nextBalance = runningBalance + (t.isIncome ? t.amount : -t.amount);
                  final card = TransactionCard(
                    transaction: t,
                    runningBalanceAfter: nextBalance,
                  );
                  runningBalance = nextBalance; // تحديث الرصيد الجاري
                  return card;
                },
              ),
            ),
          ],
        ),
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
