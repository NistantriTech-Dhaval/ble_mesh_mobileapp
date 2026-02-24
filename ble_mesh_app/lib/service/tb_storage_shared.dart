import 'package:shared_preferences/shared_preferences.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

const String _prefix = 'tb_';

/// Persists ThingsBoard auth data (tokens, etc.) using SharedPreferences
/// so the user stays logged in across app restarts.
class TbStorageShared extends TbStorage<dynamic> {
  TbStorageShared._(this._prefs);
  final SharedPreferences _prefs;

  static Future<TbStorageShared> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TbStorageShared._(prefs);
  }

  String _key(String key) => '$_prefix$key';

  @override
  Future<bool> containsKey(String key) async {
    return _prefs.containsKey(_key(key));
  }

  @override
  Future<void> deleteItem(String key) async {
    await _prefs.remove(_key(key));
  }

  @override
  Future<dynamic> getItem(String key, {dynamic defaultValue}) async {
    final value = _prefs.getString(_key(key));
    return value ?? defaultValue;
  }

  @override
  Future<void> setItem(String key, dynamic value) async {
    if (value == null) {
      await deleteItem(key);
      return;
    }
    if (value is String) {
      await _prefs.setString(_key(key), value);
    } else {
      await _prefs.setString(_key(key), value.toString());
    }
  }
}
