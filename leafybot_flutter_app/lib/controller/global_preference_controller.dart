import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/utils/consstant_utils.dart';

class GlobalPreferencesController extends GetxController {
  var devices = [
    {"name": "Rosie", "id": "LeafyBot #2432", "goal": Rxn<Duration>()},
    {"name": "Demona", "id": "LeafyBot #1152", "goal": Rxn<Duration>(const Duration(hours: 2, minutes: 20))},
    {"name": "Comy", "id": "LeafyBot #7545", "goal": Rxn<Duration>(const Duration(hours: 1))},
  ].obs;
  var brightness_level = 0.4.obs;
  final selected_reading_frequency = ConstantUtils.reading_frequency_options.first.obs;
  /// Pick Sleep Goal
  Future<void> pickSleepGoal(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 1, minute: 0),
    );

    if (picked != null) {
      devices[index]["goal"] = Duration(
        hours: picked.hour,
        minutes: picked.minute,
      );
    }
  }

  /// Format Duration
  String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0 && m > 0) return "$h Hours $m Min";
    if (h > 0) return "$h Hours";
    return "$m Min";
  }
}
