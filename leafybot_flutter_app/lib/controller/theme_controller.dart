import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../utils/sharedPrefrenceUtils.dart';

class ThemeController extends GetxController {
  var isDarkMode = false.obs;

  ThemeMode get theme => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  void onInit() {
    super.onInit();
    loadTheme();
  }

  /// Load saved theme from SharedPreferences
  Future<void> loadTheme() async {
    final savedTheme = await Preferences.getBool(LeafPreferences.isDarkMode) ?? false;
    isDarkMode.value = savedTheme;
    Get.changeThemeMode(theme); // Apply theme on app start
  }
  Future<void> toggleTheme(bool value) async {
    isDarkMode.value = value;
    await  Preferences.setBool(LeafPreferences.isDarkMode, value);
    Get.changeThemeMode(theme); // updates app theme
  }
}
