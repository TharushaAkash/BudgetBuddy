import 'package:flutter/material.dart';

enum AccountType { cash, bank, card, wallet, savings, petty_cash }

const Map<AccountType, IconData> kAccountIcons = {
  AccountType.cash: Icons.payments,
  AccountType.bank: Icons.account_balance,
  AccountType.card: Icons.credit_card,
  AccountType.wallet: Icons.account_balance_wallet,
  AccountType.savings: Icons.savings,
  AccountType.petty_cash: Icons.monetization_on,
};

const Map<AccountType, String> kAccountLabels = {
  AccountType.cash: 'Cash',
  AccountType.bank: 'Bank Account',
  AccountType.card: 'Credit Card',
  AccountType.wallet: 'E-Wallet',
  AccountType.savings: 'Savings',
  AccountType.petty_cash: 'Petty Cash',
};

class AccountModel {
  final String id;
  String name;
  AccountType type;
  double openingBalance;
  int colorValue;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.colorValue,
  });

  IconData get icon => kAccountIcons[type] ?? Icons.account_balance_wallet;
  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'openingBalance': openingBalance,
        'colorValue': colorValue,
      };

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
        id: json['id'],
        name: json['name'],
        type: AccountType.values.firstWhere((e) => e.name == json['type']),
        openingBalance: (json['openingBalance'] as num).toDouble(),
        colorValue: json['colorValue'],
      );

  static List<AccountModel> defaults() => [
        AccountModel(id: 'a1', name: 'Cash', type: AccountType.cash, openingBalance: 0, colorValue: 0xFF2E7D32),
        AccountModel(id: 'a2', name: 'Main Bank', type: AccountType.bank, openingBalance: 0, colorValue: 0xFF1565C0),
        AccountModel(id: 'a3', name: 'Credit Card', type: AccountType.card, openingBalance: 0, colorValue: 0xFFC62828),
        AccountModel(id: 'a4', name: 'Petty Cash', type: AccountType.petty_cash, openingBalance: 0, colorValue: 0xFFFF9800),
      ];
}
