import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:ntpl_ble_mesh_demo/Comman_Widget/custom_snackbar.dart';
import 'package:ntpl_ble_mesh_demo/mesh/provisioned_devices_page.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';
import '../mesh/mesh_scan_and_provisioning.dart';
import 'mesh_controller.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class ProvisionedDeviceController extends GetxController {
  final meshNetwork = Rxn<IMeshNetwork>();
  final nodes = <ProvisionedMeshNode>[].obs;
  ProvisionedMeshNode? selectedNode;
  StreamSubscription<IMeshNetwork?>? _updateSub;
  StreamSubscription<IMeshNetwork?>? _importSub;
  StreamSubscription<IMeshNetwork?>? _loadSub;
  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
  final meshController = Get.find<MeshController>();
  final isScanning = false.obs;
  final password_controller = TextEditingController();
  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();
  var wifiList = <String>[].obs;
  RxString selectedWifi = "".obs;
  final isWifiProvisioning = false.obs;
  final wifiConnectionFailed = false.obs;
  final wifistatusText = "Connecting...".obs;


  Future<void> loadMeshNetwork() async {
    isScanning.value = true;
    meshNetwork.value =  meshController.meshManagerApi.meshNetwork;

    void _update(IMeshNetwork? network) async {
      meshNetwork.value = network;
      await loadNodes();
    }

    _updateSub =  meshController.meshManagerApi.onNetworkUpdated.listen(_update);
    _importSub =  meshController.meshManagerApi.onNetworkImported.listen(_update);
    _loadSub =  meshController.meshManagerApi.onNetworkLoaded.listen(_update);
    await  meshController.meshManagerApi.loadMeshNetwork();
    isScanning.value = false;
  }

  Future<void> loadNodes() async {
    if (meshNetwork.value == null) return;

    final loadedNodes = await meshNetwork.value!.nodes;

    nodes.assignAll(loadedNodes);
  }

  Future<void> scanWifiList(String deviceName) async {
    if (isScanning.value == false) {
      isScanning.value = true;
      wifiList.clear();
      StreamSubscription<ConnectionStateUpdate>? connection;
      StreamSubscription<DiscoveredDevice>? scanSub;
      BleStatus status;
      try {
        try{
        // Wait up to 5 seconds for BLE to become ready
        status = await flutterReactiveBle.statusStream
            .firstWhere((s) => s != BleStatus.unknown)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        // Timeout or stream error
        status = BleStatus.unknown;
      }

      if (status != BleStatus.ready) {
        AppSnackBar.show("error", "Please enable Bluetooth and try again.");
        print("⚠️ BLE not ready: $status");
        return;
      }

        print("✅ BLE ready, starting scan...");
        scanSub = flutterReactiveBle
            .scanForDevices(withServices: [], scanMode: ScanMode.balanced)
            .listen(
              (device) async {
            try {
              print("Extracted MAC: ${device.name}");
              if (device.name.toUpperCase() == deviceName.toUpperCase()) {
                print("✅ Found target device, stopping scan...");
                await scanSub?.cancel(); // stop scanning immediately
                scanSub = null;
                connection = flutterReactiveBle
                    .connectToDevice(
                  id: device.id,
                  connectionTimeout: const Duration(seconds: 10),
                )
                    .listen((connectionState) async {
                  switch (connectionState.connectionState) {
                    case DeviceConnectionState.connecting:
                      print("⏳ Connecting...");
                      break;

                    case DeviceConnectionState.connected:
                      print("✅ Connected! Discovering services...");
                      await Future.delayed(const Duration(milliseconds: 300));

                      try {
                        final services = await flutterReactiveBle.discoverServices(
                          device.id,
                        );

                        // Print all services
                        for (var s in services) {
                          print("Service: ${s.serviceId}");
                        }

                        DiscoveredService? customService;

                        try {
                          customService = services.firstWhere(
                                (s) => Platform.isIOS
                                ? s.serviceId.toString().toLowerCase() == "00ff"
                                : s.serviceId.toString().toLowerCase() ==
                                "000000ff-0000-1000-8000-00805f9b34fb",
                          );
                        } catch (e) {
                          final msg = "Custom service not found!";
                          print("❌ $msg");
                          AppSnackBar.show("error", msg);
                          return; // exit if not found
                        }
                        print("Found Custom Service: ${customService.serviceId}");

                        // Iterate characteristics
                        for (var c in customService.characteristics) {
                          if (c.characteristicId.toString().toLowerCase() ==
                              "0000ff02-0000-1000-8000-00805f9b34fb"||c.characteristicId.toString().toLowerCase() ==
                              "ff02") {
                            final qChar = QualifiedCharacteristic(
                              deviceId: device.id,
                              serviceId: c.serviceId,
                              characteristicId: c.characteristicId,
                            );

                            List<int> wifiData = [];
                            bool done = false;
                            while (!done) {
                              try {
                                final value = await flutterReactiveBle
                                    .readCharacteristic(qChar).timeout(Duration(seconds: 5));
                                if (value.isEmpty) {
                                  done = true;
                                  break;
                                }

                                int remaining = value[0];
                                wifiData.addAll(value.sublist(1));

                                if (remaining == 0) done = true;

                                await Future.delayed(
                                  const Duration(milliseconds: 100),
                                );
                              } catch (e) {
                                final msg = "Error reading characteristic: $e";
                                print("❌ $msg");
                                AppSnackBar.show("error", msg);
                                done = true;
                              }
                            }

                            // Convert to string (strip first/last byte if present; guard against empty/short data)
                            String wifiString = '';
                            if (wifiData.length > 2) {
                              wifiString = String.fromCharCodes(
                                wifiData.sublist(1, wifiData.length - 1),
                              );
                            } else if (wifiData.isNotEmpty) {
                              wifiString = String.fromCharCodes(wifiData);
                            }

                            print("Full Wi-Fi string:\n$wifiString");

                            // Split into SSIDs
                            wifiList.value = wifiString.isEmpty ? <String>[] : wifiString.split(',');
                            isScanning.value = false;
                            await connection?.cancel();
                          }
                        }
                      } catch (e) {
                        final msg = "Service discovery failed: $e";
                        print("❌ $msg");
                        AppSnackBar.show("error", msg);
                      }

                      break;

                    case DeviceConnectionState.disconnected:
                      print("❌ Disconnected");
                      isScanning.value = false;
                      await connection?.cancel();
                      break;

                    default:
                      break;
                  }
                });
              }
            } catch (e, st) {
              debugPrint("Error processing device: $e\n$st");
            }
          },
          onError: (err) {
            debugPrint("BLE scan error: $err");
          },
        );
        await Future.delayed(const Duration(seconds: 10));
      } catch (e) {
        final msg = "Device '$deviceName' not found!";
        print("❌ $msg");
        AppSnackBar.show("error", msg);
      }
      finally{
        await scanSub?.cancel();
        isScanning.value = false;
        print("-----------Stop Scanning------------");
      }
    }
  }

  Future<void> connectWithNode(String deviceName, deviceNetworkTypeId) async {
    isWifiProvisioning.value = true;
    wifiConnectionFailed.value = false;
    DiscoveredDevice? selectedDevice;

    StreamSubscription<DiscoveredDevice>? subscription;

    try {
      if (deviceNetworkTypeId == 1) {
        subscription = meshController.nordicNrfMesh.scanForProxy().listen(
          (device) {
            if (device.name == deviceName) {
              selectedDevice = device;
            }
          },
          onError: (err) {
            debugPrint("Scan error: $err");
          },
        );
      } else {
        subscription = flutterReactiveBle
            .scanForDevices(withServices: [], scanMode: ScanMode.balanced)
            .listen(
              (device) {
                if (device.name == deviceName) {
                  selectedDevice = device;
                }
              },
              onError: (err) {
                debugPrint("BLE scan error: $err");
              },
            );
      }

      // Wait a few seconds for devices
      await Future.delayed(const Duration(seconds: 5));
      await subscription.cancel();
      if (selectedDevice == null) {
        throw "Device with ID $deviceName not found during scan.";
      }
      if (deviceNetworkTypeId == 1) {
        meshController.bleMeshManager.callbacks =
            DoozProvisionedBleMeshManagerCallbacks(
              meshController.meshManagerApi,
              meshController.bleMeshManager,
            );
        await meshController.bleMeshManager.disconnect();

        await meshController.bleMeshManager.connect(
          selectedDevice!,
          connectionTimeout: const Duration(seconds: 10),
        );
        await meshProvisioning(selectedDevice!, deviceNetworkTypeId);
        await wifiProvisioning(selectedDevice!, deviceNetworkTypeId);
      } else {
        // --- Non-mesh path ---
        print("Start Bluetooth connection");

        // listen to connection state
        flutterReactiveBle
            .connectToDevice(
              id: selectedDevice!.id,
              connectionTimeout: const Duration(seconds: 10),
            )
            .listen((connectionState) async {
              switch (connectionState.connectionState) {
                case DeviceConnectionState.connecting:
                  print("⏳ Connecting...");
                  break;
                case DeviceConnectionState.connected:
                  print("✅ Connected! Discovering services...");
                  await Future.delayed(const Duration(milliseconds: 300));
                  await wifiProvisioning(selectedDevice!, deviceNetworkTypeId);
                  break;
                case DeviceConnectionState.disconnected:
                  print("❌ Disconnected");
                  break;

                default:
                  break;
              }
            });
      }
    } catch (e, st) {
      wifiConnectionFailed.value = true;
      debugPrint("connectWithNode error: $e\n$st");
    }
  }

  Future<void> wifiProvisioning(DiscoveredDevice device, deviceNetworkTypeId) async {
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
        if ((Platform.isAndroid&&c.characteristicId.toString().toLowerCase() ==
            "0000ff03-0000-1000-8000-00805f9b34fb")||(Platform.isIOS&&c.characteristicId.toString().toLowerCase() ==
            "ff03"))  {
          Map<String, dynamic> payloadMap = {};
          if (deviceNetworkTypeId == 1) {
            payloadMap = {
              "config": {
                "ssid": selectedWifi.value,
                "password": password_controller.text,
                "isgateway": true, // adjust as needed
                "type": 1,
              },
            };
          } else {
            payloadMap = {
              "config": {
                "ssid": selectedWifi.value,
                "password": password_controller.text,
                "type": 2,
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
          if(deviceNetworkTypeId==1){
          Get.offAll(ProvisionedDevicesPage());}
          else{
            Get.offAll(ProvisionedDevicesPage());
          }
        }
      }
    } catch (e) {
      wifiConnectionFailed.value = true;
      print("❌ Service discovery or provisioning failed: $e");
      password_controller.clear();
    } finally {
      await meshController.bleMeshManager.disconnect();
      isWifiProvisioning.value = false;
    }
  }

  Future<void> meshProvisioning(DiscoveredDevice device, deviceNetworkTypeId) async {
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
              await  meshController.meshManagerApi.sendConfigModelAppBind(
                unicast,
                element.address,
                model.modelId,
              );
              debugPrint("AppKey bound to model ${model.modelId}");
            }
          }

          // Add subscription for specific model
          if (model.modelId == 0x1102) {
            await  meshController.meshManagerApi.sendConfigModelSubscriptionAdd(
              element.address,
              groupAddress,
              model.modelId,
            );
            debugPrint(
              "Subscribed model ${model.modelId} to group $groupAddress",
            );
          }
          await Future.delayed(Duration(seconds: 2));
        }
      }
    } catch (e, st) {
      wifiConnectionFailed.value = true;
      debugPrint("wifiProvisioning error: $e\n$st");
    }
  }

  Future<String> _syncProvisionedDevices() async {
    if (nodes.isEmpty) {
      wifiConnectionFailed.value = true;
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
