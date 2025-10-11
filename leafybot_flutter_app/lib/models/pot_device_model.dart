// models/device_response_model.dart

import 'dart:convert';

class PotDeviceModel {
  final String appDeviceId;
  final String deviceId;
  final String nickName;
  final String plantLocation;
  final String imageUrl;

  PotDeviceModel({
    required this.appDeviceId,
    required this.deviceId,
    required this.nickName,
    required this.plantLocation,
    required this.imageUrl,
  });

  factory PotDeviceModel.fromJson(Map<String, dynamic> json) {
    return PotDeviceModel(
      appDeviceId: json['appDeviceId'] ?? '',
      deviceId: json['deviceId'] ?? '',
      nickName: json['nickName'] ?? '',
      plantLocation: json['plantLocation'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "appDeviceId": appDeviceId,
    "deviceId": deviceId,
    "nickName": nickName,
    "plantLocation": plantLocation,
    "imageUrl": imageUrl,
  };

  static List<PotDeviceModel> listFromJson(dynamic jsonList) {
    if (jsonList is String) {
      jsonList = jsonDecode(jsonList);
    }
    if (jsonList is List) {
      return jsonList.map((e) => PotDeviceModel.fromJson(e)).toList();
    }
    return [];
  }
}
