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
  final String shop;
  final String item;
  final InstallmentPlatform platform;
  final double totalAmount;
  final int months;
  final int paidMonths;
  final DateTime firstPaymentDate;

  InstallmentModel({
    required this.id,
    required this.shop,
    required this.item,
    required this.platform,
    required this.totalAmount,
    required this.months,
    required this.firstPaymentDate,
    this.paidMonths = 0,
  });

  double get monthlyAmount => totalAmount / months;

  double get paidAmount => paidMonths * monthlyAmount;
  double get remainingAmount => totalAmount - paidAmount;
  bool get isCompleted => paidMonths >= months;

  DateTime? get nextPaymentDate {
    if (isCompleted) return null;
    return firstPaymentDate.add(Duration(days: 30 * paidMonths));
  }

  InstallmentModel copyWith({
    String? id,
    String? shop,
    String? item,
    InstallmentPlatform? platform,
    double? totalAmount,
    int? months,
    int? paidMonths,
    DateTime? firstPaymentDate,
  }) {
    return InstallmentModel(
      id: id ?? this.id,
      shop: shop ?? this.shop,
      item: item ?? this.item,
      platform: platform ?? this.platform,
      totalAmount: totalAmount ?? this.totalAmount,
      months: months ?? this.months,
      paidMonths: paidMonths ?? this.paidMonths,
      firstPaymentDate: firstPaymentDate ?? this.firstPaymentDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shop': shop,
        'item': item,
        'platform': platform.name,
        'totalAmount': totalAmount,
        'months': months,
        'firstPaymentDate': firstPaymentDate.toIso8601String(),
        'paidMonths': paidMonths,
      };

  factory InstallmentModel.fromJson(Map<String, dynamic> json) {
    int calculated = 0;
    if (json['firstPaymentDate'] != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final first = DateTime.parse(json['firstPaymentDate']);
      if (!today.isBefore(first)) {
        int monthsDiff = (today.year - first.year) * 12 + today.month - first.month;
        if (today.day < first.day) monthsDiff--;
        calculated = monthsDiff + 1;
        if (calculated > (json['months'] as int)) calculated = json['months'];
        if (calculated < 0) calculated = 0;
      }
    }
    
    return InstallmentModel(
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
      paidMonths: json['paidMonths'] ?? calculated,
    );
  }
}
