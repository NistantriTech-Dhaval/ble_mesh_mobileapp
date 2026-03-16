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
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Confirm Removal',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove this gateway?',
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 88),
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
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isGateway
                  ? AppColors.darkBlue.withValues(alpha: 0.35)
                  : AppColors.grayLight,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.darkBlue.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isGateway ? Icons.router_rounded : Icons.memory_rounded,
                    color: AppColors.darkBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                                  name,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          Spacer(),
                          if (unicast != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.pin_drop_rounded,
                                  size: 12,
                                  color: AppColors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Unicast $unicast',
                                  style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.blue,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),

                      if (label != null && label.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              label,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 4),
                            if (isGateway)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.darkBlue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.wifi_tethering_rounded,
                                      size: 12,
                                      color: AppColors.darkBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Gateway',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                        color: AppColors.darkBlue,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(
                            height: 34,
                            child: isGateway
                                ? TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                foregroundColor: Colors.red.shade700,
                                backgroundColor:
                                Colors.red.shade50.withValues(alpha: 0.9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              onPressed: c.removingGatewayUnicast.value != null ||
                                  c.removingDeviceUnicast.value != null
                                  ? null
                                  : () => _removeGatewayWithDialog(context, c),
                              icon: const Icon(Icons.close_rounded, size: 14),
                              label: const Text(
                                'Remove Gateway',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                                : TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                foregroundColor: Colors.white,
                                backgroundColor: AppColors.darkgreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              onPressed: unicast == null ||
                                  isSetting ||
                                  c.removingDeviceUnicast.value != null
                                  ? null
                                  : () => c.setAsGateway(d),
                              icon: isSetting
                                  ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(
                                Icons.wifi_tethering_rounded,
                                size: 14,
                              ),
                              label: Text(
                                isGateway ? 'Gateway' : 'Set gateway',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (unicast != null) ...[
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 32,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  foregroundColor: Colors.red.shade700,
                                  side: BorderSide(color: Colors.red.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                onPressed: c.removingDeviceUnicast.value != null ||
                                    c.removingGatewayUnicast.value != null
                                    ? null
                                    : () => _removeDeviceWithDialog(context, c, d),
                                icon: c.removingDeviceUnicast.value == unicast
                                    ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                  CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 14,
                                ),
                                label: const Text(
                                  'Remove Device',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
