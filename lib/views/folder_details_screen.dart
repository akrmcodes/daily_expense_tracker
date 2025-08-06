// lib/views/folder_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';
import '../widgets/balances_card.dart';
import '../widgets/account_list.dart';
import 'add_account_screen.dart';
import 'account_details_screen.dart';

class FolderDetailsScreen extends ConsumerWidget {
  final String folderName;

  const FolderDetailsScreen({Key? key, required this.folderName})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1) مزود الحالة appStateProvider يعيد هنا مباشرة List<TransactionModel>
    final allTransactions = ref.watch(appStateProvider);
    // لذا لا نحتاج .transactions
    final folderTransactions = allTransactions
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddAccountScreen(folderName: folderName),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'إضافة حساب جديد',
      ),
    );
  }
}
