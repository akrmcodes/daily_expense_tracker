import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transaction_model.dart';

/// BalanceCard مرنة:
/// - مرر transactions (ويحسب القيم داخليًا)
/// - أو مرر income + expense مباشرة
class BalanceCard extends StatelessWidget {
  final List<TransactionModel>? transactions;
  final double? income;
  final double? expense;

  const BalanceCard({super.key, this.transactions, this.income, this.expense})
    : assert(
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
    final netColor = net >= 0 ? Colors.green : Colors.red;

    return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.bodyLarge!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AmountRow(
                    label: 'الإيرادات',
                    value: totalIncome,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _AmountRow(
                    label: 'المصروفات',
                    value: totalExpense,
                    color: Colors.red,
                  ),
                  const Divider(),
                  _AmountRow(
                    label: 'الرصيد الصافي',
                    value: net,
                    color: netColor,
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
        )
        // دخول لطيف للبطاقة نفسها (لمسة خفيفة)
        .animate()
        .fadeIn(duration: 220.ms, curve: Curves.easeOut)
        .slideY(begin: .04, end: 0, duration: 220.ms, curve: Curves.easeOut);
  }
}

/// صف يحتوي على (عنوان + رقم) مع AnimatedSwitcher للرقم
class _AmountRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool bold;

  const _AmountRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    );

    return Row(
      children: [
        Expanded(
          child: Text(label, textAlign: TextAlign.right, style: textStyle),
        ),
        // الرقم مع AnimatedSwitcher + Slide/Fade عند تغير القيمة
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (child, anim) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, .15),
                end: Offset.zero,
              ).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            );
          },
          child: Text(
            value.toStringAsFixed(2),
            key: ValueKey<String>(
              value.toStringAsFixed(2),
            ), // مهم للتمييز بين القيم
            style: textStyle.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
