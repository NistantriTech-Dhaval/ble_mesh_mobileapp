import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:ntpl_ble_mesh_demo/Comman_Widget/custom_button.dart';
import 'package:ntpl_ble_mesh_demo/constant/assets_path.dart';
import 'package:ntpl_ble_mesh_demo/Comman_Widget/custom_snackbar.dart';
import 'package:ntpl_ble_mesh_demo/controller/mesh_controller.dart';
import 'package:ntpl_ble_mesh_demo/controller/mesh_network_controller.dart';
import 'package:ntpl_ble_mesh_demo/controller/provisioned_device_controller.dart';
import 'package:ntpl_ble_mesh_demo/mesh/leafy_device_count_page.dart';
import 'package:ntpl_ble_mesh_demo/mesh/mesh_network_list_page.dart';
import 'package:ntpl_ble_mesh_demo/mesh/wifi_provisioning_page.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';
import '../Comman_Widget/app_bar.dart';
import '../Comman_Widget/circular_progressbar.dart';
import '../constant/appColors.dart';

class ProvisionedDevicesPage extends StatefulWidget {
  final DiscoveredDevice device;
  final ProvisionedMeshNode? meshNode;
  final dynamic deviceNetworkTypeId;
  final String? meshNetworkId;

  ProvisionedDevicesPage({
    super.key,
    required this.device,
    this.meshNode,
    required this.deviceNetworkTypeId,
    this.meshNetworkId,
  });

  @override
  State<ProvisionedDevicesPage> createState() =>
      _ProvisionedDevicesPageState();
}

class _ProvisionedDevicesPageState extends State<ProvisionedDevicesPage> {
  final MeshController meshcontroller = Get.put(MeshController());
  final ProvisionedDeviceController controller = Get.put(
      ProvisionedDeviceController());
  late final MeshNetworkController netController = Get.put(
      MeshNetworkController());
  bool _isSettingGateway = false;

  @override
  void initState() {
    super.initState();
    if (widget.meshNetworkId != null) {
      netController.selectedNetworkId.value = widget.meshNetworkId;
    }
    loadNetwork();
  }

  Future<void> loadNetwork() async {
    await controller.loadMeshNetwork();
    await meshcontroller.scanUnprovisioned();
  }

  Future<void> _setAsGateway(ProvisionedMeshNode node) async {
    final networkId = widget.meshNetworkId ??
        netController.selectedNetworkId.value;
    if (networkId == null || networkId.isEmpty) {
      AppSnackBar.show('error', 'Select a network first');
      return;
    }
    if (_isSettingGateway) return;
    setState(() => _isSettingGateway = true);
    try {
      final unicast = await node.unicastAddress;
      // On tap: connect with device, fetch WiFi list, then do gateway process (WiFi provisioning with isgateway)
      final deviceName = await netController.getDeviceNameByUnicast(networkId, unicast);
      if (!mounted) return;
      controller.selectedNode = node;
      setState(() => _isSettingGateway = false);
      Get.to(
        WifiProvisioningPage(
          deviceName: deviceName ?? node.uuid,
          deviceNetworkTypeId: 1,
          meshNetworkId: networkId,
          gatewayUnicast: unicast,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isSettingGateway = false);
        AppSnackBar.show('error', 'Failed to open gateway setup');
      }
    }
  }

  void _openNetworkSelector() {
    Get.to(() => const MeshNetworkListPage(
          deviceCount: 0,
          leafystickCount: 0,
        ));
  }

  /// Bottom sheet to select asset (network). On tap of a network, sets selected and closes.
  void _showSelectAssetBottomSheet() {
    netController.fetchNetworks();
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.75,
        expand: false,
        builder: (ctx, scrollController) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grayLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Icon(Icons.network_wifi, color: AppColors.darkBlue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select network',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (netController.isLoading.value) {
                  return const Center(
                    child: CircularProgressLoader(color: AppColors.darkBlue),
                  );
                }
                final list = netController.networks;
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No networks. Add a network first.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final info = list[i];
                    final id = info.id?.id;
                    final name = info.name ?? 'Unnamed';
                    final selected = id == netController.selectedNetworkId.value;
                    return ListTile(
                      leading: Icon(
                        Icons.network_wifi,
                        color: selected ? AppColors.darkgreen : AppColors.darkBlue,
                        size: 22,
                      ),
                      title: Text(name),
                      subtitle: info.label != null && info.label!.isNotEmpty
                          ? Text(info.label!, style: Theme.of(context).textTheme.bodySmall)
                          : null,
                      trailing: selected ? const Icon(Icons.check_circle, color: AppColors.darkgreen) : null,
                      onTap: () {
                        if (id != null) {
                          netController.selectedNetworkId.value = id;
                          Navigator.of(context).pop();
                        }
                      },
                    );
                  },
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openNetworkSelector();
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add network'),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNetworkDeviceRelations() async {
    final networkId = widget.meshNetworkId ?? netController.selectedNetworkId.value;
    if (networkId == null || networkId.isEmpty) {
      _openNetworkSelector();
      return;
    }
    final name = netController.networks
        .where((a) => a.id?.id == networkId)
        .map((a) => a.name ?? 'Network')
        .firstOrNull;
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.25,
        maxChildSize: 0.7,
        expand: false,
        builder: (ctx, scrollController) => FutureBuilder<List<Map<String, String>>>(
          future: netController.getDevicesRelatedToAsset(networkId),
          builder: (context, snapshot) {
            final devices = snapshot.data ?? [];
            final loading = snapshot.connectionState == ConnectionState.waiting;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grayLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: [
                      Icon(Icons.network_wifi, color: AppColors.darkBlue, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Devices in ${name ?? "network"}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressLoader(color: AppColors.darkBlue),
                  )
                else if (devices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No devices linked to this network yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: devices.length,
                      itemBuilder: (context, i) {
                        final d = devices[i];
                        return ListTile(
                          leading: Icon(Icons.devices, color: AppColors.darkBlue, size: 22),
                          title: Text(d['name'] ?? 'Device'),
                          subtitle: d['label'] != null && d['label']!.isNotEmpty
                              ? Text(d['label']!, style: Theme.of(context).textTheme.bodySmall)
                              : null,
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _openNetworkSelector();
                    },
                    icon: const Icon(Icons.swap_horiz, size: 20),
                    label: const Text('Change network'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Determine if provisioning is in progress
      final provisioning = meshcontroller.isProvisioning.value;

      return Scaffold(
        appBar: CustomAppBar(
          showBack: !provisioning, // hide back button while provisioning
        ),
        backgroundColor: Theme
            .of(context)
            .scaffoldBackgroundColor,
        body: Center(
          child: provisioning
              ? Column(
            children: [
              Spacer(),
              if (meshcontroller.statusText.value !=
                  "Provisioning is Completed")
                const CircularProgressLoader(
                  size: 40,
                  strokeWidth: 7,
                  backgroundcolor: AppColors.grayLight,
                ),
              if (meshcontroller.statusText.value !=
                  "Provisioning is Completed")
                const SizedBox(height: 24),
              if (meshcontroller.statusText.value ==
                  "Provisioning is Completed")
                Image.asset(
                  AssetsPath.success_gif,
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                ),
              Text(
                meshcontroller.statusText.value,
                style: Theme
                    .of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              Spacer(),
            ],
          )
              : RefreshIndicator(
            onRefresh: () async {
              await controller.loadMeshNetwork();
              if (meshcontroller.isScanning.value) return;
              return meshcontroller.scanUnprovisioned();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Top: Select network
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
                    child: Obx(() {
                      final selectedId = netController.selectedNetworkId.value;
                      final name = selectedId == null
                          ? null
                          : netController.networks
                          .where((a) => a.id?.id == selectedId)
                          .map((a) => a.name ?? 'Unnamed')
                          .firstOrNull;
                      return InkWell(
                        onTap: _showSelectAssetBottomSheet,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Theme
                                .of(context)
                                .cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.grayLight),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                  Icons.network_wifi, color: AppColors.darkBlue,
                                  size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Network',
                                      style: Theme
                                          .of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      name ?? 'Select network',
                                      style: Theme
                                          .of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Gateway & Provisioned devices (only for selected asset)
                Obx(() {
                  final selectedId = widget.meshNetworkId ?? netController.selectedNetworkId.value;
                  final selectedName = selectedId == null
                      ? null
                      : netController.networks
                          .where((a) => a.id?.id == selectedId)
                          .map((a) => a.name ?? 'network')
                          .firstOrNull;
                  if (selectedId == null || selectedId.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.grayLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gateway & provisioned devices',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Select a network above to see gateway and provisioned devices for that network.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: _showSelectAssetBottomSheet,
                                icon: const Icon(Icons.network_wifi, size: 20),
                                label: const Text('Select network'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final nodes = controller.nodes;
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
                          child: Text(
                            'Gateway & provisioned devices${selectedName != null ? ' · $selectedName' : ''}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                      if (nodes.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                            child: Text(
                              'No provisioned devices. Provision devices from the list below.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final node = nodes[i];
                              return _ProvisionedNodeTile(
                                node: node,
                                meshNetworkId: selectedId,
                                isSettingGateway: _isSettingGateway,
                                onSetAsGateway: () => _setAsGateway(node),
                                onWifiSetup: widget.deviceNetworkTypeId == 1
                                    ? null
                                    : () {
                                        controller.selectedNode = node;
                                        Get.to(WifiProvisioningPage(
                                          deviceName: widget.device.name,
                                          deviceNetworkTypeId: widget.deviceNetworkTypeId,
                                        ));
                                      },
                              );
                            },
                            childCount: nodes.length,
                          ),
                        ),
                    ],
                  );
                }),
                // Available devices (device list at last)
                SliverToBoxAdapter(
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    title: Text(
                      'Available devices',
                      style: Theme
                          .of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: GestureDetector(
                      onTap: () => meshcontroller.scanUnprovisioned(),
                      child: Image.asset(AssetsPath.sync_Icon, height: 24,
                          width: 24),
                    ),
                  ),
                ),
                Obx(() {
                  final devices = meshcontroller.devices;
                  if (devices.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
                        child: Center(
                          child: meshcontroller.isScanning.value
                              ? const CircularProgressLoader(
                              color: AppColors.darkBlue)
                              : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                  AssetsPath.empty_device_Icon, height: 80,
                                  width: 80),
                              const SizedBox(height: 10),
                              Text(
                                'No device found',
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) {
                        final device = devices[i];
                        final uuid = meshcontroller.serviceData[device.id];
                        final mac = decodeMacFromDeviceUuid(uuid?.toString());
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 6),
                          child: GestureDetector(
                            onTap: () {
                              if (widget.deviceNetworkTypeId == 1) {
                                meshcontroller.provisionDevice(
                                  device,
                                  context,
                                  meshNetworkId: widget.meshNetworkId ??
                                      netController.selectedNetworkId.value,
                                );
                              } else {
                                Get.to(WifiProvisioningPage(
                                  deviceName: device.name,
                                  deviceNetworkTypeId: widget
                                      .deviceNetworkTypeId,
                                ));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 18),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                border: Border.all(color: AppColors.grayLight),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    AssetsPath.happyIcon,
                                    height: 24,
                                    width: 24,
                                    color: Theme
                                        .of(context)
                                        .iconButtonTheme
                                        .style
                                        ?.iconColor
                                        ?.resolve({}) ??
                                        AppColors.darkBlue,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    mac ?? device.name,
                                    style: Theme
                                        .of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: devices.length,
                    ),
                  );
                }),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
        bottomNavigationBar: provisioning
            ? null : Container(
          color: Theme
              .of(context)
              .scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(24, 19, 24, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CustomButton(
                text: "Go to Dashboard",
                onPressed: () {
                  Get.offAll(LeafyDeviceCountPage());
                },
              ),
            ],
          ),
        ),
      );
    });
  }
}
class _ProvisionedNodeTile extends StatelessWidget {
  const _ProvisionedNodeTile({
    required this.node,
    required this.meshNetworkId,
    required this.onSetAsGateway,
    this.onWifiSetup,
    this.isSettingGateway = false,
  });

  final ProvisionedMeshNode node;
  final String? meshNetworkId;
  final VoidCallback onSetAsGateway;
  final VoidCallback? onWifiSetup;
  final bool isSettingGateway;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grayLight, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              AssetsPath.happyIcon,
              height: 24,
              width: 24,
              color: Theme.of(context).iconButtonTheme.style?.iconColor?.resolve({}) ?? AppColors.darkBlue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Provisioned device',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Provisioning completed',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (onWifiSetup != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: onWifiSetup,
                  child: const Text('Wi‑Fi setup'),
                ),
              ),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkgreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: (meshNetworkId == null || isSettingGateway) ? null : onSetAsGateway,
                child: isSettingGateway
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Set as gateway', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

  String? decodeMacFromDeviceUuid(String? uuid) {
    if (uuid == null || uuid.isEmpty) return null;

    final parts = uuid.split('-');
    if (parts.length < 4) return null;

    // Extract last 4 chars of the first block + full 2nd + full 3rd blocks
    final macHex = (parts[0].substring(parts[0].length - 4) + parts[1] + parts[2]).toUpperCase();

    // Format into standard MAC: XX:XX:XX:XX:XX:XX
    return macHex.replaceAllMapped(RegExp(r'.{2}'), (m) => '${m.group(0)}:').substring(0, 17);
  }