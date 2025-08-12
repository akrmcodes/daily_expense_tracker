import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction_model.dart';
import '../providers/app_state_provider.dart';

class AccountList extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // أسماء الحسابات (فريدة) داخل هذا المجلد
    final accounts =
        transactions
            .where((t) => t.folder == folderName && t.account.isNotEmpty)
            .map((t) => t.account)
            .toSet()
            .toList()
          ..sort();

    final notifier = ref.read(appStateProvider.notifier);

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
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'rename') {
                  final newName = await _promptRename(context, accountName);
                  if (newName != null &&
                      newName.trim().isNotEmpty &&
                      newName != accountName) {
                    await notifier.renameAccount(
                      folderName,
                      accountName,
                      newName.trim(),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تمت إعادة تسمية الحساب')),
                      );
                    }
                  }
                } else if (value == 'delete') {
                  // أولًا: جرّب نحذف لو كان الحساب فارغ
                  final isEmpty = !transactions.any(
                    (t) =>
                        t.folder == folderName &&
                        t.account == accountName &&
                        // نتأكد أن ليست dummy فقط (لكن حتى لو في dummy قديمة دالة deleteAccountIfEmpty بتنظفها)
                        t.amount != 0,
                  );

                  if (isEmpty) {
                    final confirmed = await _confirm(
                      context,
                      'حذف الحساب',
                      'سيتم حذف الحساب لا يحتوي على معاملات. هل تريد المتابعة؟',
                    );
                    if (confirmed == true) {
                      final ok = await notifier.deleteAccountIfEmpty(
                        folderName,
                        accountName,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'تم الحذف (الحساب كان فارغًا)'
                                  : 'تعذّر الحذف',
                            ),
                          ),
                        );
                      }
                    }
                  } else {
                    // الحساب غير فارغ → اسأل عن الحذف الشامل
                    final cascade = await _confirm(
                      context,
                      'الحذف الشامل',
                      'هذا الحساب يحتوي على معاملات.\nهل تريد حذف الحساب وكل معاملاته؟',
                    );
                    if (cascade == true) {
                      await notifier.deleteAccountCascade(
                        folderName,
                        accountName,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم حذف الحساب وكل معاملاته'),
                          ),
                        );
                      }
                    }
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('إعادة تسمية')),
                PopupMenuItem(value: 'delete', child: Text('حذف')),
              ],
            ),
            onTap: () => onAccountTap(accountName),
          ),
        );
      }).toList(),
    );
  }
}

// ===== Helpers =====

Future<bool?> _confirm(BuildContext context, String title, String message) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('تأكيد'),
        ),
      ],
    ),
  );
}

Future<String?> _promptRename(BuildContext context, String currentName) {
  final controller = TextEditingController(text: currentName);
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('إعادة تسمية الحساب'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'الاسم الجديد'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
}
