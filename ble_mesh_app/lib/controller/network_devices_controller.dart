import 'package:get/get.dart';
import 'package:ntpl_ble_mesh_demo/Comman_Widget/custom_snackbar.dart';
import 'package:ntpl_ble_mesh_demo/controller/mesh_controller.dart';
import 'package:ntpl_ble_mesh_demo/controller/mesh_network_controller.dart';
import 'package:ntpl_ble_mesh_demo/controller/provisioned_device_controller.dart';
import 'package:ntpl_ble_mesh_demo/mesh/wifi_provisioning_page.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

class NetworkDevicesController extends GetxController {
  NetworkDevicesController({
    required this.meshNetworkId,
    this.networkName = 'Network',
  });

  final String meshNetworkId;
  final String networkName;

  final MeshNetworkController netController = Get.find<MeshNetworkController>();
  late final MeshController meshController = Get.put(MeshController());
  late final ProvisionedDeviceController provController = Get.put(ProvisionedDeviceController());

  final loading = true.obs;
  final devices = <Map<String, dynamic>>[].obs;
  final settingGatewayUnicast = Rxn<int>();
  final removingGatewayUnicast = Rxn<int>();
  /// Progress or error message during remove-gateway flow.
  final removeGatewayStatus = ''.obs;
  /// Unicast of device currently being removed from network (so firmware returns to provisioning, removed from asset, deleted from ThingsBoard).
  final removingDeviceUnicast = Rxn<int>();
  /// Progress or error message during remove-device flow.
  final removeDeviceStatus = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadDevices();
  }

  Future<void> loadDevices() async {
    loading.value = true;
    final list = await netController.getDevicesWithUnicastRelatedToAsset(meshNetworkId);
    devices.assignAll(list);
    loading.value = false;
  }

  /// Returns true if any device in this network is currently the gateway.
  bool get hasGateway => devices.any((d) => d['isGateway'] == true);

  Future<void> removeGateway() async {
    if (removingGatewayUnicast.value != null) return;
    int? gatewayUnicast;
    String? deviceName;
    for (final d in devices) {
      if (d['isGateway'] == true) {
        gatewayUnicast = d['unicast'] as int?;
        deviceName = d['name'] as String? ?? 'Device';
        break;
      }
    }
    if (gatewayUnicast == null || deviceName == null) return;
    removingGatewayUnicast.value = gatewayUnicast;
    try {
      removeGatewayStatus.value = 'Loading mesh...';
      await meshController.loadMeshNetworkForCommissioning(meshNetworkId);
      await Future.delayed(const Duration(milliseconds: 500));
      final nodes = await meshController.meshNetwork.value?.nodes ?? [];
      for (final n in nodes) {
        final u = await n.unicastAddress;
        if (u == gatewayUnicast) {
          provController.selectedNode = n;
          break;
        }
      }
      removeGatewayStatus.value = 'Connecting to device...';
      final removedFromFirmware = await provController.connectAndSendRemoveGateway(deviceName);
      if (!removedFromFirmware) {
        removeGatewayStatus.value = '';
        return;
      }
      removeGatewayStatus.value = 'Updating cloud...';
      final ok = await netController.clearGateway(meshNetworkId);
      if (!ok) {
        removeGatewayStatus.value = 'Cloud update failed.';
        AppSnackBar.show('error', 'Failed to remove gateway');
        return;
      }
      removeGatewayStatus.value = '';
      await loadDevices();
    } catch (e) {
      removeGatewayStatus.value = 'Error: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}';
      AppSnackBar.show('error', 'Failed to remove gateway');
    } finally {
      removingGatewayUnicast.value = null;
    }
  }

  /// Removes device from network: deprovision (firmware returns to provisioning mode), delete from mesh, remove from asset, delete from ThingsBoard.
  Future<void> removeDevice(Map<String, dynamic> device) async {
    final unicast = device['unicast'] as int?;
    final deviceId = device['id'] as String?;
    final deviceName = device['name'] as String? ?? 'Device';
    if (unicast == null || deviceId == null) {
      AppSnackBar.show('error', 'Device info missing');
      return;
    }
    if (removingDeviceUnicast.value != null) return;
    removingDeviceUnicast.value = unicast;
    try {
      if (device['isGateway'] == true) {
        await netController.clearGateway(meshNetworkId);
      }
      await meshController.loadMeshNetworkForCommissioning(meshNetworkId);
      await Future.delayed(const Duration(milliseconds: 500));
      final nodes = await meshController.meshNetwork.value?.nodes ?? [];
      ProvisionedMeshNode? node;
      for (final n in nodes) {
        final u = await n.unicastAddress;
        if (u == unicast) {
          node = n;
          break;
        }
      }
      if (node == null) {
        AppSnackBar.show('error', 'Device not found in mesh');
        return;
      }
      provController.selectedNode = node;
      final deprovisioned = await provController.connectAndDeprovision(deviceName, node);
      if (!deprovisioned) {
        AppSnackBar.show('error', 'Keep device in range and try again.');
        return;
      }
      await meshController.meshManagerApi.meshNetwork!.deleteNode(node.uuid);
      final exported = await meshController.meshManagerApi.exportMeshNetwork();
      if (exported != null) {
        final nodeCount = (await meshController.meshNetwork.value?.nodes)?.length ?? 0;
        await netController.saveMeshNetworkAttributes(
          meshNetworkId,
          meshNetworkJson: exported,
          deviceCount: nodeCount,
        );
      }
      final ok = await netController.removeDeviceFromAssetAndDelete(meshNetworkId, deviceId);
      if (!ok) {
        AppSnackBar.show('error', 'Cloud update failed');
      } else {
        AppSnackBar.show('success', 'Device removed');
      }
      await loadDevices();
    } catch (e) {
      AppSnackBar.show('error', 'Failed to remove device');
    } finally {
      removingDeviceUnicast.value = null;
    }
  }

  Future<void> setAsGateway(Map<String, dynamic> device) async {
    final unicast = device['unicast'] as int?;
    final deviceName = device['name'] as String? ?? 'Device';
    if (unicast == null) {
      AppSnackBar.show('error', 'Device unicast not found');
      return;
    }
    if (hasGateway) {
      AppSnackBar.show('error', 'Remove the current gateway first');
      return;
    }
    if (settingGatewayUnicast.value != null) return;
    settingGatewayUnicast.value = unicast;
    try {
      await meshController.loadMeshNetworkForCommissioning(meshNetworkId);
      await Future.delayed(const Duration(milliseconds: 500));
      final nodes = await meshController.meshNetwork.value?.nodes ?? [];
      ProvisionedMeshNode? node;
      for (final n in nodes) {
        final u = await n.unicastAddress;
        if (u == unicast) {
          node = n;
          break;
        }
      }
      provController.selectedNode = node;
      await Get.to(
        () => WifiProvisioningPage(
          deviceName: deviceName,
          meshNetworkId: meshNetworkId,
          gatewayUnicast: unicast,
        ),
      );
      loadDevices();
    } catch (_) {
      AppSnackBar.show('error', 'Failed to open gateway setup');
    } finally {
      settingGatewayUnicast.value = null;
    }
  }
}
