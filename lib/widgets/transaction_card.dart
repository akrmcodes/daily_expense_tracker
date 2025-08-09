import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  /// الرصيد بعد تنفيذ هذه العملية
  final double runningBalanceAfter;

  const TransactionCard({
    Key? key,
    required this.transaction,
    required this.runningBalanceAfter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          t.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat.yMMMd('ar').format(t.date)),
            if (t.notes != null && t.notes!.isNotEmpty)
              Text("ملاحظة: ${t.notes!}"),
            Text("الرصيد بعد العملية: ${runningBalanceAfter.toStringAsFixed(2)}"),
          ],
        ),
        trailing: Text(
          "${t.isIncome ? '+' : '-'}${t.amount.toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: t.isIncome ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
