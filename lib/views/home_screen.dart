import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/folder_model.dart';
import '../providers/app_state_provider.dart';
import 'create_folder_screen.dart';
import 'folder_details_screen.dart';

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

    double totalIncome = transactions
        .where((t) => t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);
    double totalExpense = transactions
        .where((t) => !t.isIncome)
        .fold(0, (sum, t) => sum + t.amount);
    double netBalance = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(title: const Text('الرئيسية'), centerTitle: true),
      body: Column(
        children: [
          // ✅ بطاقة الرصيد بلون متوافق مع الوضع الليلي
          Card(
            margin: const EdgeInsets.all(12),
            color: const Color(0xFF1E1E2C), // لون داكن
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الإيرادات: +${totalIncome.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                  Text(
                    'المصروفات: -${totalExpense.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const Divider(color: Colors.grey),
                  Text(
                    'الرصيد الصافي: ${netBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ✅ قائمة المجلدات
          Expanded(
            child: ListView.builder(
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                return ListTile(
                  leading: const Icon(Icons.folder, color: Colors.white),
                  title: Text(
                    folder.name,
                    style: const TextStyle(color: Colors.white),
                  ),
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
