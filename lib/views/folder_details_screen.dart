import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';
import '../widgets/balances_card.dart';
import '../widgets/account_list.dart';
import 'add_account_screen.dart';
import 'account_details_screen.dart';
import 'create_folder_screen.dart';

class FolderDetailsScreen extends ConsumerWidget {
  final int folderId;

  const FolderDetailsScreen({Key? key, required this.folderId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    final folder = appState.folders.firstWhere((f) => f.key == folderId);
    final folderName = folder.name;

    final folderTransactions = appState.transactions
        .where((t) => t.folder == folderName)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(folderName), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BalanceCard(transactions: folderTransactions),
            const SizedBox(height: 24),
            Text(
              'الحسابات في هذا المجلد',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            AccountList(
              transactions: folderTransactions,
              folderName: folderName,
              onAccountTap: (accountName) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AccountDetailsScreen(
                      folderName: folderName,
                      accountName: accountName,
                    ),
                  ),
                );
              },
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
                        MaterialPageRoute(
                          builder: (_) => AddAccountScreen(folderName: folderName),
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
                        builder: (_) => CreateFolderScreen(parentFolderId: folderId),
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
