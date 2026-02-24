import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackBar {
  static void show(
      String type,
      String message, {
        SnackPosition position = SnackPosition.BOTTOM,
        Duration duration = const Duration(seconds: 2),
      }) {
    final context = Get.context;
    if (context == null) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Config for each type
    final typeConfig = {
      "error": {
        "bgColor": isDark ? Colors.red.shade700 : Colors.red.shade400,
        "icon": Icons.error,
        "title": "Error",
        "iconColor": Colors.white,
      },
      "warning": {
        "bgColor": isDark ? Colors.orange.shade700 : Colors.orange.shade400,
        "icon": Icons.warning,
        "title": "Warning",
        "iconColor": Colors.white,
      },
      "success": {
        "bgColor": isDark ? Colors.green.shade800 : Colors.green.shade400, // changed for dark
        "icon": Icons.check_circle,
        "title": "Success",
        "iconColor": Colors.white,
      },
      "info": {
        "bgColor": isDark ? Colors.blue.shade700 : Colors.blue.shade400,
        "icon": Icons.info,
        "title": "Info",
        "iconColor": Colors.white,
      },
    };

    final config = typeConfig[type.toLowerCase()] ?? typeConfig["info"]!;

    final bgColor = config["bgColor"] as Color;
    final icon = config["icon"] as IconData;
    final title = config["title"] as String;
    final iconColor = config["iconColor"] as Color;

    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: bgColor,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: duration,
      icon: Icon(icon, color: iconColor),
    );
  }
}
