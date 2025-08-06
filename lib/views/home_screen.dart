import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';
import '../widgets/balances_card.dart';
import '../widgets/folder_list.dart';
import 'add_transaction_screen.dart';
import 'folder_details_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(appStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الرئيسية'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BalanceCard(transactions: transactions),
            const SizedBox(height: 16),
            FolderList(transactions: transactions),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFolderDialog(context, ref),
        child: const Icon(Icons.create_new_folder),
      ),
    );
  }

  void _showFolderDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اسم المجلد الجديد'),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(hintText: 'أدخل الاسم'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FolderDetailsScreen(folderName: name),
                  ),
                );
              }
            },
            child: const Text('إنشاء'),
          )
        ],
      ),
    );
  }
}