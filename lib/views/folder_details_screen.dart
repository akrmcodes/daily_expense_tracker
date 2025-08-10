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
                // (اختياري) رصيد المجلد الفرعي:
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
