import 'package:flutter/material.dart';

class AppTokens {
  // Spacing
  static const double sp8 = 8;
  static const double sp12 = 12;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;

  // Radius
  static const Radius r12 = Radius.circular(12);
  static const BorderRadius br16 = BorderRadius.all(Radius.circular(16));

  // Elevation Shadows (اختياري)
  static const List<BoxShadow> shadowMed = [
    BoxShadow(blurRadius: 12, spreadRadius: 0, offset: Offset(0, 6), color: Colors.black26),
  ];
}
