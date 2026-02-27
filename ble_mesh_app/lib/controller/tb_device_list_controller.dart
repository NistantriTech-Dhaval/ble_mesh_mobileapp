import 'dart:async';
import 'package:get/get.dart';
import 'package:ntpl_ble_mesh_demo/controller/thingsboard_controller.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// Device list from ThingsBoard over WebSocket. Updates (temp, humidity, bulb, etc.) are merged per device.
class TbDeviceListController extends GetxController {
  final ThingsBoardController _tb = Get.find<ThingsBoardController>();

  TelemetrySubscriber? _deviceSubscription;
  StreamSubscription<EntityDataUpdate>? _subscriptionStream;

  final devices = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final errorMessage = Rxn<String>();
  final isConnected = false.obs;

  static const _preserveFields = {'name', 'type', 'createdTime', 'entityId', 'unicastAddress'};

  @override
  void onReady() {
    super.onReady();
    if (_tb.isAuthenticated) {
      subscribeToDevices();
    }
  }

  @override
  void onClose() {
    unsubscribeFromDevices();
    super.onClose();
  }

  /// Subscribes to device list via WebSocket using TelemetrySubscriber.
  /// This provides continuous updates when devices are added, modified, or deleted.
  void subscribeToDevices() {
    if (!_tb.isAuthenticated) {
      errorMessage.value = 'Not logged in';
      devices.clear();
      return;
    }

    unsubscribeFromDevices();

    isLoading.value = true;
    errorMessage.value = null;

    try {
      // Create EntityDataQuery to fetch all devices with telemetry and server attributes
      final entityFilter = EntityTypeFilter(entityType: EntityType.DEVICE);

      final entityFields = <EntityKey>[
        EntityKey(type: EntityKeyType.ENTITY_FIELD, key: 'name'),
        EntityKey(type: EntityKeyType.ENTITY_FIELD, key: 'label'),
        EntityKey(type: EntityKeyType.ENTITY_FIELD, key: 'createdTime'),
      ];

      // Telemetry: bulb, humidity, temp | Server attribute: unicastAddress
      final latestValues = <EntityKey>[
        EntityKey(type: EntityKeyType.TIME_SERIES, key: 'bulb'),
        EntityKey(type: EntityKeyType.TIME_SERIES, key: 'humidity'),
        EntityKey(type: EntityKeyType.TIME_SERIES, key: 'temp'),
        EntityKey(type: EntityKeyType.SERVER_ATTRIBUTE, key: 'unicastAddress'),
      ];

      final deviceQuery = EntityDataQuery(
        entityFilter: entityFilter,
        entityFields: entityFields,
        latestValues: latestValues,
        pageLink: EntityDataPageLink(
          pageSize: 10000,
          sortOrder: EntityDataSortOrder(
            key: EntityKey(type: EntityKeyType.ENTITY_FIELD, key: 'createdTime'),
            direction: EntityDataSortOrderDirection.DESC,
          ),
        ),
      );

      final latestCmd = LatestValueCmd(keys: latestValues);
      final cmd = EntityDataCmd(query: deviceQuery, latestCmd: latestCmd);
      final telemetryService = _tb.tbClient.getTelemetryService();
      
      _deviceSubscription = TelemetrySubscriber(telemetryService, [cmd]);
      
      _subscriptionStream = _deviceSubscription!.entityDataStream.listen(
        (entityDataUpdate) {
          _handleDeviceUpdate(entityDataUpdate);
        },
        onError: (error) {
          errorMessage.value = error.toString();
          isLoading.value = false;
          isConnected.value = false;
        },
      );

      _deviceSubscription!.subscribe();
      isConnected.value = true;
      isLoading.value = false;
    } catch (e) {
      errorMessage.value = e.toString();
      isLoading.value = false;
      isConnected.value = false;
    }
  }

  /// Handles WebSocket updates: initial data load and subsequent updates.
  void _handleDeviceUpdate(EntityDataUpdate update) {
    // Initial data load (when data != null)
    if (update.data != null) {
      final deviceList = <Map<String, dynamic>>[];
      for (final entityData in update.data!.data) {
        deviceList.add(_entityDataToMap(entityData));
      }
      devices.assignAll(deviceList);
      isLoading.value = false;
    }

    // Updates (when update != null) – merge only changed fields, keep rest as-is
    if (update.update != null) {
      for (final entityData in update.update!) {
        final updateMap = _entityDataToMap(entityData);
        final deviceId = updateMap['id'] as String;

        final index = devices.indexWhere((d) => d['id'] == deviceId);
        if (index >= 0) {
          // Merge: update only keys that have a new value; leave others unchanged
          devices[index] = _mergeDeviceMap(devices[index], updateMap);
        } else {
          devices.add(updateMap);
        }
      }
      devices.refresh();
    }
  }

  /// Merges update into existing: only keys present in [update] with a value are written.
  Map<String, dynamic> _mergeDeviceMap(
    Map<String, dynamic> existing,
    Map<String, dynamic> update,
  ) {
    final merged = Map<String, dynamic>.from(existing);
    for (final entry in update.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value == null) continue;
      if (value is String && value.isEmpty && _preserveFields.contains(key)) continue;
      merged[key] = value;
    }
    return merged;
  }

  /// Builds a device map from EntityData. Only non-null fields are set so merge keeps existing values.
  Map<String, dynamic> _entityDataToMap(EntityData entityData) {
    final id = entityData.entityId.id ?? '';
    final map = <String, dynamic>{'id': id};

    final name = entityData.field('name');
    if (name != null && name.isNotEmpty) map['name'] = name;

    final label = entityData.field('label');
    if (label != null && label.isNotEmpty) map['label'] = label;

    final createdTime = entityData.createdTime;
    if (createdTime != null) map['createdTime'] = createdTime;

    map['entityId'] = entityData.entityId;

    final bulb = _latestTelemetry(entityData, 'bulb', caseInsensitive: true);
    if (bulb != null) map['bulb'] = bulb;

    final humidity = _latestTelemetry(entityData, 'humidity');
    if (humidity != null) map['humidity'] = humidity;

    final temp = _latestTelemetry(entityData, 'temp');
    if (temp != null) map['temp'] = temp;

    final unicastStr = entityData.serverAttribute('unicastAddress');
    if (unicastStr != null) {
      final u = int.tryParse(unicastStr);
      if (u != null) map['unicastAddress'] = u;
    }

    return map;
  }

  /// Latest telemetry value for [key]. [caseInsensitive] for keys like "Bulb"/"bulb".
  String? _latestTelemetry(EntityData entityData, String key, {bool caseInsensitive = false}) {
    final tsMap = entityData.latest[EntityKeyType.TIME_SERIES];
    if (tsMap == null) return null;
    if (caseInsensitive) {
      final keyLower = key.toLowerCase();
      for (final e in tsMap.entries) {
        if (e.key.toLowerCase() == keyLower) return e.value?.value;
      }
      return null;
    }
    return tsMap[key]?.value;
  }

  /// Unsubscribes from WebSocket and cleans up resources.
  void unsubscribeFromDevices() {
    _subscriptionStream?.cancel();
    _subscriptionStream = null;
    _deviceSubscription?.unsubscribe();
    _deviceSubscription = null;
    isConnected.value = false;
  }

  /// Manual refresh: re-subscribes to get latest device list.
  Future<void> refreshDevices() async {
    subscribeToDevices();
  }

  Future<void> onOffRpcCommand(String deviceId, String value, int unicastAddress) async {
    try {
      var requestBody = {
        "method": "set_bulb",   // 👈 Your device RPC method name
        "params": {
          "state": value  , // true = ON, false = OFF
          "address": unicastAddress
        }
      };

      await _tb.tbClient
          .getDeviceService()
          .handleOneWayDeviceRPCRequest(
        deviceId,
        requestBody,
      );

      print("RPC sent successfully");
    } catch (e) {
      print("RPC Error: $e");
    }
  }
}
