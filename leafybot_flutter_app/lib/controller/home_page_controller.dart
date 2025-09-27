import 'package:get/get.dart';

class HomeController extends GetxController {
  // Devices
  final deviceList = [
    {"name": "LeafyBot #2432", "active": true},
    {"name": "LeafyBot #1111", "active": false},
    {"name": "LeafyBot #5678", "active": true},
  ].obs;

  // Selected device (observable map)
  final RxMap<String, dynamic> selectedBot =
      {"name": "LeafyBot #2432", "active": true}.obs;

  // Change selected bot
  void selectBot(Map<String, dynamic> bot) {
    selectedBot.value = bot;
  }
}
