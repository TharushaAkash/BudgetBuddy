import 'package:flutter/material.dart';

enum CategoryType { income, expense }

/// Maps a stable string key to an IconData so categories can be persisted
/// as JSON (IconData objects themselves are not directly serializable).
const Map<String, IconData> kCategoryIcons = {
  'food': Icons.restaurant,
  'groceries': Icons.local_grocery_store,
  'transport': Icons.directions_car,
  'shopping': Icons.shopping_bag,
  'entertainment': Icons.movie,
  'bills': Icons.receipt_long,
  'health': Icons.local_hospital,
  'education': Icons.school,
  'travel': Icons.flight,
  'home': Icons.home,
  'gift': Icons.card_giftcard,
  'salary': Icons.attach_money,
  'business': Icons.business_center,
  'investment': Icons.trending_up,
  'freelance': Icons.laptop_mac,
  'rental': Icons.apartment,
  'other_income': Icons.savings,
  'other_expense': Icons.more_horiz,
  'pets': Icons.pets,
  'fitness': Icons.fitness_center,
  'subscription': Icons.subscriptions,
  'insurance': Icons.shield,
};

class CategoryModel {
  final String id;
  String name;
  String iconKey;
  int colorValue;
  CategoryType type;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.type,
  });

  IconData get icon => kCategoryIcons[iconKey] ?? Icons.category;
  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'colorValue': colorValue,
        'type': type.name,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'],
        name: json['name'],
        iconKey: json['iconKey'],
        colorValue: json['colorValue'],
        type: CategoryType.values.firstWhere((e) => e.name == json['type']),
      );

  static List<CategoryModel> defaults() {
    return [
      CategoryModel(id: 'c1', name: 'Food & Dining', iconKey: 'food', colorValue: 0xFFEF6C00, type: CategoryType.expense),
      CategoryModel(id: 'c2', name: 'Groceries', iconKey: 'groceries', colorValue: 0xFF43A047, type: CategoryType.expense),
      CategoryModel(id: 'c3', name: 'Transport', iconKey: 'transport', colorValue: 0xFF1E88E5, type: CategoryType.expense),
      CategoryModel(id: 'c4', name: 'Shopping', iconKey: 'shopping', colorValue: 0xFFD81B60, type: CategoryType.expense),
      CategoryModel(id: 'c5', name: 'Entertainment', iconKey: 'entertainment', colorValue: 0xFF8E24AA, type: CategoryType.expense),
      CategoryModel(id: 'c6', name: 'Bills & Utilities', iconKey: 'bills', colorValue: 0xFF6D4C41, type: CategoryType.expense),
      CategoryModel(id: 'c7', name: 'Health', iconKey: 'health', colorValue: 0xFFE53935, type: CategoryType.expense),
      CategoryModel(id: 'c8', name: 'Education', iconKey: 'education', colorValue: 0xFF3949AB, type: CategoryType.expense),
      CategoryModel(id: 'c9', name: 'Travel', iconKey: 'travel', colorValue: 0xFF00897B, type: CategoryType.expense),
      CategoryModel(id: 'c10', name: 'Subscriptions', iconKey: 'subscription', colorValue: 0xFF5E35B1, type: CategoryType.expense),
      CategoryModel(id: 'c11', name: 'Other', iconKey: 'other_expense', colorValue: 0xFF757575, type: CategoryType.expense),
      CategoryModel(id: 'c12', name: 'Salary', iconKey: 'salary', colorValue: 0xFF2E7D32, type: CategoryType.income),
      CategoryModel(id: 'c13', name: 'Business', iconKey: 'business', colorValue: 0xFF00695C, type: CategoryType.income),
      CategoryModel(id: 'c14', name: 'Investments', iconKey: 'investment', colorValue: 0xFF1565C0, type: CategoryType.income),
      CategoryModel(id: 'c15', name: 'Freelance', iconKey: 'freelance', colorValue: 0xFF6A1B9A, type: CategoryType.income),
      CategoryModel(id: 'c16', name: 'Gifts', iconKey: 'gift', colorValue: 0xFFC62828, type: CategoryType.income),
      CategoryModel(id: 'c17', name: 'Other Income', iconKey: 'other_income', colorValue: 0xFF558B2F, type: CategoryType.income),
    ];
  }
}
