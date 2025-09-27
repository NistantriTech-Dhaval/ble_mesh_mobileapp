import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leafybot_flutter_app/utils/sharedPrefrenceUtils.dart';
import 'package:leafybot_flutter_app/utils/url_utils.dart';

import '../models/login_response.dart';
import '../models/profile_response.dart';
import '../models/send_otp_response.dart';
class AuthRepository {
  static Future<LoginResponse> login(
      String phoneNumber, String otpCode) async {
    try {
      final url = Uri.parse("$UrlLogin");

      final response = await http.post(
        url,
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode({
          "phoneNumber": phoneNumber,
          "otpCode": otpCode,
        }),
      );
      debugPrint("🔹 Login API Response [${response.statusCode}]: ${response.body}");
      if (response.statusCode == 200) {
        return LoginResponse.fromJson(jsonDecode(response.body));
      } else {
        final body = jsonDecode(response.body);
        throw body["message"] ?? "Something went wrong";
      }
    } on SocketException {
      throw "No Internet Connection";
    } on FormatException {
      throw "Invalid Response Format";
    } catch (e) {
      throw "$e";
    }
  }
  static Future<SendOtpResponse> sendOtp(String phoneNumber) async {
    try {
      final url = Uri.parse("$UrlSendOtp");

      final response = await http.post(
        url,
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode({
          "phoneNumber": phoneNumber,
        }),
      );
      debugPrint("🔹 Send OTP API Response [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        return SendOtpResponse.fromJson(jsonDecode(response.body));
      } else {
        final body = jsonDecode(response.body);
        throw body["message"] ?? "Something went wrong";
      }
    } on SocketException {
      throw "No Internet Connection";
    } on FormatException {
      throw "Invalid Response Format";
    } catch (e) {
      throw "$e";
    }
  }

 // 🔹 Update Profile API
  static Future<UpdateProfileResponse> updateProfile(
      String fullName, String email) async {
    String token=await Preferences.getString(LeafPreferences.accessToken);
    try {
      final url = Uri.parse("$UrlUpdateProfile");

      final response = await http.post(
        url,
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: "Bearer $token", // if auth required
        },
        body: jsonEncode({
          "fullName": fullName,
          "email": email,
        }),
      );
      debugPrint("🔹 Update Profile API Response [${response.statusCode}]: ${response.body}");
      if (response.statusCode == 200) {
        return UpdateProfileResponse.fromJson(jsonDecode(response.body));
      } else {
        final body = jsonDecode(response.body);
        throw body["message"] ?? "Something went wrong";
      }
    } on SocketException {
      throw "No Internet Connection";
    } on FormatException {
      throw "Invalid Response Format";
    } catch (e) {
      throw "$e";
    }
  }
}
