import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import 'package:hive/hive.dart';

class AddTransactionScreen extends StatefulWidget {
  final List<TransactionModel> allTransactions;

  const AddTransactionScreen({Key? key, required this.allTransactions})
      : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedFolder;
  String? _selectedAccount;
  bool _isIncome = true;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final folders = widget.allTransactions
        .map((t) => t.folder)
        .toSet()
        .toList();

    final accounts = widget.allTransactions
        .where((t) => t.folder == _selectedFolder)
        .map((t) => t.account)
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة معاملة'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                label: 'اسم المعاملة',
                controller: _nameController,
                validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'المبلغ',
                controller: _amountController,
                keyboardType: TextInputType.number,
                validator: (val) => val == null || double.tryParse(val) == null
                    ? 'أدخل مبلغًا صحيحًا'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'المجلد',
                value: _selectedFolder,
                items: folders,
                onChanged: (val) {
                  setState(() {
                    _selectedFolder = val;
                    _selectedAccount = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'الحساب',
                value: _selectedAccount,
                items: accounts,
                onChanged: (val) => setState(() => _selectedAccount = val),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('دخل'),
                      value: true,
                      groupValue: _isIncome,
                      onChanged: (val) => setState(() => _isIncome = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.grey[900],
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  'التاريخ: ${DateFormat.yMMMMd('ar').format(_selectedDate)}',
                  textAlign: TextAlign.right,
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'ملاحظات (اختياري)',
                controller: _noteController,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('إضافة المعاملة'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.greenAccent[400],
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textAlign: TextAlign.right,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[900],
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      alignment: Alignment.centerRight,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[900],
      ),
      dropdownColor: Colors.grey[900],
      iconEnabledColor: Colors.white,
      style: const TextStyle(color: Colors.white),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, textAlign: TextAlign.right),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

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

  void _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedFolder == null || _selectedAccount == null) return;

    final transaction = TransactionModel(
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text),
      isIncome: _isIncome,
      date: _selectedDate,
      notes: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      folder: _selectedFolder!,
      account: _selectedAccount!,
    );

    final box = Hive.box<TransactionModel>('transactions');
    await box.add(transaction);

    Navigator.of(context).pop(); // رجوع بعد الإضافة
  }
}
