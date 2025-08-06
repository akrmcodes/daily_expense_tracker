import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class AccountList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String folderName;
  final void Function(String accountName)? onAccountTap;

  const AccountList({
    Key? key,
    required this.transactions,
    required this.folderName,
    this.onAccountTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accounts = transactions.map((t) => t.account).toSet().toList();

    return Column(
      children: accounts.map((account) {
        final accountTransactions = transactions
            .where((t) => t.account == account)
            .toList();
        final balance = accountTransactions.fold<double>(
          0.0,
          (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
        );

        return Card(
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              account,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "الرصيد: ${balance.toStringAsFixed(2)} — عدد العمليات: ${accountTransactions.length}",
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => onAccountTap?.call(account),
          ),
        );
      }).toList(),
    );
  }
}
