import 'package:get/get.dart';

class NotificationController extends GetxController {
  var notifications = <Map<String, dynamic>>[
    {
      "dateGroup": "Today",
      "items": [
        {"message": "Rosie needs watering today 💧", "time": "8:20 PM"},
        {"message": "Low light for last 3 days ☁️", "time": "2:10 PM"},
      ],
    },
    {
      "dateGroup": "Yesterday",
      "items": [
        {
          "message": "Temperature too high for optimal growth 🌡🔥",
          "time": "2:10 PM"
        },
      ],
    },
  ].obs;

  /// Remove notification
  void removeNotification(int sectionIndex, int itemIndex) {
    final items = notifications[sectionIndex]["items"] as List;
    items.removeAt(itemIndex);

    // If section becomes empty, remove whole section
    if (items.isEmpty) {
      notifications.removeAt(sectionIndex);
    } else {
      notifications.refresh();
    }
  }
}
