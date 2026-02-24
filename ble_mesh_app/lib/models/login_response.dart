import 'dart:convert';

class LoginResponse {
  final String token;
  final String userId;
  final String phoneNumber;
  final bool isProfileComplete;

  LoginResponse({
    required this.token,
    required this.userId,
    required this.phoneNumber,
    required this.isProfileComplete,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      userId: json['userId'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      isProfileComplete: json['isProfileComplete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "token": token,
      "userId": userId,
      "phoneNumber": phoneNumber,
      "isProfileComplete": isProfileComplete,
    };
  }

  static LoginResponse fromRawJson(String str) =>
      LoginResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());
}
