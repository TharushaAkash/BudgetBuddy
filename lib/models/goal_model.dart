import 'dart:convert';
import 'package:flutter/material.dart';

class GoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime targetDate;
  final int colorValue;
  final int iconCodePoint;

  GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0.0,
    required this.targetDate,
    required this.colorValue,
    required this.iconCodePoint,
  });

  Color get color => Color(colorValue);
  IconData get icon => Icons.flag_rounded;
  double get progress => targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => savedAmount >= targetAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'targetDate': targetDate.millisecondsSinceEpoch,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      targetAmount: map['targetAmount']?.toDouble() ?? 0.0,
      savedAmount: map['savedAmount']?.toDouble() ?? 0.0,
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['targetDate'] ?? 0),
      colorValue: map['colorValue'] ?? Colors.blue.toARGB32(),
      iconCodePoint: map['iconCodePoint'] ?? Icons.flag_rounded.codePoint,
    );
  }

  String toJson() => json.encode(toMap());

  factory GoalModel.fromJson(String source) => GoalModel.fromMap(json.decode(source));
}
