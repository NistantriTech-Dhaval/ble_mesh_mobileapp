import 'dart:convert';

class SoilType {
  final int id;
  final String key;
  final String name;
  final String description;
  final String recommendedComposition;

  SoilType({
    required this.id,
    required this.key,
    required this.name,
    required this.description,
    required this.recommendedComposition,
  });

  factory SoilType.fromJson(Map<String, dynamic> json) {
    return SoilType(
      id: json['id'],
      key: json['key'] ?? "",
      name: json['name'] ?? "",
      description: json['description'] ?? "",
      recommendedComposition: json['recommendedComposition'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'name': name,
      'description': description,
      'recommendedComposition': recommendedComposition,
    };
  }

  static List<SoilType> listFromJson(String str) =>
      List<SoilType>.from(json.decode(str).map((x) => SoilType.fromJson(x)));
}
