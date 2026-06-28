import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFFF0F0F0),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: Colors.blue,
  );

  // Classic JSON Viewer Colors - More vibrant
  static const Color objectColor = Color(0xFF0000CD); // Medium Blue
  static const Color arrayColor = Color(0xFF0000CD);  // Medium Blue
  static const Color keyColor = Colors.black;
  static const Color stringColor = Colors.black;
  static const Color numberColor = Colors.black;
  static const Color booleanColor = Colors.black;
  static const Color nullColor = Colors.black;

  static const Color stringSquare = Color(0xFF3366FF); // Vibrant Blue square
  static const Color numberSquare = Color(0xFF28A745); // Vibrant Green square
  static const Color nullSquare = Color(0xFFDC3545);   // Vibrant Red square
}
