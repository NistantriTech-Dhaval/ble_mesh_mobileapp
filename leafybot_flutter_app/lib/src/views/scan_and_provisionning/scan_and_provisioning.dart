import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

import '../../app.dart';
import '../../widgets/device.dart';

class ScanningAndProvisioning extends StatefulWidget {
  final NordicNrfMesh nordicNrfMesh;
  final VoidCallback onGoToControl;

  const ScanningAndProvisioning({
    Key? key,
    required this.nordicNrfMesh,
    required this.onGoToControl,
  }) : super(key: key);

  @override
  State<ScanningAndProvisioning> createState() =>
      _ScanningAndProvisioningState();
}

class _ScanningAndProvisioningState extends State<ScanningAndProvisioning> {
  late MeshManagerApi _meshManagerApi;
  bool isScanning = true;
  StreamSubscription? _scanSubscription;
  bool isProvisioning = false;

  final _serviceData = <String, Uuid>{};
  final _devices = <DiscoveredDevice>{};
  final bleMeshManager = BleMeshManager();

  @override
  void initState() {
    super.initState();
    _meshManagerApi = widget.nordicNrfMesh.meshManagerApi;
    _scanUnprovisionned();
  }

  @override
  void dispose() {
    super.dispose();
    _scanSubscription?.cancel();
    _deinit();
  }

  Future<void> _scanUnprovisionned() async {
    _serviceData.clear();
    setState(() {
      _devices.clear();
    });
    await checkAndAskPermissions();
    _scanSubscription =
        widget.nordicNrfMesh.scanForUnprovisionedNodes().listen((device) async {
      if (_devices.every((d) => d.id != device.id)) {
        final deviceUuid = Uuid.parse(_meshManagerApi.getDeviceUuid(
            device.serviceData[meshProvisioningUuid]?.toList() ?? []));
        debugPrint('deviceUuid: $deviceUuid');
        _serviceData[device.id] = deviceUuid;
        _devices.add(device);
        setState(() {});
      }
    });
    setState(() {
      isScanning = true;
    });
    return Future.delayed(const Duration(seconds: 10), _stopScan);
  }

  Future<void> _stopScan() async {
    await _scanSubscription?.cancel();
    isScanning = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _deinit() async {
    await bleMeshManager.disconnect().timeout(Duration(seconds: 2));
    bleMeshManager.callbacks?.dispose();
    bleMeshManager.dispose();
  }

  Future<void> provisionDevice(DiscoveredDevice device) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (isScanning) {
      await _stopScan();
    }
    if (isProvisioning) {
      return;
    }
    isProvisioning = true;

    try {
      // Android is sending the mac Adress of the device, but Apple generates
      // an UUID specific by smartphone.

      String deviceUUID;

      if (Platform.isAndroid) {
        deviceUUID = _serviceData[device.id].toString();
      } else if (Platform.isIOS) {
        deviceUUID = device.id.toString();
      } else {
        throw UnimplementedError(
            'device uuid on platform : ${Platform.operatingSystem}');
      }
      final provisioningEvent = ProvisioningEvent();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ProvisioningDialog(
            provisioningEvent: provisioningEvent,
            onGoToControl: widget.onGoToControl),
      );
      final provisionedMeshNodeF = await widget.nordicNrfMesh
          .provisioning(
            _meshManagerApi,
            BleMeshManager(),
            device,
            deviceUUID,
            events: provisioningEvent,
          )
          .timeout(const Duration(minutes: 1));
      try {
        // Wait a bit for proxy advertising
        await Future.delayed(Duration(seconds: 2));

        bleMeshManager.callbacks = DoozProvisionedBleMeshManagerCallbacks(
            _meshManagerApi, bleMeshManager);
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
                  .sendConfigModelAppBind(
                    unicast,
                    element.address,
                    sendModelId,
                  )
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
              await _meshManagerApi.sendConfigModelPublicationSet(
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
              );
            }
          }
        }
        Navigator.of(context).pop(); // Close any dialogs

        // 3. Success Feedback
        scaffoldMessenger.showSnackBar(
          const SnackBar(
              content:
                  Text('Provisioning succeeded, redirecting to Home tab...')),
        );

        Future.delayed(const Duration(milliseconds: 500), widget.onGoToControl);
      } catch (e) {
        debugPrint('Provisioning Error: $e');
        Navigator.of(context).pop();
        scaffoldMessenger
            .showSnackBar(const SnackBar(content: Text('Provisioning failed')));
        _scanUnprovisionned();
      }
    } catch (e) {
      debugPrint('Errpr $e');
      Navigator.of(context).pop();
      scaffoldMessenger
          .showSnackBar(SnackBar(content: Text('Caught error: $e')));
    } finally {
      isProvisioning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        if (isScanning) {
          return Future.value();
        }
        return _scanUnprovisionned();
      },
      child: Column(
        children: [
          if (isScanning) const LinearProgressIndicator(),
          if (!isScanning && _devices.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No module found'),
              ),
            ),
          if (_devices.isNotEmpty)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  for (var i = 0; i < _devices.length; i++)
                    Device(
                      key: ValueKey('device-$i'),
                      device: _devices.elementAt(i),
                      onTap: () => provisionDevice(_devices.elementAt(i)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ProvisioningDialog extends StatelessWidget {
  final ProvisioningEvent provisioningEvent;
  final VoidCallback onGoToControl;
  const ProvisioningDialog(
      {Key? key, required this.provisioningEvent, required this.onGoToControl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isCompositionDataDone = false;
    return Center(
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const Text('Steps :'),
                  Column(
                    children: [
                      ProvisioningState(
                        text: 'onProvisioningCapabilities',
                        stream: provisioningEvent.onProvisioningCapabilities
                            .map((event) => true),
                      ),
                      ProvisioningState(
                        text: 'onProvisioning',
                        stream: provisioningEvent.onProvisioning
                            .map((event) => true),
                      ),
                      ProvisioningState(
                        text: 'onProvisioningReconnect',
                        stream: provisioningEvent.onProvisioningReconnect
                            .map((event) => true),
                      ),
                      ProvisioningState(
                        text: 'onConfigCompositionDataStatus',
                        stream: provisioningEvent.onConfigCompositionDataStatus
                            .map((event) {
                          isCompositionDataDone = true;
                          return true;
                        }),
                      ),
                      ProvisioningState(
                        text: 'onConfigAppKeyStatus',
                        stream: provisioningEvent.onConfigAppKeyStatus
                            .map((event) => true)
                            .timeout(Duration(seconds: 30),
                                onTimeout: (sink) async {
                          print('Timeout: onConfigAppKeyStatus');
                          print(
                              "isCompositionDataDone   $isCompositionDataDone");
                          Navigator.of(context).pop();
                          if (isCompositionDataDone == true) {
                            Future.delayed(const Duration(milliseconds: 500),
                                this.onGoToControl);
                          }
                        }),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProvisioningState extends StatelessWidget {
  final Stream<bool> stream;
  final String text;

  const ProvisioningState({Key? key, required this.stream, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      initialData: false,
      stream: stream,
      builder: (context, snapshot) {
        return Row(
          children: [
            Text(text),
            const Spacer(),
            Checkbox(
              value: snapshot.data,
              onChanged: null,
            ),
          ],
        );
      },
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
      debugPrint('onMeshPduCreated $event');
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
