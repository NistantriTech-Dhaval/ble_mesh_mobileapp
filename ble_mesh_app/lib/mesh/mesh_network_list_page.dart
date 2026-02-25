import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ntpl_ble_mesh_demo/Comman_Widget/app_bar.dart';
import 'package:ntpl_ble_mesh_demo/Comman_Widget/custom_button.dart';
import 'package:ntpl_ble_mesh_demo/controller/mesh_network_controller.dart';
import 'package:ntpl_ble_mesh_demo/mesh/network_devices_page.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

import '../Comman_Widget/circular_progressbar.dart';
import '../constant/appColors.dart';

class MeshNetworkListPage extends StatefulWidget {
  /// When true, only the body is built (no Scaffold/AppBar). Use when embedding in a shell (e.g. HomePage Mesh Network tab).
  final bool embedInShell;

  const MeshNetworkListPage({
    super.key,
    this.embedInShell = false,
  });

  @override
  State<MeshNetworkListPage> createState() => _MeshNetworkListPageState();
}

class _MeshNetworkListPageState extends State<MeshNetworkListPage> {
  final MeshNetworkController controller = Get.put(MeshNetworkController());
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.fetchNetworks();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showAddNetworkDialog() {
    _nameController.clear();
    _descController.clear();
    Get.dialog(
      AlertDialog(
        title: const Text('Add Mesh Network'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Network name',
                hintText: 'e.g. Home, Office',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final ok = await controller.addNetwork(
                _nameController.text,
                description: _descController.text.isEmpty
                    ? null
                    : _descController.text,
              );
              if (ok && mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _onSelectNetwork(AssetInfo info) {
    final id = info.id?.id;
    if (id == null) return;
    controller.selectedNetworkId.value = id;
    Get.to(
      () => NetworkDevicesPage(
        meshNetworkId: id,
        networkName: info.name ?? 'Network',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Container(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 34, top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a network to provision devices, or add a new one.',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Add network',
              onPressed: _showAddNetworkDialog,
              icon: Icons.add,
              height: 48,
            ),
            const SizedBox(height: 24),
            Text(
              'Networks',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressLoader(color: AppColors.darkBlue),
                  );
                }
                final list = controller.networks;
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'No mesh networks yet.',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap "Add network" to create one in ThingsBoard.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: controller.fetchNetworks,
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final info = list[index];
                      final name = info.name ?? 'Unnamed';
                      final label = info.label;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: AppColors.grayLight),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Icon(
                            Icons.network_wifi,
                            color: AppColors.darkBlue,
                          ),
                          title: Text(
                            name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          subtitle: label != null && label.isNotEmpty
                              ? Text(
                                  label,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _onSelectNetwork(info),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      );

    if (widget.embedInShell) return body;

    return Scaffold(
      appBar: const CustomAppBar(
        showBack: true,
        title: 'Select Mesh Network',
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: body,
    );
  }
}
