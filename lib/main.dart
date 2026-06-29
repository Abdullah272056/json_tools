import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'views/home_view.dart';
import 'views/json_to_dart_view.dart';
import 'generated/json_to_dart_binding.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'JSON Viewer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const HomeView(),
      getPages: [
        GetPage(
          name: '/JsonToDartView',
          page: () => const JsonToDartView(),
          binding: JsonToDartBinding(),
        ),
      ],
    );
  }
}
