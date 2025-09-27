import 'dart:convert';

class SendOtpResponse {
  final bool success;
  final String message;
  final String currentOtp;

  SendOtpResponse({
    required this.success,
    required this.message,
    required this.currentOtp,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      currentOtp: json['currentOtp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "message": message,
      "currentOtp": currentOtp,
    };
  }

  static SendOtpResponse fromRawJson(String str) =>
      SendOtpResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());
}
