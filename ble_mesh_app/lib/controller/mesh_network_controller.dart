import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ntpl_ble_mesh_demo/Comman_Widget/custom_snackbar.dart';
import 'package:ntpl_ble_mesh_demo/controller/thingsboard_controller.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// ThingsBoard asset type used for mesh networks.
const String meshNetworkAssetType = 'MeshNetwork';

/// Server-side attribute scope for mesh network attributes.
const String _attrScope = 'SERVER_SCOPE';

/// Attribute keys for mesh network information stored on the Asset.
class MeshNetworkAttrKeys {
  static const String description = 'description';
  static const String createdAt = 'createdAt';
  static const String meshNetworkJson = 'meshNetworkJson';
  static const String networkName = 'networkName';
  static const String deviceCount = 'deviceCount';
  static const String lastModified = 'lastModified';
  static const String gatewayUnicastAddress = 'gatewayUnicastAddress';

  static const List<String> all = [
    description,
    createdAt,
    meshNetworkJson,
    networkName,
    deviceCount,
    lastModified,
    gatewayUnicastAddress,
  ];
}

/// ThingsBoard device type for BLE mesh provisioned devices.
const String meshDeviceType = 'BLE Mesh Device';

/// Device SERVER_SCOPE attribute keys for provisioned mesh device details.
class MeshDeviceAttrKeys {
  static const String deviceName = 'deviceName';
  static const String macAddress = 'macAddress';
  static const String unicastAddress = 'unicastAddress';
  static const String meshNodeUuid = 'meshNodeUuid';
  static const String meshNetworkAssetId = 'meshNetworkAssetId';
  static const String commissionedAt = 'commissionedAt';
  static const String bleDeviceId = 'bleDeviceId';
  static const String isGateway = 'isGateway';
}

/// Controller to fetch and add mesh networks stored as ThingsBoard assets.
/// Mesh network details are stored in asset SERVER_SCOPE attributes.
class MeshNetworkController extends GetxController {
  final ThingsBoardController _tb = Get.find<ThingsBoardController>();

  final networks = <AssetInfo>[].obs;
  final isLoading = false.obs;
  final selectedNetworkId = Rxn<String>();

  /// Default name for the auto-created mesh network when list is empty.
  static const String defaultNetworkName = 'Default Network';

  /// Fetches mesh networks from ThingsBoard. If list is empty, creates a default mesh network then refetches.
  Future<void> fetchNetworks() async {
    if (!_tb.isAuthenticated) {
      AppSnackBar.show('error', 'Please log in to fetch networks.');
      return;
    }
    isLoading.value = true;
    try {
      final pageLink = PageLink(50, 0);
      final pageData = await _tb.tbClient
          .getAssetService()
          .getTenantAssetInfos(pageLink, type: meshNetworkAssetType);
      final list = pageData.data ?? [];
      if (list.isEmpty) {
        await _createDefaultMeshNetwork();
        final again = await _tb.tbClient
            .getAssetService()
            .getTenantAssetInfos(pageLink, type: meshNetworkAssetType);
        networks.assignAll(again.data ?? []);
      } else {
        networks.assignAll(list);
      }
    } catch (e) {
      AppSnackBar.show('error', 'Failed to fetch networks.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Creates a default mesh network asset with default attributes (when no networks exist).
  Future<void> _createDefaultMeshNetwork() async {
    try {
      final asset = Asset(defaultNetworkName, meshNetworkAssetType);
      asset.label = 'Default BLE mesh network for commissioning';
      final saved = await _tb.tbClient.getAssetService().saveAsset(asset);
      final idStr = saved.id?.id;
      if (idStr == null) return;
      // Brief delay so ThingsBoard can persist the asset before saving attributes
      await Future.delayed(const Duration(milliseconds: 300));
      final assetId = AssetId(idStr);
      final now = DateTime.now().millisecondsSinceEpoch;
      final attrs = <String, dynamic>{
        MeshNetworkAttrKeys.networkName: defaultNetworkName,
        MeshNetworkAttrKeys.description: 'Default BLE mesh network for commissioning',
        MeshNetworkAttrKeys.createdAt: now,
        MeshNetworkAttrKeys.lastModified: now,
        MeshNetworkAttrKeys.deviceCount: 0,
        MeshNetworkAttrKeys.meshNetworkJson: '', // network information key present; empty = load from local when commissioning
      };
      await _tb.tbClient.getAttributeService().saveEntityAttributesV1(
            assetId,
            _attrScope,
            attrs,
          );
    } catch (e) {
      // Surface failure so we don't silently miss attribute save
      debugPrint('_createDefaultMeshNetwork: $e');
      rethrow;
    }
  }

  /// Adds a new mesh network (creates Asset and saves mesh network info in attributes).
  Future<bool> addNetwork(String name, {String? description}) async {
    if (!_tb.isAuthenticated) {
      AppSnackBar.show('error', 'Please log in to add a network.');
      return false;
    }
    if (name.trim().isEmpty) {
      AppSnackBar.show('error', 'Network name is required.');
      return false;
    }
    try {
      final asset = Asset(name.trim(), meshNetworkAssetType);
      if (description != null && description.trim().isNotEmpty) {
        asset.label = description.trim();
      }
      final saved = await _tb.tbClient.getAssetService().saveAsset(asset);
      final assetId = saved.id;
      if (assetId != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final attrs = <String, dynamic>{
          MeshNetworkAttrKeys.networkName: name.trim(),
          MeshNetworkAttrKeys.createdAt: now,
          MeshNetworkAttrKeys.lastModified: now,
          MeshNetworkAttrKeys.deviceCount: 0,
          MeshNetworkAttrKeys.meshNetworkJson: '', // network information key present; empty = load from local when commissioning
        };
        if (description != null && description.trim().isNotEmpty) {
          attrs[MeshNetworkAttrKeys.description] = description.trim();
        }
        await _tb.tbClient.getAttributeService().saveEntityAttributesV1(
              assetId,
              _attrScope,
              attrs,
            );
      }
      AppSnackBar.show('success', 'Network added.');
      try {
        await fetchNetworks();
      } catch (_) {
        // List refresh failed but add succeeded; dialog should still close
      }
      return true;
    } catch (e) {
      AppSnackBar.show('error', 'Failed to add network.');
      return false;
    }
  }

  /// Saves mesh network information into asset attributes (e.g. after export from Nordic mesh).
  /// Saves metadata first, then meshNetworkJson in a separate request so large JSON is saved reliably.
  Future<bool> saveMeshNetworkAttributes(
    String assetIdStr, {
    String? meshNetworkJson,
    int? deviceCount,
  }) async {
    if (!_tb.isAuthenticated) return false;
    final assetId = AssetId(assetIdStr);
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      // 1) Save metadata (lastModified, deviceCount) so at least these are stored
      final metaAttrs = <String, dynamic>{
        MeshNetworkAttrKeys.lastModified: now,
      };
      if (deviceCount != null) {
        metaAttrs[MeshNetworkAttrKeys.deviceCount] = deviceCount;
      }
      await _tb.tbClient.getAttributeService().saveEntityAttributesV1(
            assetId,
            _attrScope,
            metaAttrs,
          );
    } catch (e) {
      debugPrint('saveMeshNetworkAttributes (meta): $e');
      return false;
    }
    // 2) Save network information (meshNetworkJson) in a separate call so large payload doesn't fail silently
    if (meshNetworkJson != null && meshNetworkJson.isNotEmpty) {
      try {
        await _tb.tbClient.getAttributeService().saveEntityAttributesV1(
              assetId,
              _attrScope,
              <String, dynamic>{MeshNetworkAttrKeys.meshNetworkJson: meshNetworkJson},
            );
      } catch (e) {
        debugPrint('saveMeshNetworkAttributes (meshNetworkJson): $e');
        return false;
      }
    }
    return true;
  }

  /// Fetches mesh network attributes for an asset.
  Future<Map<String, dynamic>> getMeshNetworkAttributes(String assetIdStr) async {
    final out = <String, dynamic>{};
    if (!_tb.isAuthenticated) return out;
    try {
      final assetId = AssetId(assetIdStr);
      final entries = await _tb.tbClient.getAttributeService().getAttributesByScope(
            assetId,
            _attrScope,
            MeshNetworkAttrKeys.all,
          );
      for (final e in entries) {
        final k = e.getKey();
        final v = e.getValue();
        if (k != null && v != null) out[k] = v;
      }
    } catch (_) {}
    return out;
  }

  /// Creates a device in ThingsBoard, links it to the mesh network asset, and saves required details in device attributes.
  /// Returns the created device id (uuid string) or null on failure.
  Future<String?> createAndLinkDevice(
    String meshNetworkAssetId,
    String deviceName, {
    required Map<String, dynamic> details,
  }) async {
    if (!_tb.isAuthenticated) return null;
    try {
      final name = deviceName.trim().isEmpty ? 'Mesh Device ${DateTime.now().millisecondsSinceEpoch}' : deviceName.trim();
      final device = Device(name, meshDeviceType);
      device.label = 'BLE Mesh';
      device.additionalInfo ??= {};
      device.additionalInfo!['gateway'] = true;
      final saved = await _tb.tbClient.getDeviceService().saveDevice(device);
      final deviceId = saved.id?.id;
      if (deviceId == null) return null;

      final assetId = AssetId(meshNetworkAssetId);
      final devId = DeviceId(deviceId);
      final relation = EntityRelation(
        from: assetId,
        to: devId,
        type: 'Contains',
        typeGroup: RelationTypeGroup.COMMON,
      );
      await _tb.tbClient.getEntityRelationService().saveRelation(relation);

      final attrs = <String, dynamic>{
        MeshDeviceAttrKeys.deviceName: name,
        MeshDeviceAttrKeys.meshNetworkAssetId: meshNetworkAssetId,
        MeshDeviceAttrKeys.commissionedAt: DateTime.now().millisecondsSinceEpoch,
        ...details,
      };
      await _tb.tbClient.getAttributeService().saveEntityAttributesV1(
            devId,
            _attrScope,
            attrs,
          );
      return deviceId;
    } catch (_) {
      return null;
    }
  }

  /// Gets the current gateway unicast address for the mesh network asset (if set).
  Future<int?> getGatewayUnicast(String assetIdStr) async {
    final attrs = await getMeshNetworkAttributes(assetIdStr);
    final v = attrs[MeshNetworkAttrKeys.gatewayUnicastAddress];
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// Removes the gateway for this mesh network: clears asset gatewayUnicastAddress, sets the gateway device's isGateway attribute and additionalInfo.gateway to false.
  Future<bool> clearGateway(String assetIdStr) async {
    if (!_tb.isAuthenticated) return false;
    try {
      final oldUnicast = await getGatewayUnicast(assetIdStr);
      final assetId = AssetId(assetIdStr);
      await _tb.tbClient.getAttributeService().saveEntityAttributesV1(
            assetId,
            _attrScope,
            <String, dynamic>{MeshNetworkAttrKeys.gatewayUnicastAddress: null},
          );
      if (oldUnicast != null) {
        try {
          final relations = await _tb.tbClient.getEntityRelationService().findByFrom(
                assetId,
                relationType: 'Contains',
                relationTypeGroup: RelationTypeGroup.COMMON,
              );
          final attributeService = _tb.tbClient.getAttributeService();
          for (final rel in relations) {
            final toId = rel.to?.id;
            if (toId == null) continue;
            final devId = DeviceId(toId);
            final attrs = await attributeService.getAttributesByScope(
                  devId,
                  _attrScope,
                  [MeshDeviceAttrKeys.unicastAddress],
                );
            int? deviceUnicast;
            for (final attr in attrs) {
              if (attr.getKey() == MeshDeviceAttrKeys.unicastAddress && attr.getValue() != null) {
                final v = attr.getValue();
                if (v is int) deviceUnicast = v;
                else if (v is num) deviceUnicast = v.toInt();
                else deviceUnicast = int.tryParse(v.toString());
                break;
              }
            }
            if (deviceUnicast == oldUnicast) {
              await attributeService.saveEntityAttributesV1(
                    devId,
                    _attrScope,
                    <String, dynamic>{MeshDeviceAttrKeys.isGateway: false},
                  );
              break;
            }
          }
        } catch (_) {}
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Sets the gateway for this mesh network. Removes any existing gateway first, then sets the new one.
  /// Updates both: (1) asset attribute gatewayUnicastAddress, (2) each device's isGateway attribute in ThingsBoard.
  Future<bool> setGateway(String assetIdStr, int unicastAddress) async {
    if (!_tb.isAuthenticated) return false;
    try {
      // 1) Get old gateway unicast before clearing
      final oldGatewayUnicast = await getGatewayUnicast(assetIdStr);
      final assetId = AssetId(assetIdStr);
      final now = DateTime.now().millisecondsSinceEpoch;
      await _tb.tbClient.getAttributeService().saveEntityAttributesV1(
            assetId,
            _attrScope,
            <String, dynamic>{
              MeshNetworkAttrKeys.gatewayUnicastAddress: unicastAddress,
              MeshNetworkAttrKeys.lastModified: now,
            },
          );

      // 3) Update device attributes in ThingsBoard: set isGateway false on old gateway device, true on new gateway device
      final attributeService = _tb.tbClient.getAttributeService();
      final relations = await _tb.tbClient.getEntityRelationService().findByFrom(
            AssetId(assetIdStr),
            relationType: 'Contains',
            relationTypeGroup: RelationTypeGroup.COMMON,
          );

      for (final rel in relations) {
        final toId = rel.to;
        if (toId == null) continue;
        final deviceIdStr = toId.id;
        if (deviceIdStr == null) continue;

        try {
          final devId = DeviceId(deviceIdStr);
          final deviceAttrs = await attributeService.getAttributesByScope(
                devId,
                _attrScope,
                [MeshDeviceAttrKeys.unicastAddress],
              );
          int? deviceUnicast;
          for (final attr in deviceAttrs) {
            final key = attr.getKey();
            final val = attr.getValue();
            if (key == MeshDeviceAttrKeys.unicastAddress && val != null) {
              if (val is int) {
                deviceUnicast = val;
              } else if (val is num) {
                deviceUnicast = val.toInt();
              } else {
                deviceUnicast = int.tryParse(val.toString());
              }
              break;
            }
          }

          if (deviceUnicast == null) continue;

          final isNewGateway = deviceUnicast == unicastAddress;
          final isOldGateway = oldGatewayUnicast != null && deviceUnicast == oldGatewayUnicast;

          if (isNewGateway || isOldGateway) {
            await attributeService.saveEntityAttributesV1(
                  devId,
                  _attrScope,
                  <String, dynamic>{MeshDeviceAttrKeys.isGateway: isNewGateway},
                );
            final device = await _tb.tbClient.getDeviceService().getDevice(deviceIdStr);
            if (device != null) {
              device.additionalInfo ??= {};
              device.additionalInfo!['gateway'] = isNewGateway;
              await _tb.tbClient.getDeviceService().saveDevice(device);
            }
          }
        } catch (_) {
          // Skip devices that fail to update
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetches devices related to this mesh network asset with unicast for each device.
  /// Returns list of maps: id, name, label (optional), unicast (int), isGateway (bool). Devices without unicast are skipped.
  Future<List<Map<String, dynamic>>> getDevicesWithUnicastRelatedToAsset(String assetIdStr) async {
    final list = <Map<String, dynamic>>[];
    if (!_tb.isAuthenticated) return list;
    try {
      final gatewayUnicast = await getGatewayUnicast(assetIdStr);
      final assetId = AssetId(assetIdStr);
      final relations = await _tb.tbClient.getEntityRelationService().findByFrom(
            assetId,
            relationType: 'Contains',
            relationTypeGroup: RelationTypeGroup.COMMON,
          );
      final deviceService = _tb.tbClient.getDeviceService();
      final attributeService = _tb.tbClient.getAttributeService();
      for (final rel in relations) {
        final toId = rel.to;
        if (toId == null) continue;
        final idStr = toId.id;
        if (idStr == null) continue;
        try {
          final device = await deviceService.getDevice(idStr);
          final deviceAttrs = await attributeService.getAttributesByScope(
               EntityId.fromTypeAndUuid(EntityType.DEVICE, idStr),
                _attrScope,
                [MeshDeviceAttrKeys.unicastAddress, MeshDeviceAttrKeys.isGateway],
              );
          int? unicast;
          bool? isGatewayFromDevice;
          for (final attr in deviceAttrs) {
            final key = attr.getKey();
            final val = attr.getValue();
            if (key == MeshDeviceAttrKeys.unicastAddress && val != null) {
              if (val is int) {
                unicast = val;
              } else if (val is num) {
                unicast = val.toInt();
              } else {
                unicast = int.tryParse(val.toString());
              }
            } else if (key == MeshDeviceAttrKeys.isGateway && val != null) {
              isGatewayFromDevice = val == true || val == 1 || (val is String && (val == 'true' || val == '1'));
            }
          }
          if (unicast == null) continue;
          final isGateway = isGatewayFromDevice ?? (gatewayUnicast != null && unicast == gatewayUnicast);
          list.add({
            'id': idStr,
            'name': device?.name ?? 'Device',
            if (device?.label != null && device!.label!.isNotEmpty) 'label': device.label!,
            'unicast': unicast,
            'isGateway': isGateway,
          });
        } catch (e) {
          print(e);
        }
      }
    } catch (e) {
      print(e);
    }
    return list;
  }

  /// Fetches devices related to this mesh network asset (Asset -> Contains -> Device).
  /// Returns a list of maps with 'id' and 'name' (and optionally 'label') for each device.
  Future<List<Map<String, String>>> getDevicesRelatedToAsset(String assetIdStr) async {
    final list = <Map<String, String>>[];
    if (!_tb.isAuthenticated) return list;
    try {
      final assetId = AssetId(assetIdStr);
      final relations = await _tb.tbClient.getEntityRelationService().findByFrom(
            assetId,
            relationType: 'Contains',
            relationTypeGroup: RelationTypeGroup.COMMON,
          );
      final deviceService = _tb.tbClient.getDeviceService();
      for (final rel in relations) {
        final toId = rel.to;
        if (toId == null) continue;
        // Only devices (entityType is typically 'DEVICE')
        final idStr = toId.id;
        if (idStr == null) continue;
        try {
          final devId = DeviceId(idStr);
          final device = await deviceService.getDevice(devId as String);
          list.add({
            'id': idStr,
            'name': device?.name ?? 'Device',
            if (device?.label != null && device!.label!.isNotEmpty) 'label': device.label!,
          });
        } catch (_) {
          list.add({'id': idStr, 'name': 'Device $idStr'});
        }
      }
    } catch (_) {}
    return list;
  }

  /// Returns the ThingsBoard device access token for the device with the given unicast in this asset, or null.
  Future<String?> getDeviceAccessToken(String assetIdStr, int unicastAddress) async {
    if (!_tb.isAuthenticated) return null;
    try {
      final assetId = AssetId(assetIdStr);
      final relations = await _tb.tbClient.getEntityRelationService().findByFrom(
            assetId,
            relationType: 'Contains',
            relationTypeGroup: RelationTypeGroup.COMMON,
          );
      final attributeService = _tb.tbClient.getAttributeService();
      final deviceService = _tb.tbClient.getDeviceService();
      for (final rel in relations) {
        final toId = rel.to;
        if (toId == null) continue;
        final deviceIdStr = toId.id;
        if (deviceIdStr == null) continue;
        try {
          final devId = DeviceId(deviceIdStr);
          final deviceAttrs = await attributeService.getAttributesByScope(
                devId,
                _attrScope,
                [MeshDeviceAttrKeys.unicastAddress],
              );
          int? deviceUnicast;
          for (final attr in deviceAttrs) {
            final key = attr.getKey();
            final val = attr.getValue();
            if (key == MeshDeviceAttrKeys.unicastAddress && val != null) {
              if (val is int) {
                deviceUnicast = val;
              } else if (val is num) {
                deviceUnicast = val.toInt();
              } else {
                deviceUnicast = int.tryParse(val.toString());
              }
              break;
            }
          }
          if (deviceUnicast != unicastAddress) continue;
          final creds = await deviceService.getDeviceCredentialsByDeviceId(deviceIdStr);
          if (creds != null && creds.credentialsId != null && creds.credentialsId!.isNotEmpty) {
            return creds.credentialsId;
          }
          return null;
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// Returns the ThingsBoard device name (e.g. MAC) for the device with the given unicast in this asset, or null.
  Future<String?> getDeviceNameByUnicast(String assetIdStr, int unicastAddress) async {
    if (!_tb.isAuthenticated) return null;
    try {
      final assetId = AssetId(assetIdStr);
      final relations = await _tb.tbClient.getEntityRelationService().findByFrom(
            assetId,
            relationType: 'Contains',
            relationTypeGroup: RelationTypeGroup.COMMON,
          );
      final attributeService = _tb.tbClient.getAttributeService();
      final deviceService = _tb.tbClient.getDeviceService();
      for (final rel in relations) {
        final toId = rel.to;
        if (toId == null) continue;
        final deviceIdStr = toId.id;
        if (deviceIdStr == null) continue;
        try {
          final devId = DeviceId(deviceIdStr);
          final deviceAttrs = await attributeService.getAttributesByScope(
                devId,
                _attrScope,
                [MeshDeviceAttrKeys.unicastAddress, MeshDeviceAttrKeys.deviceName, MeshDeviceAttrKeys.macAddress],
              );
          int? deviceUnicast;
          for (final attr in deviceAttrs) {
            final key = attr.getKey();
            final val = attr.getValue();
            if (key == MeshDeviceAttrKeys.unicastAddress && val != null) {
              if (val is int) {
                deviceUnicast = val;
              } else if (val is num) {
                deviceUnicast = val.toInt();
              } else {
                deviceUnicast = int.tryParse(val.toString());
              }
              break;
            }
          }
          if (deviceUnicast != unicastAddress) continue;
          for (final attr in deviceAttrs) {
            final key = attr.getKey();
            final val = attr.getValue();
            if (val != null && (key == MeshDeviceAttrKeys.macAddress || key == MeshDeviceAttrKeys.deviceName)) {
              final s = val.toString().trim();
              if (s.isNotEmpty) return s;
            }
          }
          final device = await deviceService.getDevice(devId as String);
          return device?.name;
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// Returns asset id as string for navigation/selection.
  String? assetIdToString(AssetId? id) {
    if (id == null) return null;
    return id.id;
  }
}
