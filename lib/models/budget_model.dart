enum BudgetPeriod { weekly, monthly, yearly }

class BudgetModel {
  final String id;
  String categoryId;
  double limit;
  BudgetPeriod period;

  BudgetModel({
    required this.id,
    required this.categoryId,
    required this.limit,
    this.period = BudgetPeriod.monthly,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'limit': limit,
        'period': period.name,
      };

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'],
        categoryId: json['categoryId'],
        limit: (json['limit'] as num).toDouble(),
        period: BudgetPeriod.values.firstWhere((e) => e.name == json['period']),
      );
}
