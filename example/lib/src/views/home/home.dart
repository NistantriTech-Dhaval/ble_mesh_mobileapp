import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';
import 'package:nordic_nrf_mesh_example/src/widgets/mesh_network_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app.dart';

class Home extends StatefulWidget {
  final NordicNrfMesh nordicNrfMesh;

  const Home({Key? key, required this.nordicNrfMesh}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late IMeshNetwork? _meshNetwork;
  late final MeshManagerApi _meshManagerApi;
  late final StreamSubscription<IMeshNetwork?> onNetworkUpdateSubscription;
  late final StreamSubscription<IMeshNetwork?> onNetworkImportSubscription;
  late final StreamSubscription<IMeshNetwork?> onNetworkLoadingSubscription;

  @override
  void initState() {
    super.initState();
    _meshManagerApi = widget.nordicNrfMesh.meshManagerApi;
    _meshNetwork = _meshManagerApi.meshNetwork;
    onNetworkUpdateSubscription =
        _meshManagerApi.onNetworkUpdated.listen((event) {
      setState(() {
        _meshNetwork = event;
      });
    });
    onNetworkImportSubscription =
        _meshManagerApi.onNetworkImported.listen((event) {
      setState(() {
        _meshNetwork = event;
      });
    });
    onNetworkLoadingSubscription =
        _meshManagerApi.onNetworkLoaded.listen((event) {
      setState(() {
        _meshNetwork = event;
      });
    });
    _meshManagerApi.loadMeshNetwork();
  }

  @override
  void dispose() {
    onNetworkUpdateSubscription.cancel();
    onNetworkLoadingSubscription.cancel();
    onNetworkImportSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ExpansionTile(
            title: const Text('Mesh network'),
            expandedAlignment: Alignment.topLeft,
            children: [
              MeshNetworkDatabaseWidget(nordicNrfMesh: widget.nordicNrfMesh)
            ],
          ),
          const Divider(),
          if (_meshNetwork != null)
            MeshNetworkDataWidget(
              meshNetwork: _meshNetwork!,
              nordicNrfMesh: widget.nordicNrfMesh,
            )
          else
            const Text('No meshNetwork loaded'),
        ],
      ),
    );
  }
}

class MeshNetworkDataWidget extends StatefulWidget {
  final IMeshNetwork meshNetwork;
  final NordicNrfMesh nordicNrfMesh;
  const MeshNetworkDataWidget(
      {Key? key, required this.meshNetwork, required this.nordicNrfMesh})
      : super(key: key);

  @override
  State<MeshNetworkDataWidget> createState() => _MeshNetworkDataWidgetState();
}

class _MeshNetworkDataWidgetState extends State<MeshNetworkDataWidget> {
  List<ProvisionedMeshNode> _nodes = [];
  List<GroupData> _groups = [];
  MeshManagerApi? meshManagerApi;
  IMeshNetwork? meshNetwork;
  final bleMeshManager = BleMeshManager();
  bool isDeviceConnected = false;
  DiscoveredDevice? connectedDevice;
  String? selectedGatewayUUID = "";
  bool isLoading = false;
  SharedPreferences? prefs;
  @override
  void initState() {
    super.initState();
    _loadNetworkData();
    initSharedPrefersne();
  }

  @override
  void didUpdateWidget(covariant MeshNetworkDataWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadNetworkData();
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await bleMeshManager.disconnect().timeout(Duration(seconds: 2));
    bleMeshManager.dispose();
  }

  Future<void> _loadNetworkData() async {
    meshManagerApi = widget.nordicNrfMesh.meshManagerApi;
    meshNetwork = meshManagerApi?.meshNetwork;
    var nodes = await widget.meshNetwork.nodes;
    var groups = await widget.meshNetwork.groups;
    if (groups.isEmpty) {
      await meshManagerApi?.meshNetwork?.addGroupWithName("Test");
      groups = await widget.meshNetwork.groups;
    }
    if (_nodes.isEmpty) {
      await prefs?.remove("selected_gateway");
      setState(() {
        selectedGatewayUUID = "";
      });
    }
    setState(() {
      _nodes = nodes;
      _groups = groups;
    });
  }

  initSharedPrefersne() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedGatewayUUID = prefs?.getString("selected_gateway");
    });
  }

  Future<String> _syncProvisionedDevices() async {
    if (_nodes.isEmpty) {
      debugPrint("No provisioned devices found.");
      return jsonEncode({}); // Return empty JSON object if no devices
    }

    final Map<String, String> deviceMap = {};

    for (var node in _nodes) {
      final int address = await node.unicastAddress;
      final String shortAddress = address.toRadixString(16).padLeft(4, '0');
      deviceMap[shortAddress] = node.uuid;
    }

    final jsonString = jsonEncode(deviceMap);
    debugPrint("Provisioned Devices JSON:\n$jsonString");

    return jsonString; // Return JSON string instead of copying
  }

  @override
  Widget build(BuildContext context) {
    final provisioner = _nodes.isNotEmpty ? _nodes.first : null;
    final otherNodes = _nodes.length > 1 ? _nodes.sublist(1) : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            Container(
              // transparent dark background
              child: const LinearProgressIndicator(),
            ),
          AppBar(
            title: const Text("Ble Mesh Network"),
            actions: [
              if (!isDeviceConnected)
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.network_wifi),
                    label: const Text("Connect to Gateway"),
                    onPressed: toggleConnectionWithProvisionedNode,
                  ),
                )
              else
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.link_off),
                    label: const Text("Disconnect Gateway"),
                    onPressed: disconnectGateway,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ), // spacing to the right
            ],
          ),
          SizedBox(
            height: 20,
          ),
          if (provisioner != null) ...[
            GestureDetector(
              onTap: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Provisioner:',
                      style: Theme.of(context).textTheme.titleSmall),
                  NodeWidget(
                      node: provisioner,
                      meshNetwork: widget.meshNetwork,
                      identifier: 'node-0'),
                ],
              ),
            ),
          ],
          ...otherNodes.asMap().entries.map((entry) {
            final index = entry.key;
            final node = entry.value;

            return Dismissible(
              key: Key('node-${node.uuid}'),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              secondaryBackground: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                if (!isDeviceConnected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please connect the network first')),
                  );
                  return false;
                }

                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Remove Device'),
                    content: const Text(
                        'Are you sure you want to remove this device?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    setState(() {
                      isLoading = true;
                    });

                    final provisionedNode =
                        _nodes.firstWhere((n) => n.uuid == node.uuid);
                    await meshManagerApi
                        ?.deprovision(provisionedNode)
                        .timeout(const Duration(seconds: 40));

                    // 🔁 Remove the item here directly
                    setState(() {
                      otherNodes.removeWhere((n) => n.uuid == node.uuid);
                      _nodes.removeWhere((n) => n.uuid == node.uuid);
                      if (selectedGatewayUUID == node.uuid) {
                        selectedGatewayUUID = null;
                      }
                    });

                    if (selectedGatewayUUID == node.uuid) {
                      await prefs?.remove("selected_gateway");
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Device deprovisioned")),
                    );
                    await disconnectGateway();
                    return true;
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                    return false;
                  } finally {
                    setState(() {
                      isLoading = false;
                    });
                  }
                }

                return false;
              },
              child: ListTile(
                title: FutureBuilder<String>(
                  future: node.name,
                  builder: (context, snapshot) {
                    final name = snapshot.data ?? 'Unknown';
                    return Text('${index + 1}. $name');
                  },
                ),
                subtitle: FutureBuilder<int>(
                  future: node.unicastAddress,
                  builder: (context, snapshot) {
                    final address =
                        snapshot.data?.toRadixString(16).toUpperCase() ??
                            'Unknown';
                    return Text('Unicast Address: $address');
                  },
                ),
                trailing: Switch(
                  value: selectedGatewayUUID == node.uuid,
                  onChanged: (bool isSelected) async {
                    if (!isDeviceConnected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Device is not connected')),
                      );
                      return;
                    }

                    if (isSelected &&
                        selectedGatewayUUID != null &&
                        selectedGatewayUUID != "" &&
                        selectedGatewayUUID != node.uuid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Another device is already selected. Please deselect it first.')),
                      );
                      return;
                    }

                    final elements = await node.elements;
                    const groupAddress = 0xC000;

                    try {
                      setState(() {
                        isLoading = true;
                      });
                      if (!isSelected) {
                        // Unsubscribe all models
                        for (final element in elements) {
                          for (final model in element.models) {
                            if (model.boundAppKey.isNotEmpty) {
                              final id = model.modelId;
                              if (id == 0x1102) {
                                await meshManagerApi
                                    ?.sendConfigModelSubscriptionDelete(
                                  element.address,
                                  groupAddress,
                                  model.modelId,
                                );
                              }
                              if (id == 0x02E50001) {
                                final payloadMap = {
                                  "isgateway": false, // or false
                                };
                                final payloadJson = jsonEncode(payloadMap);
                                final payloadBytes =
                                    utf8.encode(payloadJson).toList();
                                await meshManagerApi?.sendVendorMessage(
                                    address: element.address,
                                    modelName: "VendorModel",
                                    modelId: 0x0001,
                                    companyId: 0x02E5,
                                    opCode: 0xC0,
                                    keyIndex: 0,
                                    parameters: payloadBytes);
                                setState(() {
                                  isDeviceConnected = false;
                                  connectedDevice = null;
                                  isLoading = false;
                                });
                              }
                            }
                          }
                        }
                      } else {
                        for (final element in elements) {
                          print(element);
                          for (final model in element.models) {
                            if (model.boundAppKey.isEmpty &&
                                !(element == elements.first &&
                                    model == element.models.first)) {
                              final unicast = await node.unicastAddress;
                              await meshManagerApi?.sendConfigModelAppBind(
                                unicast,
                                element.address,
                                model.modelId,
                              );
                            }

                            final id = model.modelId;
                            print("Model id $id");
                            if (id == 0x1102) {
                              await meshManagerApi
                                  ?.sendConfigModelSubscriptionAdd(
                                element.address,
                                groupAddress,
                                model.modelId,
                              );
                            }
                            if ((Platform.isIOS == true && id == 0x0001) ||
                                (Platform.isAndroid == true &&
                                    id == 48562177)) {
                              debugPrint(
                                  'Vendor model found — asking for Wi-Fi credentials...');
                              await showDialog(
                                context: context,
                                builder: (_) {
                                  final ssidController = TextEditingController(
                                      text: "Airtel_NTPL");
                                  final passController =
                                      TextEditingController(text: "NTPL#1234");
                                  return AlertDialog(
                                    title: Text("Enter Wi-Fi Credentials"),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: ssidController,
                                          decoration: InputDecoration(
                                              labelText: "SSID"),
                                        ),
                                        TextField(
                                          controller: passController,
                                          decoration: InputDecoration(
                                              labelText: "Password"),
                                          obscureText: true,
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          final devicesJson =
                                              await _syncProvisionedDevices();

                                          final payloadMap = {
                                            "ssid": ssidController.text,
                                            "password": passController.text,
                                            "isgateway": true, // or false
                                            "network_info": devicesJson
                                          };
                                          final payloadJson =
                                              jsonEncode(payloadMap);
                                          final payloadBytes =
                                              utf8.encode(payloadJson).toList();
                                          await meshManagerApi
                                              ?.sendVendorMessage(
                                                  address: element.address,
                                                  modelName: "VendorModel",
                                                  modelId: 0x0001,
                                                  companyId: 0x02E5,
                                                  opCode: 0xC0,
                                                  keyIndex: 0,
                                                  parameters: payloadBytes);
                                          showFullScreenLoading(context);
                                        },
                                        child: Text("Send"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          }
                        }
                      }

                      setState(() {
                        selectedGatewayUUID = isSelected ? node.uuid : null;
                      });
                      await prefs?.setString(
                          "selected_gateway", selectedGatewayUUID ?? "");
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error during subscription: $e')),
                      );
                    } finally {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void showFullScreenLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Disable back button
          child: Scaffold(
            backgroundColor: Colors.black54,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Sending...",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Close after 20 seconds
    Timer(const Duration(seconds: 30), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> toggleConnectionWithProvisionedNode() async {
    setState(() {
      isLoading = true;
    });
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Not connected — scan and connect to best RSSI
    final List<DiscoveredDevice> scannedDevices = [];

    try {
      await checkAndAskPermissions();

      final subscription = widget.nordicNrfMesh.scanForProxy().listen((device) {
        if (scannedDevices.every((d) => d.id != device.id)) {
          scannedDevices.add(device);
        }
      });

      await Future.delayed(const Duration(seconds: 5));
      await subscription.cancel();

      if (scannedDevices.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('No provisioned device found')),
        );
        return;
      }

      // Pick device with strongest RSSI
      final bestDevice = scannedDevices.reduce(
        (a, b) => a.rssi > b.rssi ? a : b,
      );
      bleMeshManager.callbacks = DoozProvisionedBleMeshManagerCallbacks(
          meshManagerApi!, bleMeshManager);
      await bleMeshManager.connect(bestDevice);
      isDeviceConnected = true;
      connectedDevice = bestDevice;
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text('Connected to ${bestDevice.name ?? bestDevice.id}')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> disconnectGateway() async {
    await bleMeshManager.disconnect().timeout(Duration(seconds: 2));

    setState(() {
      isDeviceConnected = false;
      connectedDevice = null;
      isLoading = true;
    });

    bleMeshManager.dispose();
    setState(() {
      isLoading = false;
    });
  }
}

class MeshNetworkDatabaseWidget extends StatelessWidget {
  final NordicNrfMesh nordicNrfMesh;

  const MeshNetworkDatabaseWidget({Key? key, required this.nordicNrfMesh})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    MeshManagerApi? meshManagerApi = nordicNrfMesh.meshManagerApi;
    IMeshNetwork? meshNetwork = meshManagerApi.meshNetwork;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: meshManagerApi.loadMeshNetwork,
          child: const Text('Load MeshNetwork'),
        ),
        TextButton(
          onPressed:
              meshNetwork != null ? meshManagerApi.resetMeshNetwork : null,
          child: const Text('Reset MeshNetwork'),
        ),
      ],
    );
  }
}

class DoozProvisionedBleMeshManagerCallbacks extends BleMeshManagerCallbacks {
  final MeshManagerApi meshManagerApi;
  final BleMeshManager bleMeshManager;

  late StreamSubscription<ConnectionStateUpdate> onDeviceConnectingSubscription;
  late StreamSubscription<ConnectionStateUpdate> onDeviceConnectedSubscription;
  late StreamSubscription<BleManagerCallbacksDiscoveredServices>
      onServicesDiscoveredSubscription;
  late StreamSubscription<DiscoveredDevice> onDeviceReadySubscription;
  late StreamSubscription<BleMeshManagerCallbacksDataReceived>
      onDataReceivedSubscription;
  late StreamSubscription<BleMeshManagerCallbacksDataSent>
      onDataSentSubscription;
  late StreamSubscription<ConnectionStateUpdate>
      onDeviceDisconnectingSubscription;
  late StreamSubscription<ConnectionStateUpdate>
      onDeviceDisconnectedSubscription;
  late StreamSubscription<List<int>> onMeshPduCreatedSubscription;

  DoozProvisionedBleMeshManagerCallbacks(
      this.meshManagerApi, this.bleMeshManager) {
    onDeviceConnectingSubscription = onDeviceConnecting.listen((event) {
      debugPrint('onDeviceConnecting $event');
    });
    onDeviceConnectedSubscription = onDeviceConnected.listen((event) {
      debugPrint('onDeviceConnected $event');
    });

    onServicesDiscoveredSubscription = onServicesDiscovered.listen((event) {
      debugPrint('onServicesDiscovered');
    });

    onDeviceReadySubscription = onDeviceReady.listen((event) async {
      debugPrint('onDeviceReady ${event.id}');
    });

    onDataReceivedSubscription = onDataReceived.listen((event) async {
      debugPrint('onDataReceived ${event.device.id} ${event.pdu} ${event.mtu}');
      await meshManagerApi.handleNotifications(event.mtu, event.pdu);
    });
    onDataSentSubscription = onDataSent.listen((event) async {
      debugPrint('onDataSent ${event.device.id} ${event.pdu} ${event.mtu}');
      await meshManagerApi.handleWriteCallbacks(event.mtu, event.pdu);
    });

    onDeviceDisconnectingSubscription = onDeviceDisconnecting.listen((event) {
      debugPrint('onDeviceDisconnecting $event');
    });
    onDeviceDisconnectedSubscription = onDeviceDisconnected.listen((event) {
      debugPrint('onDeviceDisconnected $event');
    });

    onMeshPduCreatedSubscription =
        meshManagerApi.onMeshPduCreated.listen((event) async {
      debugPrint('Home onMeshPduCreated $event');
      await bleMeshManager.sendPdu(event);
    });
  }

  @override
  Future<void> dispose() => Future.wait([
        onDeviceConnectingSubscription.cancel(),
        onDeviceConnectedSubscription.cancel(),
        onServicesDiscoveredSubscription.cancel(),
        onDeviceReadySubscription.cancel(),
        onDataReceivedSubscription.cancel(),
        onDataSentSubscription.cancel(),
        onDeviceDisconnectingSubscription.cancel(),
        onDeviceDisconnectedSubscription.cancel(),
        onMeshPduCreatedSubscription.cancel(),
        super.dispose(),
      ]);

  @override
  Future<void> sendMtuToMeshManagerApi(int mtu) => meshManagerApi.setMtu(mtu);
}
