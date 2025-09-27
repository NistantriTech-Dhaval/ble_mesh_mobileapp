import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:leafybot_flutter_app/models/plant_species_model.dart';
import 'package:leafybot_flutter_app/models/soil_type_model.dart';
import 'package:leafybot_flutter_app/utils/url_utils.dart';
import '../models/login_response.dart';
import '../models/plant_location_model.dart';
import '../utils/sharedPrefrenceUtils.dart';
class PlantRepository {
  static Future<List<PlantSpecies>> getAllPlantSpecies() async {
    String token=await Preferences.getString(LeafPreferences.accessToken);
    try {
      final url = Uri.parse("$UrlAllPlantSpecies");

      final response = await http.get(
        url,
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: "Bearer $token", // if auth required
        },
      );
      debugPrint("🔹 Update getAllPlantSpecies API Response [${response.statusCode}]: ${response.body}");
      if (response.statusCode == 200) {
        return PlantSpecies.listFromJson(response.body);
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

  static Future<List<SoilType>> getAllSoilTypes() async {
    String token=await Preferences.getString(LeafPreferences.accessToken);
    try {
      final url = Uri.parse("$UrlAllSoilTypes");

      final response = await http.get(
        url,
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: "Bearer $token", // if auth required
        },
      );
      debugPrint("🔹 Update getAllSoilTypes API Response [${response.statusCode}]: ${response.body}");
      if (response.statusCode == 200) {
        return SoilType.listFromJson(response.body);
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

  static Future<List<PlantLocation>> getAllPlantLocatinos() async {
    String token=await Preferences.getString(LeafPreferences.accessToken);
    try {
      final url = Uri.parse("$UrlAllPlantLocations");

      final response = await http.get(
        url,
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: "Bearer $token", // if auth required
        },
      );
      debugPrint("🔹 Update getAllPlantLocatinos API Response [${response.statusCode}]: ${response.body}");
      if (response.statusCode == 200) {
        return PlantLocation.listFromJson(response.body);
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

  static  addPlantLocatino(String location_name) async {
    String token=await Preferences.getString(LeafPreferences.accessToken);
    try {
      final url = Uri.parse("$UrlAddPlantLocation");

      final response = await http.post(
        url,
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: "Bearer $token", // if auth required
        },
        body: jsonEncode({
          "location": location_name
        }),
      );
      debugPrint("🔹 Update addPlantLocatino API Response [${response.statusCode}]: ${response.body}");
      if (response.statusCode == 200) {

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
