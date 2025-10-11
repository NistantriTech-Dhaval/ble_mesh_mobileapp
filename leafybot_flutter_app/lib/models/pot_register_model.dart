class PotRegisterModel {
  final String deviceId;
  final int plantTypeId;
  final List<int> soilTypes;
  final String nickName;
  final String plantLocation;
  final int deviceNetworkTypeId;
  final bool isWifiConnected;
  final String networkDetailsJson;
  final String firmwareVersion;
  final String timezone;
  final String otherPlantType;

  PotRegisterModel({
    required this.deviceId,
    required this.plantTypeId,
    required this.soilTypes,
    required this.nickName,
    required this.plantLocation,
    required this.deviceNetworkTypeId,
    required this.isWifiConnected,
    required this.networkDetailsJson,
    required this.firmwareVersion,
    required this.timezone,
    required this.otherPlantType,
  });

  factory PotRegisterModel.fromJson(Map<String, dynamic> json) {
    return PotRegisterModel(
      deviceId: json['deviceId'] ?? '',
      plantTypeId: json['plantTypeId'] ?? 0,
      soilTypes: (json['soilTypes'] as List?)?.map((e) => e as int).toList() ?? [],
      nickName: json['nickName'] ?? '',
      plantLocation: json['plantLocation'] ?? '',
      deviceNetworkTypeId: json['deviceNetworkTypeId'] ?? 0,
      isWifiConnected: json['isWifiConnected'] ?? false,
      networkDetailsJson: json['networkDetailsJson'] ?? '',
      firmwareVersion: json['firmwareVersion'] ?? '',
      timezone: json['timezone'] ?? '',
      otherPlantType: json['otherPlantType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    "deviceId": deviceId,
    "plantTypeId": plantTypeId,
    "soilTypes": soilTypes,
    "nickName": nickName,
    "plantLocation": plantLocation,
    "deviceNetworkTypeId": deviceNetworkTypeId,
    "isWifiConnected": isWifiConnected,
    "networkDetailsJson": networkDetailsJson,
    "firmwareVersion": firmwareVersion,
    "timezone": timezone,
    "otherPlantType": otherPlantType,
  };
}
