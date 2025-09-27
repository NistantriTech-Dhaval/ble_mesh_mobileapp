import 'package:get/get.dart';

class PlantsController extends GetxController {
  // Observable list of plants
  var plants = <Map<String, dynamic>>[
    {
      "name": "Rosie",
      "deviceId": "LeafyBot #2432",
      "room": "Living Room",
      "status": true,
      "plantsName": "Areca Palm Plant",
    },
    {
      "name": "Demona",
      "deviceId": "LeafyBot #1152",
      "room": "Bedroom",
      "status": false,
      "plantsName": "ZZ Plant",
    },
    {
      "name": "Comy",
      "deviceId": "LeafyBot #7545",
      "room": "Bathroom",
      "status": false,
      "plantsName": "Yucca Plant",
    },
    {
      "name": "Laky",
      "deviceId": "LeafyBot #2344",
      "room": "Kitchen",
      "status": false,
      "plantsName": "Weeping Fig Plant",
    },
    {
      "name": "Giyan",
      "deviceId": "LeafyBot #4356",
      "room": "Kitchen",
      "status": false,
      "plantsName": "Pothos Plant",
    },
  ].obs;

  /// Remove a plant by index
  void removePlant(int index) {
    plants.removeAt(index);
  }

}
