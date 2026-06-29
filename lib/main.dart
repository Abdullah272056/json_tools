import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'views/home_view.dart';
import 'views/json_to_dart_view.dart';
import 'views/index_view.dart';
import 'generated/json_to_dart_binding.dart';
import 'utils/app_theme.dart';
import 'controllers/theme_controller.dart';

void main() {
  Get.put(ThemeController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() => GetMaterialApp(
      title: 'JSON Viewer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => const IndexView(),
        ),
        GetPage(
          name: '/HomeView',
          page: () => const HomeView(),
        ),
        GetPage(
          name: '/JsonToDartView',
          page: () => const JsonToDartView(),
          binding: JsonToDartBinding(),
        ),
      ],
    ));
  }
}
