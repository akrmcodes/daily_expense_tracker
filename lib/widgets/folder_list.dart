import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../views/folder_details_screen.dart';

class FolderList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final void Function(String folderName)? onFolderTap;

  const FolderList({Key? key, required this.transactions, this.onFolderTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final folders = transactions.map((t) => t.folder).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "المجلدات",
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 10),
        ...folders.map((folder) {
          final folderTransactions = transactions
              .where((t) => t.folder == folder)
              .toList();
          final folderBalance = folderTransactions.fold<double>(
            0.0,
            (sum, t) => sum + (t.isIncome ? t.amount : -t.amount),
          );

          return Card(
            color: Colors.grey[900],
            child: ListTile(
              title: Text(
                folder,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text("الرصيد: ${folderBalance.toStringAsFixed(2)}"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FolderDetailsScreen(
                      folderName: folder,
                      allTransactions: transactions,
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ],
    );
  }
}
