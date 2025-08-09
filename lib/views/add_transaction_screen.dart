import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/app_state_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? folderName;
  final String? accountName;

  const AddTransactionScreen({Key? key, this.folderName, this.accountName})
    : super(key: key);

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة معاملة')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم المعاملة'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'مطلوب';
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0)
                      return 'أدخل رقمًا صالحًا';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظة (اختياري)',
                  ),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 12),

                // ✅ استخدم Card تتبع الثيم بدل لون أسود ثابت
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      'التاريخ: ${DateFormat.yMMMMd('ar').format(_selectedDate)}',
                      textAlign: TextAlign.right,
                    ),
                    onTap: _pickDate,
                  ),
                ),

                const SizedBox(height: 20),
                ElevatedButton(onPressed: _submit, child: const Text('إضافة')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('ar'),
      // مافيش builder — الحوارات هتورّث الثيم (فاتح/داكن) تلقائيًا
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تمت إضافة المعاملة بنجاح')));
  }
}
