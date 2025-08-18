// lib/views/backup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/backup_service.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backup = ref.read(backupServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي والاستيراد')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('تصدير إلى Downloads'),
            subtitle: const Text('سيتم إنشاء ملف داخل Downloads/DailyExpenseTracker'),
            trailing: const Icon(Icons.file_download),
            onTap: () async {
              try {
                final file = await backup.exportToDownloads(shareAfter: true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 5),
                      content: Text('تم إنشاء الملف:\n${file.path}'),
                      action: SnackBarAction(
                        label: 'نسخ المسار',
                        onPressed: () => Clipboard.setData(ClipboardData(text: file.path)),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل التصدير: $e')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('استيراد من ملف'),
            subtitle: const Text('اختر ملف .detb أو .json'),
            trailing: const Icon(Icons.file_open),
            onTap: () async {
              try {
                await backup.importFromPicker(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ أثناء الاستيراد: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
