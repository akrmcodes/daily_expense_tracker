import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class BalanceCard extends StatelessWidget {
  final List<TransactionModel> transactions;

  const BalanceCard({
    Key? key,
    required this.transactions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double totalIncome = transactions
        .where((t) => t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);

    final double totalExpense = transactions
        .where((t) => !t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);

    final double balance = totalIncome - totalExpense;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1E1E2C),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRow(
              context,
              label: 'الإيرادات',
              amount: totalIncome,
              color: Colors.greenAccent,
              icon: Icons.arrow_downward,
            ),
            const SizedBox(height: 12),
            _buildRow(
              context,
              label: 'المصروفات',
              amount: totalExpense,
              color: Colors.redAccent,
              icon: Icons.arrow_upward,
            ),
            const Divider(height: 32, color: Colors.grey),
            _buildRow(
              context,
              label: 'الرصيد المتبقي',
              amount: balance,
              color: balance >= 0 ? Colors.greenAccent : Colors.redAccent,
              icon: Icons.account_balance_wallet,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
            textAlign: TextAlign.right,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ],
    );
  }
}
