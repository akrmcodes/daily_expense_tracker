import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/app_state_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/account_list.dart';
import '../widgets/app/glass_panel_card.dart';
import '../widgets/app/section_title.dart';
import '../utils/transitions.dart';
import 'add_account_screen.dart';
import 'account_details_screen.dart';
import 'create_folder_screen.dart';
import '../widgets/folder_tile.dart';

class FolderDetailsScreen extends ConsumerWidget {
  final int folderId;

  const FolderDetailsScreen({Key? key, required this.folderId})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    // المجلد الحالي
    final folder = appState.folders.firstWhere((f) => f.key == folderId);
    final folderName = folder.name;

    // معاملات هذا المجلد
    final folderTransactions = appState.transactions
        .where((t) => t.folder == folderName)
        .toList();

    // المجلدات الفرعية
    final subFolders = appState.folders
        .where((f) => f.parentFolderId == folderId)
        .toList();

    // تلوين ديناميكي للزجاج حسب صافي رصيد المجلد
    final totalIncome = folderTransactions
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = folderTransactions
        .where((t) => !t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final net = totalIncome - totalExpense;
    final cs = Theme.of(context).colorScheme;
    final Color dynamicTint = net >= 0 ? cs.tertiary : cs.error;

    return Scaffold(
      appBar: AppBar(title: Text(folderName), centerTitle: true),
      body: SingleChildScrollView(
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

            const SizedBox(height: 12),

            // المجلدات الفرعية (إن وجدت)
            if (subFolders.isNotEmpty) ...[
              const SectionTitle('المجلدات الفرعية'),
              const SizedBox(height: 8),
              ...List.generate(subFolders.length, (i) {
                final sub = subFolders[i];

                // (اختياري) رصيد المجلد الفرعي
                final subFolderBalance = appState.transactions
                    .where((t) => t.folder == sub.name)
                    .fold<double>(
                      0.0,
                      (s, t) => s + (t.isIncome ? t.amount : -t.amount),
                    );

                return FolderTile(
                      title: sub.name,
                      balance: subFolderBalance,
                      isSubfolder: true,
                      // ✅ قائمة ⋮ للمجلد الفرعي
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'rename') {
                            final newName = await _promptRename(
                              context,
                              sub.name,
                            );
                            if (newName != null &&
                                newName.trim().isNotEmpty &&
                                newName != sub.name) {
                              await notifier.renameFolder(
                                sub.key as int,
                                newName.trim(),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تمت إعادة التسمية'),
                                ),
                              );
                            }
                          } else if (value == 'delete') {
                            // جرّب الحذف الآمن أولًا
                            final ok = await notifier.deleteFolderIfEmpty(
                              sub.key as int,
                            );
                            if (ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم حذف المجلد')),
                              );
                            } else {
                              // غير فارغ → اسأل عن الحذف الشامل
                              final cascade = await _confirm(
                                context,
                                'الحذف الشامل',
                                'هذا المجلد يحتوي على مجلدات فرعية أو معاملات.\nهل تريد حذف كل المحتويات؟',
                              );
                              if (cascade == true) {
                                await notifier.deleteFolderCascade(
                                  sub.key as int,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم الحذف الشامل'),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'rename',
                            child: Text('إعادة تسمية'),
                          ),
                          PopupMenuItem(value: 'delete', child: Text('حذف')),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          slideFadeRoute(
                            context: context,
                            page: FolderDetailsScreen(folderId: sub.key as int),
                          ),
                        );
                      },
                    )
                    .animate()
                    .fadeIn(
                      duration: 220.ms,
                      curve: Curves.easeOut,
                      delay: (i * 24).ms,
                    )
                    .slideY(
                      begin: .05,
                      end: 0,
                      duration: 220.ms,
                      curve: Curves.easeOut,
                    );
              }),
              const SizedBox(height: 16),
            ],

            const SectionTitle('الحسابات في هذا المجلد'),
            const SizedBox(height: 8),

            // قائمة الحسابات
            AccountList(
                  transactions: folderTransactions,
                  folderName: folderName,
                  onAccountTap: (accountName) {
                    Navigator.of(context).push(
                      slideFadeRoute(
                        context: context,
                        page: AccountDetailsScreen(
                          folderName: folderName,
                          accountName: accountName,
                        ),
                      ),
                    );
                  },
                )
                .animate()
                .fadeIn(duration: 220.ms, curve: Curves.easeOut)
                .slideY(
                  begin: .04,
                  end: 0,
                  duration: 220.ms,
                  curve: Curves.easeOut,
                ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                runSpacing: 16,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_add),
                    title: const Text('إضافة حساب'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        slideFadeRoute(
                          context: context,
                          page: AddAccountScreen(folderName: folderName),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.create_new_folder),
                    title: const Text('إنشاء مجلد فرعي'),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) =>
                            CreateFolderScreen(parentFolderId: folderId),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'إضافة',
      ),
    );
  }
}

// ===== Helpers (نفس أسلوب HomeScreen) =====

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
      title: const Text('إعادة تسمية المجلد'),
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
