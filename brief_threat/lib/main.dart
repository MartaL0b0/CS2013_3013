import 'package:flutter/material.dart';
import 'package:brief_threat/Screens/LoginScreen.dart';
import 'package:brief_threat/colors.dart' as colors;

void main() {
  runApp(MaterialApp(
      title: 'Form app',
      home: LoginScreen(),
      routes: <String, WidgetBuilder> {
        '/Login': (BuildContext context) => new LoginScreen(),
      },
      theme : buildTheme()
    ));
}

ThemeData buildTheme() {
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    primaryColor: colors.primaryColor,
    accentColor: colors.accentColor,
    buttonColor: colors.primaryColor,
    backgroundColor: colors.primaryColor
  );
}