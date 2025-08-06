import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';
import '../widgets/balances_card.dart';
import '../widgets/folder_list.dart';
import '../views/folder_details_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(appStateProvider);
    final folders = ref.read(appStateProvider.notifier).getFolders();

    return Scaffold(
      appBar: AppBar(title: const Text('متتبع المصاريف'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BalanceCard(transactions: transactions),
            const SizedBox(height: 20),
            FolderList(transactions: transactions),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFolderDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context, WidgetRef ref) {
    final folderController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('أدخل اسم المجلد الجديد'),
          content: TextField(
            controller: folderController,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(hintText: 'اسم المجلد'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final folderName = folderController.text.trim();
                if (folderName.isEmpty) return;
                Navigator.of(ctx).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => FolderDetailsScreen(folderName: folderName),
                ));
              },
              child: const Text('متابعة'),
            )
          ],
        );
      },
    );
  }
}
