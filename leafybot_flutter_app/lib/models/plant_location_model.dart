// models/plant_location_model.dart
import 'dart:convert';

class PlantLocation {
  final int id;
  final String location;
  final String? userId;

  PlantLocation({
    required this.id,
    required this.location,
    this.userId,
  });

  factory PlantLocation.fromJson(Map<String, dynamic> json) {
    return PlantLocation(
      id: json['id'],
      location: json['location'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'userId': userId,
    };
  }

  static List<PlantLocation> listFromJson(String str) =>
      List<PlantLocation>.from(json.decode(str).map((x) => PlantLocation.fromJson(x)));
}
