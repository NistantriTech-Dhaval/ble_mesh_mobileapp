import 'package:flutter/material.dart';

class ConstantUtils {
  static final List<Map<String, String>> plantsList = [
    {"name": "Areca Palm Plant", "image": "assets/plants/Areca Palm Plant.png"},
    {"name": "Boston Fern Plant", "image": "assets/plants/Boston Fern Plant.png"},
    {"name": "Croton Plant", "image": "assets/plants/Croton Plant.png"},
    {"name": "Flamingo Lily Plant", "image": "assets/plants/Flamingo Lily Plant.png"},
    {"name": "Jade Plant", "image": "assets/plants/Jade Plant.png"},
    {"name": "Lucky Bamboo Plant", "image": "assets/plants/Lucky bamboo Plant.png"},
    {"name": "Orchid Plant", "image": "assets/plants/Orchid Plant.png"},
    {"name": "Pothos Plant", "image": "assets/plants/Pothos Plant.png"},
    {"name": "Snake Plant", "image": "assets/plants/Snake Plant.png"},
    {"name": "Spider Plant", "image": "assets/plants/Spider Plant.png"},
    {"name": "String of Pearls Plant", "image": "assets/plants/String of Pearls Plant.png"},
    {"name": "Weeping Fig Plant", "image": "assets/plants/Weeping Fig Plant.png"},
    {"name": "Yucca Plant", "image": "assets/plants/Yucca Plant.png"},
    {"name": "ZZ Plant", "image": "assets/plants/ZZ Plant.png"},
  ];
  static String getPlantImage(String name) {
    final plant = plantsList.firstWhere(
          (p) => p["name"]!.toLowerCase() == name.toLowerCase(),
      orElse: () => {"image": "assets/plants/Areca Palm Plant.png"}, // fallback
    );
    return plant["image"]!;
  }
  static final List<Map<String, String>> soilsList = [
    {"name": "Clay", "info": "Clay soil is a heavy, dense soil type composed of very fine mineral particles with little organic material."},
    {"name": "Cocopeat", "info": "Cocopeat soil is a natural, sustainable growing medium made from the fibrous husk of coconuts, known for its excellent water retention and aeration properties."},
    {"name": "Mix", "info": "Mixing soil involves combining different types of soil, amendments, and organic matter to create an optimal growing medium tailored to specific plant needs."},
  ];

  static final List<Map<String, String>> plantLoactionList = [
    {"name": "Balcony", "image": "assets/plant_location/Balcony.png"},
    {"name": "Bathroom", "image": "assets/plant_location/bathroom.png"},
    {"name": "Bedroom", "image": "assets/plant_location/Bedroom.png"},
    {"name": "Kitchen", "image": "assets/plant_location/Kitchen.png"},
    {"name": "Living Room", "image": "assets/plant_location/Living Room.png"},
  ];

  static String getLocationImage(String name) {
    final location = plantLoactionList.firstWhere(
          (p) => p["name"]!.toLowerCase() == name.toLowerCase(),
      orElse: () => {"image": "assets/plant_location/Balcony.png"}, // fallback
    );
    return location["image"]!;
  }
  static final List<String> reading_frequency_options = [
    "One every 30 min",
    "One every 1 hour",
    "One every 2 hour",
    "One every 3 hour",
    "One every 4 hour",
  ];

  static List<String> date_range_options = [
    'Current week',
    'Last week',
    'Current month',
    'Custom date range',
  ];

}

