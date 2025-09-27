import 'dart:io';
import 'dart:async';
import 'package:get/get.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';
import 'package:permission_handler/permission_handler.dart';

class MeshController extends GetxController {
  final nordicNrfMesh = NordicNrfMesh();
  final meshNetwork = Rxn<IMeshNetwork>();
  final nodes = <ProvisionedMeshNode>[].obs;
  final groups = <GroupData>[].obs;

  late final MeshManagerApi _meshManagerApi;
  StreamSubscription<IMeshNetwork?>? _updateSub;
  StreamSubscription<IMeshNetwork?>? _importSub;
  StreamSubscription<IMeshNetwork?>? _loadSub;

  @override
  void onInit() {
    super.onInit();
    _askPermissions();
    _loadMeshNetwork();
  }

  Future<void> _askPermissions() async {
    print("Request Ask permission");
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

  Future<void> _loadMeshNetwork() async {
    _meshManagerApi = nordicNrfMesh.meshManagerApi;
    meshNetwork.value = _meshManagerApi.meshNetwork;

    // Subscribe to events
    void _update(IMeshNetwork? network) {
      meshNetwork.value = network;
      _loadNodesAndGroups();
    }

    _updateSub = _meshManagerApi.onNetworkUpdated.listen(_update);
    _importSub = _meshManagerApi.onNetworkImported.listen(_update);
    _loadSub = _meshManagerApi.onNetworkLoaded.listen(_update);

    await _meshManagerApi.cleanProvisioningData();
    await _meshManagerApi.loadMeshNetwork();
  }

  Future<void> _loadNodesAndGroups() async {
    if (meshNetwork.value == null) return;

    final loadedNodes = await meshNetwork.value!.nodes;
    final loadedGroups = await meshNetwork.value!.groups;

    nodes.assignAll(loadedNodes);
    groups.assignAll(loadedGroups);

    // Ensure at least one group exists
    if (groups.isEmpty) {
      await _meshManagerApi.meshNetwork?.addGroupWithName("DefaultGroup");
      final updatedGroups = await meshNetwork.value!.groups;
      groups.assignAll(updatedGroups);
    }
  }

  @override
  void onClose() {
    _updateSub?.cancel();
    _importSub?.cancel();
    _loadSub?.cancel();
    super.onClose();
  }
}
