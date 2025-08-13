import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../providers/app_state_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  /// لو نمرر معاملة + مفتاحها → الشاشة تعمل كنمط "تحرير"
  final TransactionModel? initialTransaction;
  final int? txKey;

  /// في وضع الإضافة فقط: نحتاج معرفة المجلد/الحساب
  final String? folderName;
  final String? accountName;

  const AddTransactionScreen({
    Key? key,
    this.initialTransaction,
    this.txKey,
    this.folderName,
    this.accountName,
  }) : super(key: key);

  bool get isEdit => initialTransaction != null && txKey != null;

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
  void initState() {
    super.initState();
    // تهيئة الحقول لو كنا في وضع التحرير:
    final tx = widget.initialTransaction;
    if (tx != null) {
      _nameController.text = tx.name;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.notes ?? '';
      _isIncome = tx.isIncome;
      _selectedDate = tx.date;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEdit;
    final effectiveFolder = widget.initialTransaction?.folder ?? widget.folderName ?? 'Default';
    final effectiveAccount = widget.initialTransaction?.account ?? widget.accountName ?? 'Default';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل المعاملة' : 'إضافة معاملة'),
      ),
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
                    if (parsed == null || parsed <= 0) {
                      return 'أدخل رقمًا صالحًا';
                    }
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

                // اختيار التاريخ — يستخدم ثيم التطبيق تلقائيًا
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.20),
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    'التاريخ: ${DateFormat.yMMMMd('ar').format(_selectedDate)}',
                    textAlign: TextAlign.right,
                  ),
                  onTap: _pickDate,
                ),

                const SizedBox(height: 20),

                // ملاحظة بسيطة تعرض مكان الحفظ (اسم المجلد/الحساب)
                Align(
                  alignment: Alignment.centerRight,
                  child: Opacity(
                    opacity: .7,
                    child: Text(
                      'سيتم ${isEdit ? 'تحديث' : 'حفظ'} العملية في: $effectiveFolder / $effectiveAccount',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: () => _submit(effectiveFolder, effectiveAccount),
                  child: Text(isEdit ? 'حفظ التعديلات' : 'إضافة'),
                ),
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
      // لا نمرر ThemeData يدويًا — يستخدم ثيم التطبيق (فاتح/داكن) تلقائيًا
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit(String folderName, String accountName) async {
    if (!_formKey.currentState!.validate()) return;

    final model = TransactionModel(
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text),
      isIncome: _isIncome,
      date: _selectedDate,
      notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      folder: folderName,
      account: accountName,
    );

    final notifier = ref.read(appStateProvider.notifier);

    if (widget.isEdit) {
      // تحديث
      await notifier.updateTransaction(widget.txKey as int, model);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التعديلات')),
        );
      }
    } else {
      // إضافة جديدة
      notifier.addTransaction(model); // ترجع void — بدون await
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة المعاملة بنجاح')),
        );
      }
    }
  }
}
