import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  /// الرصيد بعد تنفيذ هذه العملية
  final double runningBalanceAfter;

  /// يفتح شاشة التفاصيل/التحرير عند الضغط على البطاقة
  final VoidCallback? onTap;

  /// إظهار زر القائمة ⋮ من عدمه
  final bool showMenu;

  /// استدعاءات القائمة
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionCard({
    Key? key,
    required this.transaction,
    required this.runningBalanceAfter,
    this.onTap,
    this.showMenu = false,
    this.onEdit,
    this.onDelete,
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
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Color.alphaBlend(tileTint, cs.surface),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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

              // النصوص (اسم + تاريخ + ملاحظة + رصيد)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الاسم (سطرين كحد أقصى) + Tooltip يظهر الاسم كامل بالضغط المطوّل
                    Tooltip(
                      message: t.name,
                      preferBelow: false,
                      child: Text(
                        t.name,
                        maxLines: 2,           // ← بدلاً من 1
                        softWrap: true,        // ← يسمح بالالتفاف
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // التاريخ تحت الاسم بخط صغير
                    Text(
                      DateFormat.yMMMd('ar').format(t.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
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

              // مبلغ العملية + قائمة ⋮ اختيارية
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      if (showMenu) ...[
                        const SizedBox(width: 4),
                        PopupMenuButton<_TxMenuAction>(
                          tooltip: 'خيارات',
                          onSelected: (value) {
                            switch (value) {
                              case _TxMenuAction.edit:
                                if (onEdit != null) onEdit!();
                                break;
                              case _TxMenuAction.delete:
                                if (onDelete != null) onDelete!();
                                break;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _TxMenuAction.edit,
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('تعديل'),
                              ),
                            ),
                            PopupMenuItem(
                              value: _TxMenuAction.delete,
                              child: ListTile(
                                leading: Icon(Icons.delete_outline),
                                title: Text('حذف'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TxMenuAction { edit, delete }
