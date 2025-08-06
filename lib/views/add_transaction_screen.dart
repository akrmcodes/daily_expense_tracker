import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/app_state_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? folderName;
  final String? accountName;

  const AddTransactionScreen({Key? key, this.folderName, this.accountName}) : super(key: key);

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isIncome = true;
  DateTime _selectedDate = DateTime.now(); // ← تأكد إنه هنا

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة معاملة')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ... حقول الاسم والمبلغ والملاحظات ...
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      value: true,
                      groupValue: _isIncome,
                      title: const Text('دخل'),
                      onChanged: (val) => setState(() => _isIncome = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      value: false,
                      groupValue: _isIncome,
                      title: const Text('مصروف'),
                      onChanged: (val) => setState(() => _isIncome = val!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              // ← هنا تضيف هذا الكود لعرض التاريخ واختيار التاريخ
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.grey[900],
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  'التاريخ: ${DateFormat.yMMMMd('ar').format(_selectedDate)}',
                  textAlign: TextAlign.right,
                ),
                onTap: _pickDate,
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('إضافة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ← وهذه الدالة تحت الـ build مباشرة
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
      builder: (context, child) => Theme(
        data: ThemeData.dark(),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final transaction = TransactionModel(
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text),
      isIncome: _isIncome,
      date: _selectedDate,
      notes: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      folder: widget.folderName ?? 'Default',
      account: widget.accountName ?? 'Default',
    );

    ref.read(appStateProvider.notifier).addTransaction(transaction);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إضافة المعاملة بنجاح')),
    );
  }
}