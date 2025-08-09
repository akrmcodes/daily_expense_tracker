import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class AccountList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String folderName;
  final void Function(String accountName) onAccountTap;

  const AccountList({
    Key? key,
    required this.transactions,
    required this.folderName,
    required this.onAccountTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // استخراج أسماء الحسابات داخل هذا المجلد
    final accounts =
        transactions
            .where((t) => t.folder == folderName && t.account.isNotEmpty)
            .map((t) => t.account)
            .toSet()
            .toList()
          ..sort();

    return Column(
      children: accounts.map((accountName) {
        final accountTx = transactions
            .where((t) => t.folder == folderName && t.account == accountName)
            .toList();

        final balance = accountTx.fold<double>(
          0.0,
          (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
        );

        final balanceColor = balance >= 0 ? Colors.green : Colors.red;

        return Card(
          // بدون لون مخصص — يتبع الثيم
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: Text(
              accountName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('حساب'),
            trailing: Text(
              balance.toStringAsFixed(2),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: balanceColor,
              ),
            ),
            onTap: () => onAccountTap(accountName),
          ),
        );
      }).toList(),
    );
  }
}
