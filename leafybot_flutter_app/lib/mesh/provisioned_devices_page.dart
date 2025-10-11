import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:leafybot_flutter_app/Comman_Widget/custom_button.dart';
import 'package:leafybot_flutter_app/constant/assets_path.dart';
import 'package:leafybot_flutter_app/controller/mesh_controller.dart';
import 'package:leafybot_flutter_app/controller/provisioned_device_controller.dart';
import 'package:leafybot_flutter_app/mesh/wifi_provisioning_page.dart';
import 'package:leafybot_flutter_app/screens/main_screen.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';
import '../Comman_Widget/app_bar.dart';
import '../Comman_Widget/circular_progressbar.dart';
import '../constant/appColors.dart';

class ProvisionedDevicesPage extends StatefulWidget {

  const ProvisionedDevicesPage({Key? key}) : super(key: key);

  @override
  State<ProvisionedDevicesPage> createState() =>
      _ProvisionedDevicesPageState();
}

class _ProvisionedDevicesPageState extends State<ProvisionedDevicesPage> {
  final MeshController meshcontroller = Get.put(MeshController());
  final ProvisionedDeviceController controller = Get.put(ProvisionedDeviceController());
  @override
  void initState() {
    super.initState();
    loadNetwork();
  }

  loadNetwork() async {
    await controller.loadPotDeviceList();
    await controller.loadMeshNetwork();
    await meshcontroller.scanUnprovisioned();
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: provisioning
              ? Column(
            children: [
              Spacer(),
                const CircularProgressLoader(
                  size: 40,
                  strokeWidth: 7,
                  backgroundcolor: AppColors.grayLight,
                ),
              const SizedBox(height: 24),
              Text(
                meshcontroller.statusText.value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              Spacer(),
            ],
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24,right: 24,top: 14),
                child: Text(
                  "Provisioned Devices",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                   await controller.loadMeshNetwork();
                  },
                  child: Obx(() {
                    final nodes = controller.nodes;
                    if (nodes.isEmpty) {
                      if (controller.isScanning.value) {
                        return const Center(
                          child: CircularProgressLoader(color: AppColors.darkBlue),
                        );
                      } else {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                AssetsPath.empty_device_Icon,
                                height: 50,
                                width: 50,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "No provisioned device found",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontSize: 18, fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        );
                      }
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(left: 24, right: 24, top: 14),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: controller.potDeviceList.length,
                      itemBuilder: (context, i) {
                        final pot = controller.potDeviceList[i];
                        return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            margin: EdgeInsets.only(top: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.grayLight, width: 1),
                            ),
                            child:  Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Image.asset(
                                  AssetsPath.happyIcon,
                                  height: 24,
                                  width: 24,
                                  color: Theme.of(context)
                                      .iconButtonTheme
                                      .style
                                      ?.iconColor
                                      ?.resolve({}) ??
                                      AppColors.darkBlue,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pot.nickName+ pot.deviceId,
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        "Provisioning Completed",
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.darkgreen,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () async {
                                      // Convert deviceId string to int
                                      final int targetUnicastAddress = int.tryParse(pot.deviceId) ?? -1;

                                      if (targetUnicastAddress == -1) {
                                        throw "Invalid device ID: ${pot.deviceId}";
                                      }

//
                                      ProvisionedMeshNode? matchedNode;

                                      for (final node in nodes) {
                                        final unicast = await node.unicastAddress; // await here
                                        if (unicast == targetUnicastAddress) {
                                          matchedNode = node;
                                          break;
                                        }
                                      }

                                      if (matchedNode == null) {
                                        throw "Node with unicast address $targetUnicastAddress not found";
                                      }

                                      debugPrint("✅ Found node with unicast address: $targetUnicastAddress");

                                      controller.selectedNode=matchedNode;
                                      Get.to(WifiProvisioningPage(deviceId:pot.nickName,selected_mesh_option: 1));
                                      // your action
                                    },
                                    label: const Text(
                                      "Setup as gateway",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                ),// ❌ this causes layout conflict with `Flexible`
                              ],
                            ),



                        );
                      },
                    );
                  }),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  'Available Devices',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: GestureDetector(
                  onTap: () async => meshcontroller.scanUnprovisioned(),
                  child: Image.asset(AssetsPath.sync_Icon, height: 24, width: 24),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () {
                    if (meshcontroller.isScanning.value) return Future.value();
                    return meshcontroller.scanUnprovisioned();
                  },
                  child: Obx(() {
                    final devices = meshcontroller.devices;
                    if (devices.isEmpty) {
                      if (meshcontroller.isScanning.value) {
                        return const Center(
                          child: CircularProgressLoader(color: AppColors.darkBlue),
                        );
                      } else {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                AssetsPath.empty_device_Icon,
                                height: 100,
                                width: 100,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "No device found",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontSize: 18, fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        );
                      }
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(left: 24, right: 24, top: 10),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: devices.length,
                      itemBuilder: (context, i) {
                        final device = devices[i];
                        return GestureDetector(
                          onTap: () => meshcontroller.provisionDevice(device, context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              border: Border.all(color: AppColors.grayLight),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  AssetsPath.happyIcon,
                                  height: 24,
                                  width: 24,
                                  color: Theme.of(context)
                                      .iconButtonTheme
                                      .style
                                      ?.iconColor
                                      ?.resolve({}) ??
                                      AppColors.darkBlue,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  device.name,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: provisioning
            ?null: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.fromLTRB(24, 19, 24, 34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CustomButton(
                  text: "Go to Dashboard",
                  onPressed: (){
                    Get.offAll(MainScreen());
                  },
                ),
              ],
            ),
        ),
      );
    });
  }

}