import 'dart:convert';

class PlantSpecies {
  final int id;
  final String plantName;

  // Temperature
  final int tempCIdealMin;
  final int tempCIdealMax;
  final int tempCTolMin;
  final int tempCTolMax;
  final int tempCStressLow;
  final int tempCStressHigh;

  // Relative Humidity
  final int rhPctIdealMin;
  final int rhPctIdealMax;
  final int rhPctTolMin;
  final int rhPctTolMax;
  final int rhPctStressLow;
  final int rhPctStressHigh;

  // Soil Moisture
  final int soilPctIdealMin;
  final int soilPctIdealMax;
  final int soilPctTolMin;
  final int soilPctTolMax;
  final int soilPctStressLow;
  final int soilPctStressHigh;

  // Light
  final int luxIdealMin;
  final int luxIdealMax;
  final int luxTolMin;
  final int luxTolMax;
  final int luxStressLow;
  final int luxStressHigh;

  // Other details
  final String lightingRequirement;
  final String waterFrequency;
  final String soilComposition;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlantSpecies({
    required this.id,
    required this.plantName,
    required this.tempCIdealMin,
    required this.tempCIdealMax,
    required this.tempCTolMin,
    required this.tempCTolMax,
    required this.tempCStressLow,
    required this.tempCStressHigh,
    required this.rhPctIdealMin,
    required this.rhPctIdealMax,
    required this.rhPctTolMin,
    required this.rhPctTolMax,
    required this.rhPctStressLow,
    required this.rhPctStressHigh,
    required this.soilPctIdealMin,
    required this.soilPctIdealMax,
    required this.soilPctTolMin,
    required this.soilPctTolMax,
    required this.soilPctStressLow,
    required this.soilPctStressHigh,
    required this.luxIdealMin,
    required this.luxIdealMax,
    required this.luxTolMin,
    required this.luxTolMax,
    required this.luxStressLow,
    required this.luxStressHigh,
    required this.lightingRequirement,
    required this.waterFrequency,
    required this.soilComposition,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlantSpecies.fromJson(Map<String, dynamic> json) {
    return PlantSpecies(
      id: json['id'],
      plantName: json['plantName'],
      tempCIdealMin: json['tempCIdealMin'],
      tempCIdealMax: json['tempCIdealMax'],
      tempCTolMin: json['tempCTolMin'],
      tempCTolMax: json['tempCTolMax'],
      tempCStressLow: json['tempCStressLow'],
      tempCStressHigh: json['tempCStressHigh'],
      rhPctIdealMin: json['rhPctIdealMin'],
      rhPctIdealMax: json['rhPctIdealMax'],
      rhPctTolMin: json['rhPctTolMin'],
      rhPctTolMax: json['rhPctTolMax'],
      rhPctStressLow: json['rhPctStressLow'],
      rhPctStressHigh: json['rhPctStressHigh'],
      soilPctIdealMin: json['soilPctIdealMin'],
      soilPctIdealMax: json['soilPctIdealMax'],
      soilPctTolMin: json['soilPctTolMin'],
      soilPctTolMax: json['soilPctTolMax'],
      soilPctStressLow: json['soilPctStressLow'],
      soilPctStressHigh: json['soilPctStressHigh'],
      luxIdealMin: json['luxIdealMin'],
      luxIdealMax: json['luxIdealMax'],
      luxTolMin: json['luxTolMin'],
      luxTolMax: json['luxTolMax'],
      luxStressLow: json['luxStressLow'],
      luxStressHigh: json['luxStressHigh'],
      lightingRequirement: json['lightingRequirement'],
      waterFrequency: json['waterFrequency'],
      soilComposition: json['soilComposition'],
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "plantName": plantName,
      "tempCIdealMin": tempCIdealMin,
      "tempCIdealMax": tempCIdealMax,
      "tempCTolMin": tempCTolMin,
      "tempCTolMax": tempCTolMax,
      "tempCStressLow": tempCStressLow,
      "tempCStressHigh": tempCStressHigh,
      "rhPctIdealMin": rhPctIdealMin,
      "rhPctIdealMax": rhPctIdealMax,
      "rhPctTolMin": rhPctTolMin,
      "rhPctTolMax": rhPctTolMax,
      "rhPctStressLow": rhPctStressLow,
      "rhPctStressHigh": rhPctStressHigh,
      "soilPctIdealMin": soilPctIdealMin,
      "soilPctIdealMax": soilPctIdealMax,
      "soilPctTolMin": soilPctTolMin,
      "soilPctTolMax": soilPctTolMax,
      "soilPctStressLow": soilPctStressLow,
      "soilPctStressHigh": soilPctStressHigh,
      "luxIdealMin": luxIdealMin,
      "luxIdealMax": luxIdealMax,
      "luxTolMin": luxTolMin,
      "luxTolMax": luxTolMax,
      "luxStressLow": luxStressLow,
      "luxStressHigh": luxStressHigh,
      "lightingRequirement": lightingRequirement,
      "waterFrequency": waterFrequency,
      "soilComposition": soilComposition,
      "imageUrl": imageUrl,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
    };
  }

  static List<PlantSpecies> listFromJson(String str) =>
      List<PlantSpecies>.from(json.decode(str).map((x) => PlantSpecies.fromJson(x)));
}
