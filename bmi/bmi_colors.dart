import 'package:flutter/material.dart';

class BmiColors {
  static const bgLight = Color(0xFFF3F7F8);
  static const cardLight = Colors.white;
  static const inkLight = Color(0xFF243244);
  static const inkFaintLight = Color(0xFF8A97A6);
  static const borderLight = Color(0xFFDCE6E8);

  static const bgDark = Color(0xFF121820);
  static const cardDark = Color(0xFF1E2631);
  static const inkDark = Color(0xFFE2E8F0);
  static const inkFaintDark = Color(0xFF94A3B8);
  static const borderDark = Color(0xFF334155);

  static const teal = Color(0xFF0F766E);
  static const underweight = Color(0xFF4A90D9);
  static const normal = Color(0xFF2F9E63);
  static const overweight = Color(0xFFE0A62A);
  static const obese = Color(0xFFD9534F);
  static const veryObese = Color(0xFFB33A32);

  static Color forCategory(String category) {
    switch (category) {
      case 'น้ำหนักน้อย':
        return underweight;
      case 'ปกติ':
        return normal;
      case 'น้ำหนักเกิน':
        return overweight;
      case 'อ้วน':
        return obese;
      case 'อ้วนมาก':
        return veryObese;
      default:
        return inkFaintLight;
    }
  }
}