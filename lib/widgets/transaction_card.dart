import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  /// الرصيد بعد تنفيذ هذه العملية
  final double runningBalanceAfter;

  /// ← جديد: نجعل البطاقة تقبل onTap من الخارج
  final VoidCallback? onTap;

  const TransactionCard({
    Key? key,
    required this.transaction,
    required this.runningBalanceAfter,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final cs = Theme.of(context).colorScheme;
    final bool income = t.isIncome;

    // ألوان ديناميكية حسب النوع مع شفافية بسيطة
    final Color accent = income ? Colors.green : Colors.red;
    final Color chipBg = accent.withOpacity(0.10);
    final Color tileTint = (income ? cs.tertiary : cs.error).withOpacity(0.08);
    final Color divider = cs.outlineVariant.withOpacity(0.45);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap, // ← نستخدم الكولباك القادم من الخارج
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            // Tint خفيف يحافظ على قابلية القراءة في الفاتح والداكن
            color: Color.alphaBlend(tileTint, cs.surface),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // أيقونة النوع
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  income ? Icons.south_west : Icons.north_east,
                  color: accent,
                ),
              ),

              const SizedBox(width: 12),

              // نصوص: الاسم + التاريخ + الملاحظة + الرصيد بعد العملية
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الاسم + التاريخ في سطر واحد عند الإمكان
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat.yMMMd('ar').format(t.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    if (t.notes != null && t.notes!.isNotEmpty) ...[
                      Text(
                        t.notes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // خط فاصل رفيع
                    Container(height: 1, color: divider),

                    const SizedBox(height: 6),

                    // الرصيد بعد العملية
                    Text(
                      "الرصيد بعد العملية: ${runningBalanceAfter.toStringAsFixed(2)}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // مبلغ العملية كبادج صغير
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withOpacity(0.35)),
                ),
                child: Text(
                  "${income ? '+' : '-'}${t.amount.toStringAsFixed(2)}",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
