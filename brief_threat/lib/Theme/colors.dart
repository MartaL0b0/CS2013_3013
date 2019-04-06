import 'package:flutter/material.dart';

const primaryColor = const Color(0xFF9C27B0);
const accentColor = const Color(0xFFE040FB);
const buttonColor = const Color(0xFF6a0080);

ThemeData buildTheme() {
  final ThemeData base = ThemeData.light();
  return base.copyWith(
      primaryColor: primaryColor,
      accentColor: accentColor,
      buttonColor: primaryColor,
      backgroundColor: primaryColor
  );
}