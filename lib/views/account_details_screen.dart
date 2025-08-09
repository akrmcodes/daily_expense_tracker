import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../providers/app_state_provider.dart';
import '../widgets/transaction_card.dart';
import '../widgets/balance_card.dart';
import '../widgets/app/glass_panel_card.dart';
import '../widgets/app/section_title.dart';
import '../utils/transitions.dart';
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

    // تلوين ديناميكي لزجاج البطاقة حسب الرصيد
    final cs = Theme.of(context).colorScheme;
    final Color dynamicTint = netBalance >= 0 ? cs.tertiary : cs.error;

    double runningBalance = 0;

    return Scaffold(
      appBar: AppBar(title: Text('تفاصيل $accountName')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Glass + Balance
            GlassPanelCard(
              tintColor: dynamicTint,
              opacity: 0.16,
              blurSigma: 14,
              borderOpacity: 0.12,
              highlightOpacity: 0.07,
              child: BalanceCard(
                income: totalIncome,
                expense: totalExpense,
              ),
            )
                .animate()
                .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                .slideY(begin: .06, end: 0, duration: 260.ms, curve: Curves.easeOut),

            const SizedBox(height: 8),
            const SectionTitle('المعاملات'),
            const SizedBox(height: 8),

            // قائمة العمليات
            Expanded(
              child: accountTransactions.isEmpty
                  ? Center(
                      child: Opacity(
                        opacity: 0.7,
                        child: Text(
                          'لا توجد معاملات بعد',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: accountTransactions.length,
                      itemBuilder: (_, i) {
                        final t = accountTransactions[i];
                        final nextBalance =
                            runningBalance + (t.isIncome ? t.amount : -t.amount);

                        final tile = TransactionCard(
                          transaction: t,
                          runningBalanceAfter: nextBalance,
                        );

                        runningBalance = nextBalance;

                        // micro-animations لكل عنصر
                        return tile
                            .animate()
                            .fadeIn(duration: 220.ms, curve: Curves.easeOut, delay: (i * 24).ms)
                            .slideY(begin: .05, end: 0, duration: 220.ms, curve: Curves.easeOut);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            slideFadeRoute(
              context: context,
              page: AddTransactionScreen(
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
