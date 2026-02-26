import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ntpl_ble_mesh_demo/Comman_Widget/app_bar.dart';
import 'package:ntpl_ble_mesh_demo/controller/network_devices_controller.dart';
import 'package:ntpl_ble_mesh_demo/mesh/mesh_scan_and_provisioning.dart';
import '../Comman_Widget/circular_progressbar.dart';
import '../constant/appColors.dart';

class NetworkDevicesPage extends StatelessWidget {
  const NetworkDevicesPage({
    super.key,
    required this.meshNetworkId,
    required this.networkName,
  });

  final String meshNetworkId;
  final String networkName;

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<NetworkDevicesController>(tag: meshNetworkId)
        ? Get.find<NetworkDevicesController>(tag: meshNetworkId)
        : Get.put(
            NetworkDevicesController(meshNetworkId: meshNetworkId, networkName: networkName),
            tag: meshNetworkId,
          );
    return Scaffold(
      appBar: const CustomAppBar(
        showBack: true,
        title: 'Network devices',
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: c.loadDevices,
        child: Obx(() => _buildBody(context, c)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Get.to(
            () => ScanningAndProvisioning(
              meshNetworkId: meshNetworkId,
              returnToNetworkDevicesPage: true,
            ),
          );
          c.loadDevices();
        },
        icon: const Icon(Icons.add),
        label: const Text('New device commissioning'),
        backgroundColor: AppColors.darkBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  static Future<void> _removeGatewayWithDialog(
    BuildContext context,
    NetworkDevicesController c,
  ) async {
    Get.dialog(
      Obx(() => AlertDialog(
        title: Text('Remove gateway',
          style: TextStyle(
            color: AppColors.textPrimary,
          )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressLoader(
              size: 40,
              color: AppColors.darkBlue,
              strokeWidth: 7,
            ),
            const SizedBox(height: 16),
            Text(
              c.removeGatewayStatus.value.isEmpty
                  ? 'Removing gateway...'
                  : c.removeGatewayStatus.value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      )),
      barrierDismissible: false,
    );
    await c.removeGateway();
    if (Get.isDialogOpen == true) Get.back();
  }

  static Future<void> _removeDeviceWithDialog(
    BuildContext context,
    NetworkDevicesController c,
    Map<String, dynamic> device,
  ) async {
    final name = device['name'] as String? ?? 'Device';
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Remove device',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Remove "$name"? Keep device in range.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    Get.dialog(
      AlertDialog(
        title: Text(
          'Removing device',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressLoader(
              size: 40,
              color: AppColors.darkBlue,
              strokeWidth: 7,
            ),
            const SizedBox(height: 16),
            Text(
              'Please wait...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
    await c.removeDevice(device);
    Get.back(closeOverlays: true);
  }

  Widget _buildBody(BuildContext context, NetworkDevicesController c) {
    if (c.loading.value) {
      return const Center(child: CircularProgressLoader(color: AppColors.darkBlue));
    }
    if (c.devices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No devices in this network yet.',
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Provision devices from the mesh network flow.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
      itemCount: c.devices.length,
      itemBuilder: (context, i) {
        final d = c.devices[i];
        final name = d['name'] as String? ?? 'Device';
        final label = d['label'] as String?;
        final unicast = d['unicast'] as int?;
        final isGateway = d['isGateway'] == true;
        final isSetting = c.settingGatewayUnicast.value == unicast;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.grayLight),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.devices, color: AppColors.darkBlue, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (label != null && label.isNotEmpty)
                        Text(
                          label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 40,
                      child: isGateway
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.darkBlue.withOpacity(0.9),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: c.removingGatewayUnicast.value != null ||
                                      c.removingDeviceUnicast.value != null
                                  ? null
                                  : () => _removeGatewayWithDialog(context, c),
                              child: const Text(
                                'Remove gateway',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.darkgreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: unicast == null ||
                                      isSetting ||
                                      c.removingDeviceUnicast.value != null
                                  ? null
                                  : () => c.setAsGateway(d),
                              child: isSetting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Set as Gateway',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                            ),
                    ),
                    if (unicast != null) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: c.removingDeviceUnicast.value != null ||
                                  c.removingGatewayUnicast.value != null
                              ? null
                              : () => _removeDeviceWithDialog(context, c, d),
                          child: c.removingDeviceUnicast.value == unicast
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Remove',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
