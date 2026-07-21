import 'category_model.dart';

enum RecurrenceInterval { none, daily, weekly, monthly, yearly }

class TransactionModel {
  final String id;
  String title;
  double amount;
  CategoryType type; // income or expense
  String categoryId;
  String accountId;
  DateTime date;
  String note;
  RecurrenceInterval recurrence;
  // For transfers between accounts (optional destination account)
  String? toAccountId;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.date,
    this.note = '',
    this.recurrence = RecurrenceInterval.none,
    this.toAccountId,
  });

  bool get isTransfer => toAccountId != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'accountId': accountId,
        'date': date.toIso8601String(),
        'note': note,
        'recurrence': recurrence.name,
        'toAccountId': toAccountId,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'],
        title: json['title'],
        amount: (json['amount'] as num).toDouble(),
        type: CategoryType.values.firstWhere((e) => e.name == json['type']),
        categoryId: json['categoryId'],
        accountId: json['accountId'],
        date: DateTime.parse(json['date']),
        note: json['note'] ?? '',
        recurrence: RecurrenceInterval.values.firstWhere(
          (e) => e.name == (json['recurrence'] ?? 'none'),
          orElse: () => RecurrenceInterval.none,
        ),
        toAccountId: json['toAccountId'],
      );
}
