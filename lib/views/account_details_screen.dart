import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/transaction_model.dart';
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
    final notifier = ref.read(appStateProvider.notifier);

    // 1) فلترة + ترتيب زمني تصاعدي
    final accountTransactions =
        appState.transactions
            .where((t) => t.folder == folderName && t.account == accountName)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    // 2) ملخص الرصيد
    final totalIncome = accountTransactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = accountTransactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final netBalance = totalIncome - totalExpense;

    // 🎨 تلوين ديناميكي
    final cs = Theme.of(context).colorScheme;
    final Color dynamicTint = netBalance >= 0 ? cs.tertiary : cs.error;

    // 3) الرصيد الجاري + تجميع حسب اليوم
    double runningBalance = 0;
    final Map<DateTime, List<_TxRow>> grouped = {};
    for (final tx in accountTransactions) {
      runningBalance += tx.isIncome ? tx.amount : -tx.amount;
      final dayKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      grouped.putIfAbsent(dayKey, () => []);
      grouped[dayKey]!.add(_TxRow(tx: tx, runningAfter: runningBalance));
    }
    final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

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
                .slideY(
                  begin: .06,
                  end: 0,
                  duration: 260.ms,
                  curve: Curves.easeOut,
                ),

            const SizedBox(height: 8),
            const SectionTitle('المعاملات'),
            const SizedBox(height: 8),

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
                      itemCount: dateKeys.length,
                      itemBuilder: (_, dayIndex) {
                        final day = dateKeys[dayIndex];
                        final rows = grouped[day]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 4,
                                end: 4,
                                bottom: 8,
                                top: 12,
                              ),
                              child:
                                  Text(
                                        _formatArabicDate(day),
                                        textAlign: TextAlign.right,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      )
                                      .animate()
                                      .fadeIn(
                                        duration: 180.ms,
                                        curve: Curves.easeOut,
                                      )
                                      .slideY(
                                        begin: .05,
                                        end: 0,
                                        duration: 180.ms,
                                        curve: Curves.easeOut,
                                      ),
                            ),

                            ...List.generate(rows.length, (i) {
                              final row = rows[i];
                              final tx = row.tx;

                              return Dismissible(
                                key: ValueKey(tx.key),
                                direction: DismissDirection.endToStart,
                                background: _buildDismissBg(context),
                                confirmDismiss: (_) async {
                                  final deletedTx = tx;
                                  await notifier.deleteTransactionByKey(
                                    tx.key as int,
                                  );

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('تم حذف المعاملة'),
                                        action: SnackBarAction(
                                          label: 'تراجع',
                                          onPressed: () {
                                            notifier.addTransaction(
                                              deletedTx,
                                            ); // addTransaction ترجع void
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                  return true;
                                },
                                child:
                                    TransactionCard(
                                          transaction: tx,
                                          runningBalanceAfter: row.runningAfter,
                                          onTap: () {
                                            // فتح التحرير بالضغط على البطاقة
                                            Navigator.of(context).push(
                                              slideFadeRoute(
                                                context: context,
                                                page: AddTransactionScreen(
                                                  initialTransaction: tx,
                                                  txKey: tx.key as int,
                                                ),
                                              ),
                                            );
                                          },
                                          showMenu: true,
                                          onEdit: () {
                                            // نفس التحرير لكن من القائمة ⋮
                                            Navigator.of(context).push(
                                              slideFadeRoute(
                                                context: context,
                                                page: AddTransactionScreen(
                                                  initialTransaction: tx,
                                                  txKey: tx.key as int,
                                                ),
                                              ),
                                            );
                                          },
                                          onDelete: () async {
                                            // تأكيد الحذف من القائمة ⋮
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                  'حذف المعاملة',
                                                ),
                                                content: const Text(
                                                  'هل أنت متأكد من حذف هذه المعاملة؟',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          false,
                                                        ),
                                                    child: const Text('إلغاء'),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          ctx,
                                                          true,
                                                        ),
                                                    child: const Text('حذف'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (ok == true) {
                                              final deletedTx = tx;
                                              await notifier
                                                  .deleteTransactionByKey(
                                                    tx.key as int,
                                                  );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: const Text(
                                                      'تم حذف المعاملة',
                                                    ),
                                                    action: SnackBarAction(
                                                      label: 'تراجع',
                                                      onPressed: () {
                                                        notifier.addTransaction(
                                                          deletedTx,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        )
                                        .animate()
                                        .fadeIn(
                                          duration: 200.ms,
                                          curve: Curves.easeOut,
                                          delay: (i * 20).ms,
                                        )
                                        .slideY(
                                          begin: .04,
                                          end: 0,
                                          duration: 200.ms,
                                          curve: Curves.easeOut,
                                        ),
                              );
                            }),
                          ],
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

  String _formatArabicDate(DateTime d) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _buildDismissBg(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.errorContainer.withOpacity(.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.delete, color: cs.onErrorContainer),
    );
  }
}

class _TxRow {
  final TransactionModel tx;
  final double runningAfter;
  _TxRow({required this.tx, required this.runningAfter});
}
