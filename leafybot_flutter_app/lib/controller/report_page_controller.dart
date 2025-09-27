import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReportPageController extends GetxController {
  // Devices
  final deviceList = [
    {"name": "Roise"},
    {"name": "LeafyBot"},
    {"name": "Roise 3"},
  ].obs;

  // Selected device (observable map)
  final RxMap<String, dynamic> selectedBot =
      {"name": "LeafyBot"}.obs;

  DateTimeRange? customRange;
  RxString selected_date_range = 'Current week'.obs;
  // Change selected bot
  void selectBot(Map<String, dynamic> bot) {
    selectedBot.value = bot;
  }

  DateTimeRange getPresetRange(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (preset) {
      case 'Current week':
        final start = today.subtract(Duration(days: today.weekday - 1));
        final end = start.add(Duration(days: 6));
        return DateTimeRange(start: start, end: end);

      case 'Last week':
        final end = today.subtract(Duration(days: today.weekday));
        final start = end.subtract(Duration(days: 6));
        return DateTimeRange(start: start, end: end);

      case 'Current month':
        final start = DateTime(today.year, today.month, 1);
        final end = DateTime(
            today.year, today.month + 1, 0); // Last day of month
        return DateTimeRange(start: start, end: end);

      case 'Custom date range':
        return customRange ??
            DateTimeRange(start: today, end: today); // Fallback for null

      default:
        return DateTimeRange(start: today, end: today);
    }
  }
  Future<void> selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: customRange ?? DateTimeRange(start: DateTime.now(), end: DateTime.now()),
    );

    if (picked != null) {
        customRange = picked;
        selected_date_range.value = 'Custom date range';
    }
  }
}
