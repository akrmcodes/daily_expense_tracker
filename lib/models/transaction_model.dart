import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final bool isIncome;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String? notes;

  @HiveField(5)
  final String folder;

  @HiveField(6)
  final String account;

  TransactionModel({
    required this.name,
    required this.amount,
    required this.isIncome,
    required this.date,
    this.notes,
    required this.folder,
    required this.account,
  });
}
