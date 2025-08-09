import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transaction_model.dart';

class BalanceCard extends StatelessWidget {
  final List<TransactionModel>? transactions;
  final double? income;
  final double? expense;

  const BalanceCard({
    super.key,
    this.transactions,
    this.income,
    this.expense,
  }) : assert(
          (transactions != null) || (income != null && expense != null),
          'Pass either transactions OR income & expense',
        );

  @override
  Widget build(BuildContext context) {
    double totalIncome = income ?? 0;
    double totalExpense = expense ?? 0;

    if (transactions != null) {
      totalIncome = transactions!
          .where((t) => t.isIncome)
          .fold(0.0, (s, t) => s + t.amount);
      totalExpense = transactions!
          .where((t) => !t.isIncome)
          .fold(0.0, (s, t) => s + t.amount);
    }

    final net = totalIncome - totalExpense;

    final card = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle.merge(
          style: Theme.of(context).textTheme.bodyLarge!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('الإيرادات', totalIncome, Colors.green),
              const SizedBox(height: 8),
              _row('المصروفات', totalExpense, Colors.red),
              const Divider(),
              _row('الرصيد الصافي', net, net >= 0 ? Colors.green : Colors.red, bold: true),
            ],
          ),
        ),
      ),
    );

    // micro-interaction بسيطة
    return card
        .animate()
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideY(begin: .08, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _row(String label, double value, Color color, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
