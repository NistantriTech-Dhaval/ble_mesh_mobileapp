import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:leafybot_flutter_app/constant/assets_path.dart';
import 'package:leafybot_flutter_app/controller/provisioned_device_controller.dart';
import '../Comman_Widget/app_bar.dart';
import '../Comman_Widget/circular_progressbar.dart';
import '../Comman_Widget/custom_button.dart';
import '../Comman_Widget/custom_textfield.dart' show CustomTextField;
import '../constant/appColors.dart';
import '../controller/mesh_controller.dart';

class WifiProvisioningPage extends StatefulWidget {
  const WifiProvisioningPage({Key? key}) : super(key: key);

  @override
  State<WifiProvisioningPage> createState() => _WifiProvisioningPageState();
}

class _WifiProvisioningPageState extends State<WifiProvisioningPage> {
  final ProvisionedDeviceController controller = Get.put(
    ProvisionedDeviceController(),
  );

  final MeshController menuController = Get.put(MeshController());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Determine if provisioning is in progress
      final provisioning = controller.isWifiProvisioning.value;

      return Scaffold(
        appBar: CustomAppBar(
          showBack: !provisioning, // hide back button while provisioning
        ),
        backgroundColor: Colors.white,
        body: Center(
          child: provisioning
              ? Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 34,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: controller.wifiConnectionFailed.value == true
                        ? [
                            Spacer(),
                            Image.asset(
                              AssetsPath.angryIcon,
                              height: 44,
                              width: 44,
                            ),

                            const SizedBox(height: 20),

                            // Title
                            Text(
                              "Unable to connect. Try again",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0,
                                  ),
                            ),

                            const SizedBox(height: 8),

                            // Subtitle
                            Text(
                              "Device already paired with another user",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0,
                                  ),
                            ),

                            const SizedBox(height: 40),

                            // Reset Guidance Title
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Reset guidance",
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0,
                                    ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Steps
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "1. Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 0,
                                        ),
                                  ),

                                  SizedBox(height: 8),
                                  Text(
                                    "2. Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 0,
                                        ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "3. Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 0,
                                        ),
                                  ),
                                ],
                              ),
                            ),

                            Spacer(),
                            CustomButton(
                              text: "Retry",
                              onPressed: () async {
                                await controller.connectWithNode();
                              },
                            ),
                          ]
                        : [
                            const CircularProgressLoader(),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  controller.wifistatusText.value,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                if (controller.wifistatusText.value ==
                                    "Connected to")
                                  Text(
                                    " ${controller.selectedWifi.value}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                              ],
                            ),
                          ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "Connect the Device to Wi-Fi",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      title: Text(
                        'Available Networks',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: GestureDetector(
                        onTap: () async => controller.scanWifi(),
                        child: Image.asset(
                          AssetsPath.sync_Icon,
                          height: 24,
                          width: 24,
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () {
                          if (controller.isScanning.value)
                            return Future.value();
                          return controller.scanWifi();
                        },
                        child: Obx(() {
                          final devices = controller.wifiList;
                          if (devices.isEmpty) {
                            if (controller.isScanning.value) {
                              return const Center(
                                child: CircularProgressLoader(
                                  color: AppColors.darkBlue,
                                ),
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

                                    Text(
                                      "No device found",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w400,
                                          ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.only(
                              left: 24,
                              right: 24,
                              top: 10,
                            ),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: devices.length,
                            itemBuilder: (context, i) {
                              final device = devices[i];
                              return GestureDetector(
                                onTap: () {
                                  _wifiPassword(context, device);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(top: 14),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    border: Border.all(
                                      color: AppColors.grayLight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        AssetsPath.wifi_icon,
                                        height: 24,
                                        width: 24,
                                        color: Theme.of(
                                          context,
                                        ).iconTheme.color,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        device,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400,
                                            ),
                                      ),
                                      Spacer(),
                                      Image.asset(
                                        AssetsPath.lock_icon,
                                        height: 24,
                                        width: 24,
                                        color:
                                            Theme.of(context)
                                                .iconButtonTheme
                                                .style
                                                ?.iconColor
                                                ?.resolve({}) ??
                                            AppColors.darkBlue,
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
      );
    });
  }

  void _wifiPassword(BuildContext context, String deviceName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Important: allows full height modal
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          // This padding allows the sheet to move up when the keyboard opens
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Important: shrink to content
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.grayLight),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        deviceName,
                        style: Theme.of(Get.context!).textTheme.titleSmall
                            ?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Icon(Icons.close, color: AppColors.gray),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Password",
                    style: Theme.of(Get.context!).textTheme.titleSmall
                        ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CustomTextField(
                    hintText: "Enter password",
                    controller: controller.password_controller,
                    textStyle: Theme.of(context).textTheme.titleSmall,
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: 12,
                    borderColor: AppColors.grayLight,
                    errorBorderColor: Colors.red,
                    borderWidth: 1,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  child: CustomButton(
                    text: "Submit",
                    onPressed: () async {
                      if (controller.password_controller.text.isNotEmpty) {
                        Get.back();
                        controller.selectedWifi.value = deviceName;
                        await controller.connectWithNode();
                      }
                    },
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
