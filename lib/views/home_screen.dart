import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/app_state_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/transitions.dart';
import '../widgets/balance_card.dart';

import '../widgets/app/section_title.dart';
import '../widgets/app/glass_panel_card.dart';
import '../widgets/folder_tile.dart';
import 'create_folder_screen.dart';
import 'folder_details_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    // مجلدات المستوى الأعلى فقط
    final folders = appState.folders.where((f) => f.parentFolderId == null).toList();
    final transactions = appState.transactions;

    final totalIncome = transactions.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
    final netBalance = totalIncome - totalExpense;

    // تلوين ديناميكي للزجاج حسب الرصيد
    final cs = Theme.of(context).colorScheme;
    final Color dynamicTint = netBalance >= 0 ? cs.tertiary : cs.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'تبديل الثيم',
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              final notifier = ref.read(themeModeProvider.notifier);
              notifier.state =
                  notifier.state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // GlassPanelCard + BalanceCard
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    blurRadius: 24,
                    offset: Offset(0, 12),
                    color: Colors.black26,
                  ),
                ],
              ),
              child: GlassPanelCard(
                tintColor: dynamicTint,
                opacity: 0.16,
                blurSigma: 14,
                borderOpacity: 0.12,
                highlightOpacity: 0.07,
                child: BalanceCard(
                  income: totalIncome,
                  expense: totalExpense,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                .slideY(begin: .06, end: 0, duration: 260.ms, curve: Curves.easeOut),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: SectionTitle('المجلدات'),
          ),

          // قائمة المجلدات مع FolderTile + micro-animations + قائمة خيارات
          Expanded(
            child: ListView.builder(
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];

                // رصيد المجلد
                final folderBalance = transactions
                    .where((t) => t.folder == folder.name)
                    .fold<double>(0.0, (sum, t) => sum + (t.isIncome ? t.amount : -t.amount));

                return FolderTile(
                  title: folder.name,
                  balance: folderBalance,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'rename') {
                        final newName = await _promptRename(context, folder.name);
                        if (newName != null &&
                            newName.trim().isNotEmpty &&
                            newName != folder.name) {
                          await ref
                              .read(appStateProvider.notifier)
                              .renameFolder(folder.key as int, newName.trim());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تمت إعادة التسمية')),
                          );
                        }
                      } else if (value == 'delete') {
                        final confirm = await _confirm(
                          context,
                          'حذف المجلد',
                          'سيتم الحذف إذا كان المجلد فارغًا. هل تريد المتابعة؟',
                        );
                        if (confirm == true) {
                          final ok = await ref
                              .read(appStateProvider.notifier)
                              .deleteFolderIfEmpty(folder.key as int);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok ? 'تم الحذف' : 'تعذّر الحذف: المجلد غير فارغ',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('إعادة تسمية')),
                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      slideFadeRoute(
                        context: context,
                        page: FolderDetailsScreen(folderId: folder.key as int),
                      ),
                    );
                  },
                )
                    .animate()
                    .fadeIn(
                      duration: 220.ms,
                      curve: Curves.easeOut,
                      delay: (index * 30).ms,
                    )
                    .slideY(begin: .06, end: 0, duration: 220.ms, curve: Curves.easeOut);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateFolderScreen(),
          );
        },
        child: const Icon(Icons.create_new_folder),
      ),
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
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد')),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
}
