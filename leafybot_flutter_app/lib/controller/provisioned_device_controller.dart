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
  Future<void> connectWithNode() async {
    isWifiProvisioning.value = true;
    wifiConnectionFailed.value = false;
    final List<DiscoveredDevice> scannedDevices = [];

    StreamSubscription<DiscoveredDevice>? subscription;

    try {
      // Start scan
      subscription = meshController.nordicNrfMesh.scanForProxy().listen(
        (device) {
          if (scannedDevices.every((d) => d.id != device.id)) {
            scannedDevices.add(device);
          }
        },
        onError: (err) {
          debugPrint("Scan error: $err");
        },
      );

      // Wait a few seconds for devices
      await Future.delayed(const Duration(seconds: 5));
      await subscription.cancel();

      if (scannedDevices.isEmpty) {
        isWifiProvisioning.value = false;
        throw Exception("No provisioned device found");
      }

      // Pick device with strongest RSSI
      final bestDevice = scannedDevices.reduce(
        (a, b) => a.rssi > b.rssi ? a : b,
      );

      debugPrint(
        "Best device: ${bestDevice.name ?? bestDevice.id} RSSI=${bestDevice.rssi}",
      );

      // Setup callbacks
      meshController.bleMeshManager.callbacks =
          DoozProvisionedBleMeshManagerCallbacks(
            _meshManagerApi,
            meshController.bleMeshManager,
          );

      // Disconnect previous (if any)
      await meshController.bleMeshManager.disconnect();

      await meshController.bleMeshManager.connect(
        bestDevice,
        connectionTimeout: const Duration(seconds: 10),
      );
      // Start provisioning
      await wifiProvisioning();
    } catch (e, st) {
      wifiConnectionFailed.value = true;
      debugPrint("connectWithNode error: $e\n$st");
    } finally {
      await subscription?.cancel();
      isWifiProvisioning.value = false;
    }
  }

  Future<void> wifiProvisioning() async {
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

          // Handle Vendor Model for WiFi provisioning
          final id = model.modelId;
          if ((Platform.isIOS && id == 0x0001) ||
              (Platform.isAndroid && id == 48562177)) {
            debugPrint("Vendor model found — sending WiFi credentials...");

            final devicesJson = await _syncProvisionedDevices();

            final payloadMap = {
              "ssid": selectedWifi.value,
              "password": password_controller.text,
              "isgateway": true, // adjust as needed
              "network_info": devicesJson,
            };

            final payloadJson = jsonEncode(payloadMap);
            final payloadBytes = utf8.encode(payloadJson).toList();
            await _meshManagerApi
                .sendVendorMessage(
                  address: element.address,
                  modelName: "VendorModel",
                  modelId: 0x0001,
                  companyId: 0x02E5,
                  opCode: 0xC0,
                  keyIndex: 0,
                  parameters: payloadBytes,
            );
                // ).timeout(
                //   Duration(seconds: 10),
                //   onTimeout: () async {
                //     return true;
                //   },
                // );
            wifistatusText.value = "Connected to";
            await Future.delayed(Duration(seconds: 5));
            Get.offAll(MainScreen());
          }
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
