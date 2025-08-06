import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/app_state_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String folderName;
  const AddTransactionScreen({Key? key, required this.folderName}) : super(key: key);

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isIncome = true;
  
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة معاملة'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: 'اسم المعاملة'),
                validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(labelText: 'المبلغ'),
                validator: (value) => value == null || double.tryParse(value) == null
                    ? 'أدخل مبلغًا صحيحًا'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                textAlign: TextAlign.right,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: const Text('دخل'),
                      value: true,
                      groupValue: _isIncome,
                      onChanged: (val) => setState(() => _isIncome = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: const Text('مصروف'),
                      value: false,
                      groupValue: _isIncome,
                      onChanged: (val) => setState(() => _isIncome = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  'التاريخ: ${DateFormat.yMMMMd('ar').format(_selectedDate)}',
                  textAlign: TextAlign.right,
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('إضافة'),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final transaction = TransactionModel(
      name: _nameController.text,
      amount: double.parse(_amountController.text),
      isIncome: _isIncome,
      date: _selectedDate,
      notes: _noteController.text.isEmpty ? null : _noteController.text,
      folder: widget.folderName,
      account: 'افتراضي',
    );

    ref.read(appStateProvider.notifier).addTransaction(transaction);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إضافة المعاملة')),
    );
    Navigator.of(context).pop();
  }
  

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
    );

    if (picked != null) setState(() => _selectedDate = picked);
  }
}
