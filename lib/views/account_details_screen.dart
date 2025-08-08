import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/app_state_provider.dart';
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
    final transactions = ref.watch(appStateProvider);

    // تصفية المعاملات حسب الحساب والمجلد
    final accountTransactions =
        transactions
            .where((t) => t.folder == folderName && t.account == accountName)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    // حساب الرصيد
    double totalIncome = accountTransactions
        .where((t) => t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);
    double totalExpense = accountTransactions
        .where((t) => !t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);
    double netBalance = totalIncome - totalExpense;
    double runningBalance = 0;

    return Scaffold(
      appBar: AppBar(title: Text('تفاصيل $accountName')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Balance Card
            Card(
              color: Colors.grey[900],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "الدخل: +${totalIncome.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.green),
                    ),
                    Text(
                      "المصروف: -${totalExpense.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.red),
                    ),
                    const Divider(),
                    Text(
                      "الرصيد الصافي: ${netBalance.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text("المعاملات:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            // ✅ قائمة العمليات
            Expanded(
              child: ListView.builder(
                itemCount: accountTransactions.length,
                itemBuilder: (_, i) {
                  final t = accountTransactions[i];
                  runningBalance += t.isIncome ? t.amount : -t.amount;

                  return Card(
                    color: Colors.grey[850],
                    child: ListTile(
                      title: Text(t.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat.yMMMd('ar').format(t.date)),
                          if (t.notes != null && t.notes!.isNotEmpty)
                            Text("ملاحظة: ${t.notes!}"),
                          Text(
                            "الرصيد بعد العملية: \$${runningBalance.toStringAsFixed(2)}",
                          ),
                        ],
                      ),
                      trailing: Text(
                        "${t.isIncome ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: t.isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  );
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
