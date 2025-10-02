import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/Comman_Widget/custom_snackbar.dart';
import 'package:leafybot_flutter_app/screens/main_screen.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';
import '../mesh/mesh_scan_and_provisioning.dart';
import 'mesh_controller.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class ProvisionedDeviceController extends GetxController {
  final meshNetwork = Rxn<IMeshNetwork>();
  final nodes = <ProvisionedMeshNode>[].obs;
  ProvisionedMeshNode? selectedNode;
  late final MeshManagerApi _meshManagerApi;
  StreamSubscription<IMeshNetwork?>? _updateSub;
  StreamSubscription<IMeshNetwork?>? _importSub;
  StreamSubscription<IMeshNetwork?>? _loadSub;
  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
  final meshController = Get.find<MeshController>();
  final isScanning = false.obs;
  final password_controller = TextEditingController();
  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();
  var wifiList = <String>[
    "Nothing",
    "Airtel_NTPL",
    "Office_WiFi",
    "Cafe_Free_WiFi",
    "Neighbor_WiFi",
  ].obs;
  RxString selectedWifi = "".obs;
  final isWifiProvisioning = false.obs;
  final wifiConnectionFailed = false.obs;
  final wifistatusText = "Connecting...".obs;

  Future<void> loadMeshNetwork() async {
    isScanning.value = true;
    _meshManagerApi = meshController.nordicNrfMesh.meshManagerApi;
    meshNetwork.value = _meshManagerApi.meshNetwork;

    void _update(IMeshNetwork? network) async {
      meshNetwork.value = network;
      await loadNodes();
    }

    _updateSub = _meshManagerApi.onNetworkUpdated.listen(_update);
    _importSub = _meshManagerApi.onNetworkImported.listen(_update);
    _loadSub = _meshManagerApi.onNetworkLoaded.listen(_update);
    await _meshManagerApi.loadMeshNetwork();
    isScanning.value = false;
  }

  Future<void> loadNodes() async {
    if (meshNetwork.value == null) return;

    final loadedNodes = await meshNetwork.value!.nodes;

    nodes.assignAll(loadedNodes);
  }

  Future<void> scanWifi() async {}
  Future<void> connectWithNode(DiscoveredDevice device, mesh_optionn) async {
    isWifiProvisioning.value = true;
    wifiConnectionFailed.value = false;

    try {
      if (mesh_optionn == 1) {
        meshController.bleMeshManager.callbacks =
            DoozProvisionedBleMeshManagerCallbacks(
              _meshManagerApi,
              meshController.bleMeshManager,
            );
        await meshController.bleMeshManager.disconnect();

        await meshController.bleMeshManager.connect(
          device,
          connectionTimeout: const Duration(seconds: 10),
        );
        await meshProvisioning(device, mesh_optionn);
      } else {
        await flutterReactiveBle.connectToDevice(
          id: device.id,
          connectionTimeout: Duration(seconds: 10),
        );
        await wifiProvisioning(device, mesh_optionn);
      }
    } catch (e, st) {
      wifiConnectionFailed.value = true;
      debugPrint("connectWithNode error: $e\n$st");
    } finally {
      isWifiProvisioning.value = false;
    }
  }

  Future<void> wifiProvisioning(DiscoveredDevice device, mesh_optionn) async {
    try {
      print("✅ Connected! Discovering services...");
      final services = await flutterReactiveBle.discoverServices(device.id);
      // 1. Print all services
      for (var s in services) {
        print("Service: ${s.serviceId}");
      }
      var customService;
      if (Platform.isIOS) {
        // 2. Find your custom service (0x00FF)
        customService = services.firstWhere(
          (s) => s.serviceId.toString() == "00ff",
        );
      } else if (Platform.isAndroid) {
        customService = services.firstWhere(
          (s) =>
              s.serviceId.toString() == "000000ff-0000-1000-8000-00805f9b34fb",
        );
      }
      if (customService == null) {
        throw Exception("Custom service not found");
      }
      print("Found Custom Service: ${customService.serviceId}");

      // 3. Iterate characteristics
      for (var c in customService.characteristics) {
        final qChar = QualifiedCharacteristic(
          deviceId: device.id,
          serviceId: c.serviceId,
          characteristicId: c.characteristicId,
        );
        if (c.characteristicId.toString().toLowerCase().contains("ff03")) {
          Map<String, dynamic> payloadMap = {};
          if (mesh_optionn == 1) {
            final devicesJson = await _syncProvisionedDevices();
            payloadMap = {
              "config": {
                "ssid": selectedWifi.value,
                "password": password_controller.text,
                "isgateway": true, // adjust as needed
                "network_info": devicesJson,
                "type":1
              },
            };
          } else {
            payloadMap = {
              "config": {
                "ssid": selectedWifi.value,
                "password": password_controller.text,
                "type":2
              },
            };
          }
          final payloadJson = jsonEncode(payloadMap);
          final payloadBytes = utf8.encode(payloadJson).toList();

          await flutterReactiveBle.writeCharacteristicWithResponse(
            qChar,
            value: payloadBytes,
          );
          wifistatusText.value = "Connected to";
          await Future.delayed(Duration(seconds: 7));
          Get.offAll(MainScreen());
        }
      }
    } catch (e) {
      wifiConnectionFailed.value = true;
      print("❌ Service discovery or provisioning failed: $e");
      AppSnackBar.show("error", "WiFi provisioning failed: $e");
    } finally {
      await meshController.bleMeshManager.disconnect();
      wifiConnectionFailed.value = false;
    }
  }

  Future<void> meshProvisioning(DiscoveredDevice device, mesh_optionn) async {
    try {
      final elements = await selectedNode!.elements;
      const groupAddress = 0xC000;

      for (final element in elements) {
        debugPrint("Processing element ${element.address}");

        for (final model in element.models) {
          // Ensure appKey binding
          if (model.boundAppKey.isEmpty &&
              !(element == elements.first && model == element.models.first)) {
            final unicast = await selectedNode?.unicastAddress;
            if (unicast != null) {
              await _meshManagerApi.sendConfigModelAppBind(
                unicast,
                element.address,
                model.modelId,
              );
              debugPrint("AppKey bound to model ${model.modelId}");
            }
          }

          // Add subscription for specific model
          if (model.modelId == 0x1102) {
            await _meshManagerApi.sendConfigModelSubscriptionAdd(
              element.address,
              groupAddress,
              model.modelId,
            );
            debugPrint(
              "Subscribed model ${model.modelId} to group $groupAddress",
            );
          }
          await Future.delayed(Duration(seconds: 2));
          await wifiProvisioning(device, mesh_optionn);
        }
      }
    } catch (e, st) {
      wifiConnectionFailed.value = true;
      debugPrint("wifiProvisioning error: $e\n$st");
      AppSnackBar.show("error", "WiFi provisioning failed: $e");
    } finally {
      isWifiProvisioning.value = false;
    }
  }

  Future<String> _syncProvisionedDevices() async {
    if (nodes.isEmpty) {
      isWifiProvisioning.value = false;
      debugPrint("No provisioned devices found.");
      return jsonEncode({}); // Return empty JSON object if no devices
    }

    final Map<String, String> deviceMap = {};

    for (var node in nodes) {
      final int address = await node.unicastAddress;
      final String shortAddress = address.toRadixString(16).padLeft(4, '0');
      deviceMap[shortAddress] = node.uuid;
    }

    final jsonString = jsonEncode(deviceMap);
    debugPrint("Provisioned Devices JSON:\n$jsonString");

    return jsonString; // Return JSON string instead of copying
  }

  @override
  void onClose() {
    _updateSub?.cancel();
    _importSub?.cancel();
    _loadSub?.cancel();
    super.onClose();
  }
}
