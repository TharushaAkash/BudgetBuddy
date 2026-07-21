import 'package:flutter/material.dart';

enum InstallmentPlatform { koko, mintpay, creditCard, other }

const Map<InstallmentPlatform, String> kPlatformNames = {
  InstallmentPlatform.koko: 'Koko',
  InstallmentPlatform.mintpay: 'Mintpay',
  InstallmentPlatform.creditCard: 'Credit Card',
  InstallmentPlatform.other: 'Other',
};

const Map<InstallmentPlatform, Color> kPlatformColors = {
  InstallmentPlatform.koko: Color(0xFFF95B72), // Koko pinkish
  InstallmentPlatform.mintpay: Color(0xFF00C9A7), // Mintpay green
  InstallmentPlatform.creditCard: Color(0xFF1565C0), // Blue
  InstallmentPlatform.other: Colors.grey,
};

class InstallmentModel {
  final String id;
  String shop;
  String item;
  InstallmentPlatform platform;
  double totalAmount;
  int months;
  DateTime firstPaymentDate;

  InstallmentModel({
    required this.id,
    required this.shop,
    required this.item,
    required this.platform,
    required this.totalAmount,
    required this.months,
    required this.firstPaymentDate,
  });

  double get monthlyAmount => totalAmount / months;

  int get paidMonths {
    final now = DateTime.now();
    // Start of today to compare with dates safely
    final today = DateTime(now.year, now.month, now.day);
    final first = DateTime(firstPaymentDate.year, firstPaymentDate.month, firstPaymentDate.day);
    
    if (today.isBefore(first)) return 0;
    
    int monthsDiff = (today.year - first.year) * 12 + today.month - first.month;
    if (today.day < first.day) {
      monthsDiff--;
    }
    
    int paid = monthsDiff + 1; // +1 because first payment is ON the first date
    return paid > months ? months : (paid < 0 ? 0 : paid);
  }

  double get paidAmount => paidMonths * monthlyAmount;
  double get remainingAmount => totalAmount - paidAmount;
  bool get isCompleted => paidMonths >= months;

  DateTime? get nextPaymentDate {
    if (isCompleted) return null;
    // Calculate the next month using correct day mapping (handles month overflow properly)
    return DateTime(firstPaymentDate.year, firstPaymentDate.month + paidMonths, firstPaymentDate.day);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shop': shop,
        'item': item,
        'platform': platform.name,
        'totalAmount': totalAmount,
        'months': months,
        'firstPaymentDate': firstPaymentDate.toIso8601String(),
      };

  factory InstallmentModel.fromJson(Map<String, dynamic> json) => InstallmentModel(
        id: json['id'],
        shop: json['shop'],
        item: json['item'],
        platform: InstallmentPlatform.values.firstWhere(
          (e) => e.name == json['platform'],
          orElse: () => InstallmentPlatform.other,
        ),
        totalAmount: (json['totalAmount'] as num).toDouble(),
        months: json['months'],
        firstPaymentDate: DateTime.parse(json['firstPaymentDate']),
      );
}
