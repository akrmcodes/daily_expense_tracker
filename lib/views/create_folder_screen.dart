// create_folder_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_state_provider.dart';
import '../models/folder_model.dart';

class CreateFolderScreen extends ConsumerStatefulWidget {
  final int? parentFolderId;
  const CreateFolderScreen({Key? key, this.parentFolderId}) : super(key: key);
  
  @override
  ConsumerState<CreateFolderScreen> createState() => _CreateFolderScreenState();
}

class _CreateFolderScreenState extends ConsumerState<CreateFolderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _folderNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.parentFolderId == null
          ? 'إنشاء مجلد جديد'
          : 'إنشاء مجلد فرعي'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _folderNameController,
          decoration: const InputDecoration(labelText: 'اسم المجلد'),
          validator: (value) =>
              value == null || value.isEmpty ? 'مطلوب' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('إنشاء'),
        )
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final folderName = _folderNameController.text.trim();

    await ref.read(appStateProvider.notifier).addFolder(
      FolderModel(
        name: folderName,
        parentFolderId: widget.parentFolderId,
      ),
    );

    // ✅ إغلاق النافذة
    Navigator.pop(context);

    // 📢 إظهار رسالة نجاح
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ تم إنشاء المجلد بنجاح')),
    );
  }
}
