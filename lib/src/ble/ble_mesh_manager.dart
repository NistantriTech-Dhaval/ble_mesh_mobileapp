import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';
import 'package:nordic_nrf_mesh/src/constants.dart';
import 'package:retry/retry.dart';

/// {@template ble_mesh_manager}
/// A Singleton that should be used to handle **BLE Mesh** connectivity features.
///
/// It implements the methods to init GATT layer, subscribe to notifications and send PDUs for **BLE Mesh** nodes.
/// Android-only logic (delay after subscribe, proxy segmentation) is guarded with Platform.isAndroid; iOS unchanged.
/// {@endtemplate}
class BleMeshManager<T extends BleMeshManagerCallbacks> extends BleManager<T> {
  static final BleMeshManager _instance = BleMeshManager._(FlutterReactiveBle());

  /// The list of [DiscoveredService] that were discovered during the last connection process
  late List<DiscoveredService> _discoveredServices;

  /// The subscription for data when the connected node is a mesh proxy (ie. already provisioned in a network)
  StreamSubscription<List<int>>? _meshProxyDataOutSubscription;

  /// The subscription for data when the connected node is a free mesh node (ie. waiting to be provisioned in a network)
  StreamSubscription<List<int>>? _meshProvisioningDataOutSubscription;

  BleMeshManager._(FlutterReactiveBle bleInstance) : super(bleInstance);

  /// {@macro ble_mesh_manager}
  factory BleMeshManager() => _instance as BleMeshManager<T>;

  void _log(String msg) => debugPrint('[NordicNrfMesh] $msg');

  /// A method to clear some resources when the device should be disconnected
  void _onDeviceDisconnected() async {
    isProvisioningCompleted = false;
    await _meshProxyDataOutSubscription?.cancel();
    _meshProxyDataOutSubscription = null;
    await _meshProvisioningDataOutSubscription?.cancel();
    _meshProvisioningDataOutSubscription = null;
  }

  @override
  Future<void> disconnect() {
    _onDeviceDisconnected();
    return super.disconnect();
  }

  /// A method to read the connected device's MAC address via [doozCustomServiceUuid]
  ///
  /// _(DooZ specific API)_
  Future<String?> getServiceMacId() async {
    String? macId;
    if (_hasExpectedService(doozCustomServiceUuid)) {
      final service = _discoveredServices.firstWhere((service) => service.serviceId == doozCustomServiceUuid);
      if (_hasExpectedCharacteristicUuid(service, doozCustomCharacteristicUuid)) {
        macId = await getMacId();
      }
    }
    return macId;
  }

  @override
  Future<DiscoveredService?> isRequiredServiceSupported(bool shouldCheckDoozCustomService) async {
    // In the case of a mesh node, the advertised service should be either 0x1827 or 0x1828
    if (Platform.isAndroid) {
      debugPrint('[NordicNrfMesh BLE] STEP: discoverServices() - STUCK? Waiting for GATT service discovery');
    }
    _discoveredServices = await bleInstance.discoverServices(device!.id);
    if (Platform.isAndroid) {
      debugPrint('[NordicNrfMesh BLE] STEP: discoverServices() done. isProvisioningCompleted=$isProvisioningCompleted');
    }
    _log('services $_discoveredServices');
    isProvisioningCompleted = false;
    if (_hasExpectedService(meshProxyUuid)) {
      isProvisioningCompleted = true;
      // check for meshProxy characs
      final service = _discoveredServices.firstWhere((service) => service.serviceId == meshProxyUuid);
      if (_hasExpectedCharacteristicUuid(service, meshProxyDataIn) &&
          _hasExpectedCharacteristicUuid(service, meshProxyDataOut)) {
        // if shouldCheckDoozCustomService is true, will also check for the existence of doozCustomServiceUuid
        // that has been introduced in firmwares v1.1.0 so we can get the mac address even on iOS devices
        if (shouldCheckDoozCustomService) {
          if (_hasExpectedService(doozCustomServiceUuid)) {
            final service = _discoveredServices.firstWhere((service) => service.serviceId == doozCustomServiceUuid);
            if (_hasExpectedCharacteristicUuid(service, doozCustomCharacteristicUuid)) {
              return service;
            }
          }
          throw const BleManagerException(
            BleManagerFailureCode.doozServiceNotFound,
            'plz update the firmware to v1.1.x',
          );
        } else {
          return service;
        }
      }
      return null;
    } else {
      if (_hasExpectedService(meshProvisioningUuid)) {
        final service = _discoveredServices.firstWhere((service) => service.serviceId == meshProvisioningUuid);
        if (_hasExpectedCharacteristicUuid(service, meshProvisioningDataIn) &&
            _hasExpectedCharacteristicUuid(service, meshProvisioningDataOut)) {
          return service;
        }
      }
      return null;
    }
  }

  @override
  Future<void> initGatt() async {
    if (Platform.isAndroid) {
      debugPrint('[NordicNrfMesh BLE] STEP: requestMtu() - STUCK? Waiting for MTU negotiation');
    }
    // request highest MTU (only useful on Android)
    final negotiatedMtu = await bleInstance.requestMtu(deviceId: device!.id, mtu: mtuSizeMax);
    if (Platform.isAndroid) {
      debugPrint('[NordicNrfMesh BLE] STEP: MTU=$negotiatedMtu. Subscribing to provisioning/proxy data out - STUCK? Waiting for subscribe');
    }
    if (Platform.isAndroid) {
      mtuSize = negotiatedMtu - 3;
    } else if (Platform.isIOS) {
      mtuSize = negotiatedMtu -3 ;
    }
    // notify about negociated MTU size
    await callbacks!.sendMtuToMeshManagerApi(mtuSize);
    // subscribe to notifications from the proper BLE service (proxy/provisioning)
    DiscoveredService? discoveredService;
    if (isProvisioningCompleted) {
      discoveredService = _discoveredServices.firstWhere((service) => service.serviceId == meshProxyUuid);
      await _meshProxyDataOutSubscription?.cancel();
      _meshProxyDataOutSubscription =
          _getDataOutSubscription(_getQualifiedCharacteristic(meshProxyDataOut, discoveredService.serviceId));
    } else {
      discoveredService = _discoveredServices.firstWhere((service) => service.serviceId == meshProvisioningUuid);
      await _meshProvisioningDataOutSubscription?.cancel();
      _meshProvisioningDataOutSubscription =
          _getDataOutSubscription(_getQualifiedCharacteristic(meshProvisioningDataOut, discoveredService.serviceId));
    }
    // Android: ensure CCCD 0x0001 (enable notify) is written and acked before we send any PDU.
    // Otherwise the device sees "Client wrote 0x0000" / protocol timeout because we write to Data In before notify is enabled on Data Out.
    if (Platform.isAndroid) {
      debugPrint('[NordicNrfMesh BLE] STEP: wait for notify enable (CCCD 0x0001) before device ready');
      await Future.delayed(const Duration(milliseconds: 400));
    }
    if (Platform.isAndroid) {
      debugPrint('[NordicNrfMesh BLE] STEP: initGatt() done (MTU set, subscribed to data out). Device ready will fire next.');
    }
  }

  bool _hasExpectedService(Uuid serviceUuid) => _discoveredServices.any((service) => service.serviceId == serviceUuid);

  bool _hasExpectedCharacteristicUuid(DiscoveredService discoveredService, Uuid expectedCharacteristicId) =>
      discoveredService.characteristicIds.any((uuid) => uuid == expectedCharacteristicId);

  QualifiedCharacteristic _getQualifiedCharacteristic(Uuid characteristicId, Uuid serviceId) => QualifiedCharacteristic(
        characteristicId: characteristicId,
        serviceId: serviceId,
        deviceId: device!.id,
      );

  StreamSubscription<List<int>> _getDataOutSubscription(QualifiedCharacteristic qCharacteristic) =>
      bleInstance.subscribeToCharacteristic(qCharacteristic).where((data) => data.isNotEmpty == true).listen((data) {
        if (!(callbacks?.onDataReceivedController.isClosed == true) &&
            callbacks!.onDataReceivedController.hasListener) {
          callbacks!.onDataReceivedController.add(BleMeshManagerCallbacksDataReceived(device!, mtuSize, data));
        } else {
          if (!connectCompleter.isCompleted) {
            const msg = 'no callback ready to receive data event';
            _log(msg);
            connectCompleter.completeError(const BleManagerException(BleManagerFailureCode.callbacks, msg));
          }
        }
      }, onError: (e, s) {
        const msg = 'error in device data stream';
        _log('$msg : $e\n$s');
        if (!(callbacks?.onErrorController.isClosed == true) && callbacks!.onErrorController.hasListener) {
          callbacks!.onErrorController.add(BleManagerCallbacksError(device, msg, e));
        }
        if (!connectCompleter.isCompleted) {
          // will notify for error as the connection could not be properly established
          connectCompleter.completeError(e);
        }
      });

  /// This method will send the given PDU.
  ///
  /// It may split the data in chunks based on the current [mtuSize].
  // Future<void> sendPdu(final List<int> pdu) async {
  //   final chunks = ((pdu.length / (mtuSize - 1)) + 1).floor();
  //   var srcOffset = 0;
  //   if (chunks > 1) {
  //     for (var i = 0; i < chunks; i++) {
  //       final length = math.min(pdu.length - srcOffset, mtuSize);
  //       final sublist = pdu.sublist(srcOffset, srcOffset + length);
  //       final segmentedBuffer = sublist;
  //       await _send(segmentedBuffer);
  //       srcOffset += length;
  //     }
  //   } else {
  //     await _send(pdu);
  //   }
  // }
  Future<void> sendPdu(List<int> pdu) async {
    if (Platform.isIOS) {
      // Max payload per segment (minus 1 byte for SAR+MsgType header).
      final maxSegmentSize = mtuSize - 1;
      final totalSegments = (pdu.length / maxSegmentSize).ceil();

      if (totalSegments == 1) {
        await _send(pdu);
        return;
      }

      var offset = 1;
      for (var segO = 0; segO < totalSegments; segO++) {
        final end = math.min(offset + maxSegmentSize, pdu.length);
        final segmentData = pdu.sublist(offset, end);

        // SAR bits (2 bits):
        // 00 = Complete message
        // 01 = First segment
        // 10 = Continuation segment
        // 11 = Last segment
        int sar;
        if (segO == 0) {
          sar = 0x01; // First
        } else if (segO == totalSegments - 1) {
          sar = 0x03; // Last
        } else {
          sar = 0x02; // Continuation
        }

        final packet = _buildProxyPdu(sar, segmentData);
        await _send(packet);

        offset = end;
      }
    } else {
      // Android: Nordic applySegmentation() returns one buffer with variable-length segments.
      // Segment 0 = min(pduLen, mtuSize) bytes at 0; then dstOffset += mtuSize (gap!);
      // segment 1..n-1 start at mtuSize, 2*mtuSize, ... and are mtuSize bytes (middle) or
      // 1+payload (last). We must send exact segments so ESP proxy SAR matches (iOS works because we build segments ourselves).
      final chunks = (pdu.length + 1 + mtuSize) ~/ (mtuSize + 1);
      if (chunks <= 1) {
        await _send(pdu);
        return;
      }
      final pduLen = pdu.length - chunks + 1;
      final seg0Size = math.min(pduLen, mtuSize);
      // Segment 0: indices 0..seg0Size-1
      await _send(pdu.sublist(0, seg0Size));
      var offset = mtuSize; // Nordic advances by mtuSize after each segment
      for (var i = 1; i < chunks; i++) {
        final isLast = i == chunks - 1;
        final segLen = isLast ? (pdu.length - offset) : mtuSize;
        await _send(pdu.sublist(offset, offset + segLen));
        offset += mtuSize;
      }
    }
  }

  /// Builds a Proxy PDU with SAR + MessageType.
  List<int> _buildProxyPdu(int sar, List<int> payload) {
    int messageType = 0x00;
    if (isProvisioningCompleted) {
      messageType = 0x00;
    }// Network PDU (can change: 0x03=Provisioning)
    else{
      messageType = 0x03;
    }
    final header = (sar << 6) | messageType;
    print("header $header");
    return [header,...payload];
  }
  Future<void> _send(final List<int> data) async {
    print("→ Sending segment (${data.length} bytes): $data");
    if (data.isEmpty) {
      return;
    }
    if (isProvisioningCompleted) {
      try {
        await retry(
          () async {
            final service = _discoveredServices.firstWhere((service) => service.serviceId == meshProxyUuid);
            await bleInstance.writeCharacteristicWithoutResponse(
                _getQualifiedCharacteristic(meshProxyDataIn, service.serviceId),
                value: data);
            print("✅  isProvisioningCompleted Write succeeded (with response)");
          },
          retryIf: (e) => e is PlatformException,
        );
        callbacks!.onDataSentController.add(BleMeshManagerCallbacksDataSent(device!, mtuSize, data));
      } catch (_) {}
    } else {
      try {
        await retry(
          () async {
            final service = _discoveredServices.firstWhere((service) => service.serviceId == meshProvisioningUuid);
            await bleInstance.writeCharacteristicWithoutResponse(
                _getQualifiedCharacteristic(meshProvisioningDataIn, service.serviceId),
                value: data);
          },
          retryIf: (e) => e is PlatformException,
        );
        callbacks!.onDataSentController.add(BleMeshManagerCallbacksDataSent(device!, mtuSize, data));
      } catch (_) {}
    }
  }

  /// A method to clear GATT cache (only useful in some cases in **Android**)
  Future<void> refreshDeviceCache() async {
    if (Platform.isAndroid) {
      if (device != null) {
        try {
          return await bleInstance.clearGattCache(device!.id);
        } on Exception catch (e) {
          if (e.toString().toLowerCase().contains('not connected')) {
            _log('cannot clear gatt cache because not connected');
          } else {
            rethrow;
          }
        }
      }
    }
  }
}
