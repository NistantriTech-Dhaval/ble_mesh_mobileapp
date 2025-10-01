import 'dart:io';
import 'dart:async';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/Comman_Widget/custom_snackbar.dart';
import 'package:leafybot_flutter_app/screens/device_setup/device_setup_page.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

import '../mesh/mesh_scan_and_provisioning.dart';

class MeshController extends GetxController {
  late final NordicNrfMesh nordicNrfMesh = NordicNrfMesh();
  final meshNetwork = Rxn<IMeshNetwork>();
  final nodes = <ProvisionedMeshNode>[].obs;
  final groups = <GroupData>[].obs;
  final devices = <DiscoveredDevice>[].obs;
  final serviceData = <String, Uuid>{}.obs;
  final isScanning = false.obs;
  final isProvisioning = false.obs;
  final isBluetooth = false.obs;
  late final MeshManagerApi _meshManagerApi;
  StreamSubscription<IMeshNetwork?>? _updateSub;
  StreamSubscription<IMeshNetwork?>? _importSub;
  StreamSubscription<IMeshNetwork?>? _loadSub;
  StreamSubscription? _scanSubscription;

  final statusText = "Provisioning is in process...".obs;
  final bleMeshManager = BleMeshManager();

  @override
  Future<void> onInit() async {
    super.onInit();
    _meshManagerApi = nordicNrfMesh.meshManagerApi;
    meshNetwork.value = _meshManagerApi.meshNetwork;
  }
  Future<void> askPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
      ].request();
    } else if (Platform.isIOS) {
      await [Permission.bluetooth].request();
    }
  }

  Future<void> loadMeshNetwork() async {
    void _update(IMeshNetwork? network) async {
      meshNetwork.value = network;
      await loadNodesAndGroups();
    }

    _updateSub = _meshManagerApi.onNetworkUpdated.listen(_update);
    _importSub = _meshManagerApi.onNetworkImported.listen(_update);
    _loadSub = _meshManagerApi.onNetworkLoaded.listen(_update);
    await _meshManagerApi.loadMeshNetwork();
    final loadedNodes = await meshNetwork.value?.nodes;
    if (loadedNodes!.isNotEmpty) {
      await _meshManagerApi.resetMeshNetwork();
    }
  }

  Future<void> loadNodesAndGroups() async {
    if (meshNetwork.value == null) return;

    final loadedNodes = await meshNetwork.value!.nodes;
    final loadedGroups = await meshNetwork.value!.groups;

    nodes.assignAll(loadedNodes);
    groups.assignAll(loadedGroups);

    // Ensure default group exists
    if (groups.isEmpty) {
      await _meshManagerApi.meshNetwork?.addGroupWithName("DefaultGroup");
      final updatedGroups = await meshNetwork.value!.groups;
      groups.assignAll(updatedGroups);
    }
  }

  Future<void> scanUnprovisioned() async {
    devices.clear();
    serviceData.clear();

    if (isBluetooth.value = true) {
      isScanning.value = true;

      _scanSubscription?.cancel();
      _scanSubscription = nordicNrfMesh.scanForUnprovisionedNodes().listen((
        device,
      ) {
        if (devices.every((d) => d.id != device.id)) {
          final deviceUuid = Uuid.parse(
            _meshManagerApi.getDeviceUuid(
              device.serviceData[meshProvisioningUuid]?.toList() ?? [],
            ),
          );
          serviceData[device.id] = deviceUuid;
          devices.add(device);
        }
      });

      // Auto stop scan after 10 sec
      Future.delayed(const Duration(seconds: 10), stopScan);
    }
  }

  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    isScanning.value = false;
  }

  Future<void> toggleBluetooth(bool enable, BuildContext context) async {
    if (enable) {
      if (Platform.isAndroid) {
        try {
          await FlutterBluePlus.turnOn(); // Android: request to enable Bluetooth
        } catch (e) {
          AppSnackBar.show("info", "Please turn ON Bluetooth");
        }
      } else if (Platform.isIOS) {
       // await AppSettings.openAppSettings(type:AppSettingsType.bluetooth,asAnotherTask: true);
      }
    }else{
    // await AppSettings.openAppSettings(type:AppSettingsType.bluetooth,asAnotherTask: true);
    }
  }

  void _subscribeToProvisioning(ProvisioningEvent provisioningEvent) {
    // Background logic: listen to streams
    provisioningEvent.onProvisioningCapabilities.listen((_) {});
    provisioningEvent.onProvisioning.listen((_) {});
    provisioningEvent.onProvisioningReconnect.listen((_) {});
    provisioningEvent.onConfigCompositionDataStatus.listen((_) {});
    provisioningEvent.onConfigAppKeyStatus.listen((_) {});
  }

  Future<void> provisionDevice(
    DiscoveredDevice device,
    BuildContext context,
  ) async {
    if (isScanning.value) {
      await stopScan();
    }
    if (isProvisioning.value) {
      return;
    }
    isProvisioning.value = true;

    try {
      // Android is sending the mac Adress of the device, but Apple generates
      // an UUID specific by smartphone.

      String deviceUUID;

      if (Platform.isAndroid) {
        deviceUUID = serviceData[device.id].toString();
      } else if (Platform.isIOS) {
        deviceUUID = device.id.toString();
      } else {
        throw UnimplementedError(
          'device uuid on platform : ${Platform.operatingSystem}',
        );
      }
      final provisioningEvent = ProvisioningEvent();

      _subscribeToProvisioning(provisioningEvent);
      final provisionedMeshNodeF = await nordicNrfMesh
          .provisioning(
            _meshManagerApi,
            BleMeshManager(),
            device,
            deviceUUID,
            events: provisioningEvent,
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              print("Getting timeout error");
              AppSnackBar.show("error", "Provisioning failed");
              scanUnprovisioned(); // no need to await here
              isProvisioning.value = false;
              throw TimeoutException("Provisioning timed out");
            },
          );
      try {
        // Wait a bit for proxy advertising
        await Future.delayed(Duration(seconds: 2));

        bleMeshManager.callbacks = DoozProvisionedBleMeshManagerCallbacks(
          _meshManagerApi,
          bleMeshManager,
        );
        await bleMeshManager.connect(device);

        const groupAddress = 0xC000;
        final elements = await provisionedMeshNodeF.elements;

        for (var element in elements) {
          for (var model in element.models) {
            if (model.boundAppKey.isEmpty) {
              final isPrimaryElement = element == elements.first;
              final isFirstModel = model == element.models.first;

              // Skip binding for primary element first model
              if (isPrimaryElement && isFirstModel) continue;

              final unicast = await provisionedMeshNodeF.unicastAddress;
              int sendModelId = model.modelId;

              // If fallback modelId == 1, combine with vendor companyId (example 0x02E5)
              int? companyId;
              if (sendModelId == 1 && Platform.isIOS == true) {
                companyId = 0x02E5; // your vendor company ID
                sendModelId = (companyId << 16) | sendModelId;
              }

              debugPrint('Binding AppKey to model: $sendModelId');
              await _meshManagerApi
                  .sendConfigModelAppBind(unicast, element.address, sendModelId)
                  .timeout(const Duration(seconds: 5));

              await Future.delayed(const Duration(milliseconds: 100));
            }
          }
        }

        // // 2.Publish
        for (final element in elements) {
          for (final model in element.models) {
            final modelId = model.modelId;
            final isSensorModel = modelId == 0x1100;
            if (isSensorModel) {
              debugPrint('Publishing to model: $modelId');
              await _meshManagerApi
                  .sendConfigModelPublicationSet(
                    element.address,
                    groupAddress.toInt(),
                    model.modelId,
                    appKeyIndex: 0,
                    credentialFlag: false,
                    publishTtl: 15,
                    publicationSteps:
                        100, // Publish every 1 step// Step = 100ms => 100ms interval
                    retransmitCount: 0,
                    retransmitIntervalSteps: 0,
                  )
                  .timeout(
                    Duration(seconds: 2),
                    onTimeout: () async {
                      return ConfigModelPublicationStatus(
                        0,
                        0,
                        0,
                        true,
                        0,
                        0,
                        0,
                        0,
                        0,
                        0,
                        true,
                      ); //dummy data return because response not getting from api
                    },
                  );
            }
          }
        }
        await bleMeshManager.disconnect();
        print("Provisioning is Completed");
        statusText.value = "Provisioning is Completed";
        // Wait 2 seconds then navigate
        await Future.delayed(const Duration(seconds: 5));
        // Navigate directly using GetX
        Get.to(DeviceSetupPage());
        isProvisioning.value = false;

        // Future.delayed(const Duration(milliseconds: 500), widget.onGoToControl);
      } catch (e) {
        debugPrint('Provisioning Error: $e');
        AppSnackBar.show("error", "Provisioning failed");
        await scanUnprovisioned();
      }
    } on TimeoutException catch (_) {
      // Optional: handle timeout specifically here
      print("Provisioning timed out - handled in catch");
    } catch (e) {
      debugPrint('Errpr $e');
      AppSnackBar.show("error", "Caught error: $e");
    } finally {
      isProvisioning.value = false;
    }
  }

  @override
  void onClose() {
    _updateSub?.cancel();
    _importSub?.cancel();
    _loadSub?.cancel();
    _scanSubscription?.cancel();
    super.onClose();
  }
}
