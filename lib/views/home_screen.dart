import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';
import 'create_folder_screen.dart';
import 'folder_details_screen.dart';
import '../providers/theme_provider.dart';
import '../widgets/balance_card.dart';

// إضافات الواجهة الجديدة:
import '../widgets/app/panel_card.dart';
import '../widgets/app/section_title.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    // مجلدات المستوى الأعلى فقط
    final folders = appState.folders
        .where((f) => f.parentFolderId == null)
        .toList();
    final transactions = appState.transactions;

    final totalIncome = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final netBalance = totalIncome - totalExpense;

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
              notifier.state = notifier.state == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ✅ PanelCard من نظام التصميم
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: BalanceCard(income: totalIncome, expense: totalExpense),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: SectionTitle('المجلدات'),
          ),

          // ✅ قائمة المجلدات
          Expanded(
            child: ListView.builder(
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                return ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(folder.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FolderDetailsScreen(folderId: folder.key as int),
                      ),
                    );
                  },
                );
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
