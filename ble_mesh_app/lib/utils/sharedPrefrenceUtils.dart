import 'package:shared_preferences/shared_preferences.dart';

class LeafPreferences {
  static String accessToken = "AccessToken";
  static String userId = "userId";
  static String phoneNumber = "phoneNumber";
  static String isDarkMode = "isDarkMode";
}


class Preferences {
  static Future<bool> setString(String key, String data) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, data);
  }

  static Future<String> getString(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key)??"";
  }

  static Future<bool> setInt(String key, int data) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setInt(key, data);
  }

  static Future<int> getInt(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key)??0;
  }

  static Future<bool> setBool(String key, bool data) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(key, data);
  }

  static Future<bool> getBool(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<bool> clearAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }
}
