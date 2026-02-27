import 'package:get/get.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// ThingsBoard server base URL. Change this to your ThingsBoard instance.
const String thingsBoardBaseUrl = 'https://tbce.nistantritech.com';

/// App-wide ThingsBoard API client controller.
/// Use [tbClient] anywhere to call ThingsBoard APIs (devices, assets, telemetry, etc.).
///
/// Example usage from any screen or controller:
/// ```dart
/// final tb = Get.find<ThingsBoardController>();
/// if (tb.isAuthenticated) {
///   var user = await tb.tbClient.getUserService().getUser();
///   var deviceService = tb.tbClient.getDeviceService();
///   var telemetryService = tb.tbClient.getTelemetryService();
///   var assetService = tb.tbClient.getAssetService();
///   // or raw: tb.tbClient.get('/api/...'), tb.tbClient.post('/api/...', data: ...);
/// }
/// ```
class ThingsBoardController extends GetxController {
  ThingsBoardController({
    String? baseUrl,
    TbStorage<dynamic>? storage,
  }) {
    _client = ThingsboardClient(
      baseUrl ?? thingsBoardBaseUrl,
      storage: storage,
    );
  }

  late final ThingsboardClient _client;

  /// The ThingsBoard API client. Use this everywhere to call TB APIs:
  /// - getUserService(), getDeviceService(), getAssetService()
  /// - getTelemetryService(), getAttributeService(), getAlarmService()
  /// - get(path), post(path, data), etc.
  ThingsboardClient get tbClient => _client;


  /// Whether the stored JWT is still valid (not expired).
  bool get isJwtTokenValid => _client.isJwtTokenValid();

  /// Whether the user is logged in and the token is valid.
  bool get isAuthenticated =>
      _client.isAuthenticated() && _client.isJwtTokenValid();

  /// Current auth user (null if not logged in).
  AuthUser? get authUser => _client.getAuthUser();

  /// JWT token for WebSocket or other API use. Null if not authenticated.
  String? get jwtToken => _client.getJwtToken();

  /// On app start/resume: loads stored tokens from storage, then if valid returns true; if not, tries to refresh.
  Future<bool> ensureValidToken() async {
    try {
      await _client.init();
    } catch (_) {
      // No stored session or init failed
    }
    if (_client.isJwtTokenValid()) return true;
    if (!_client.isAuthenticated()) return false;
    try {
      await _client.refreshJwtToken();
      return _client.isJwtTokenValid();
    } catch (_) {
      return false;
    }
  }

  /// Login with ThingsBoard credentials.
  /// Returns true on success, false on failure.
  Future<bool> login(String username, String password) async {
    try {
      await _client.login(LoginRequest(username, password));
      return _client.isAuthenticated() && _client.isJwtTokenValid();
    } catch (e) {
      return false;
    }
  }

  /// Logout from ThingsBoard.
  Future<void> logout() async {
    try {
      await _client.logout();
    } catch (_) {}
  }
}
