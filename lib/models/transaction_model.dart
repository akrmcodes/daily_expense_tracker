import 'package:hive/hive.dart';
part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double amount;

  @HiveField(2)
  bool isIncome;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? notes;

  @HiveField(5)
  String folder;

  @HiveField(6)
  String account;

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