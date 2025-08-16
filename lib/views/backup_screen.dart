// lib/views/backup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backup_service.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backup = ref.read(backupServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('تصدير البيانات كـ JSON'),
              subtitle: const Text('مجلدات + معاملات (مشاركة الملف)'),
              onTap: () async {
                try {
                  final path = await backup.exportAllToTempFile();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم إنشاء الملف:\n$path'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  await backup.shareFile(path);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل التصدير: $e')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('استيراد بيانات من JSON'),
              subtitle: const Text('اختر ملف .json من جهازك'),
              onTap: () async {
                try {
                  final r = await ref
                      .read(backupServiceProvider)
                      .importFromJsonWithPicker();
                  if (!context.mounted) return;

                  if (r.cancelled) return;

                  if (r.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل الاستيراد: ${r.error}')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم الاستيراد: +${r.foldersAdded} مجلد، +${r.transactionsAdded} معاملة',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ غير متوقع: $e')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'ملاحظات:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            '• التصدير ينشئ ملف JSON مؤقت ثم يفتح المشاركة.\n'
            '• الاستيراد يدمج البيانات دون حذف الموجود.\n'
            '• لو لم يظهر منتقي الملفات/الشير شيت، راجع إعدادات أندرويد أدناه.',
          ),
        ],
      ),
    );
  }
}
