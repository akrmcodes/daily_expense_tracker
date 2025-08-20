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
          // --- تصدير إلى التنزيلات ---
          Card(
            child: ListTile(
              leading: const Icon(Icons.download),
              title: const Text('تصدير إلى مجلد التنزيلات'),
              subtitle: const Text(
                'سيُحفظ في Downloads/DailyExpenseTracker ويمكن مشاركته',
              ),
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
                          onPressed: () =>
                              Clipboard.setData(ClipboardData(text: file.path)),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('فشل التصدير: $e')));
                  }
                }
              },
            ),
          ),

          const SizedBox(height: 12),

          // --- احفظ في مكان آخر ---
          Card(
            child: ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('احفظ في مكان آخر…'),
              subtitle: const Text('اختر مجلدًا واسم الملف يدويًا'),
              onTap: () async {
                try {
                  final file = await backup.exportWithPicker();
                  if (file == null) return;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 5),
                        content: Text('تم الحفظ:\n${file.path}'),
                        action: SnackBarAction(
                          label: 'نسخ المسار',
                          onPressed: () =>
                              Clipboard.setData(ClipboardData(text: file.path)),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
                  }
                }
              },
            ),
          ),

          const SizedBox(height: 24),

          // --- استيراد ---
          Card(
            child: ListTile(
              leading: const Icon(Icons.file_open),
              title: const Text('استيراد من ملف'),
              subtitle: const Text('اختر: استبدال كلي أو دمج بدون حذف'),
              onTap: () async {
                final mode = await showModalBottomSheet<String>(
                  context: context,
                  builder: (sheetCtx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.warning_amber),
                          title: const Text('استبدال كلي'),
                          subtitle: const Text(
                            'سيتم حذف البيانات الحالية واستيراد ما في الملف',
                          ),
                          onTap: () => Navigator.pop(sheetCtx, 'replace'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.merge_type),
                          title: const Text('دمج بدون حذف'),
                          subtitle: const Text(
                            'إضافة العناصر الناقصة فقط وتجنب التكرارات',
                          ),
                          onTap: () => Navigator.pop(sheetCtx, 'merge'),
                        ),
                      ],
                    ),
                  ),
                );
                if (mode == null) return;

                try {
                  await ref
                      .read(backupServiceProvider)
                      .importFromPicker(context, merge: mode == 'merge');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ أثناء الاستيراد: $e')),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
