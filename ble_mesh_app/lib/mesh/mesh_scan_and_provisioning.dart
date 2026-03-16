import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ntpl_ble_mesh_demo/constant/assets_path.dart';
import 'package:ntpl_ble_mesh_demo/controller/mesh_controller.dart';
import 'package:ntpl_ble_mesh_demo/mesh/wifi_provisioning_page.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';

import '../Comman_Widget/app_bar.dart';
import '../Comman_Widget/circular_progressbar.dart';
import '../constant/appColors.dart';

class ScanningAndProvisioning extends StatefulWidget {
  final String? meshNetworkId;
  /// When true, after provisioning completes navigate back to NetworkDevicesPage instead of ProvisionedDevicesPage.
  final bool returnToNetworkDevicesPage;

  ScanningAndProvisioning({
    Key? key,
    this.meshNetworkId,
    this.returnToNetworkDevicesPage = false,
  }) : super(key: key);

  @override
  State<ScanningAndProvisioning> createState() =>
      _ScanningAndProvisioningState();
}

class _ScanningAndProvisioningState extends State<ScanningAndProvisioning> {
  final MeshController controller = Get.put(MeshController(), permanent: true);
  final FlutterReactiveBle flutterReactiveBle=FlutterReactiveBle();
  @override
  void initState() {
    super.initState();
    initNetwork();
    // Preload success GIF so it appears immediately when provisioning completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(AssetImage(AssetsPath.success_gif), context);
    });
  }

  initNetwork() async {
    await controller.askPermissions();
    FlutterBluePlus.adapterState.listen((state) async {
      switch (state) {
        case BluetoothAdapterState.on:
          controller.isBluetooth.value = true;
          await controller.loadMeshNetworkForCommissioning(widget.meshNetworkId);
          await controller.scanUnprovisioned();
          break;
        case BluetoothAdapterState.off:
          controller.isBluetooth.value = false;
          break;
        default:
          print("ℹ️ Bluetooth state: $state");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Determine if provisioning is in progress
      final provisioning = controller.isProvisioning.value;

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
                    // Fixed height so layout doesn't jump when switching from loader to GIF
                    SizedBox(
                      height: controller.statusText.value ==
                          "Provisioning is Completed"?100:50,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: controller.statusText.value ==
                                "Provisioning is Completed"
                            ? Image.asset(
                                AssetsPath.success_gif,
                                key: const ValueKey('success_gif'),
                                height: 100,
                                width: 100,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                              )
                            : const Center(
                                key: ValueKey('loader'),
                                child: CircularProgressLoader(
                                  size: 40,
                                  strokeWidth: 7,
                                  backgroundcolor: AppColors.grayLight,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      controller.statusText.value,
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
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "Connect the Device to Bluetooth",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Obx(
                      () => ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                        ),
                        title: Text(
                          'Bluetooth',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                        trailing: Switch(
                          value: controller.isBluetooth.value,
                          onChanged: (val) =>
                              controller.toggleBluetooth(val, context),
                          trackOutlineColor: MaterialStateProperty.all(
                            Colors.transparent,
                          ),
                          activeTrackColor: AppColors.green,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: AppColors.grayLight,
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      title: Text(
                        'Available Devices',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      leading: GestureDetector(
                        onTap: () async => controller.resetMeshNetwork(),
                        child: Icon(
                        Icons.lock_reset_outlined,
                          size: 24,
                        ),
                      ),
                      trailing: GestureDetector(
                        onTap: () async => controller.scanUnprovisioned(),
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
                          return controller.scanUnprovisioned();
                        },
                        child: Obx(() {
                          final devices = controller.devices;
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
                              final uuid = controller.serviceData[device.id];
                              final mac = decodeMacFromDeviceUuid(uuid?.toString());


                              return GestureDetector(
                                onTap: () async {
                                  controller.provisionDevice(
                                    device,
                                    context,
                                    meshNetworkId: widget.meshNetworkId,
                                    returnToNetworkDevicesPage: widget.returnToNetworkDevicesPage,
                                  );
                                },
                                child: Container(
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
                                        AssetsPath.happyIcon,
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
                                      const SizedBox(width: 10),
                                      Text(
                                        mac.toString(),
                                        style: Theme.of(context)
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
  String? decodeMacFromDeviceUuid(String? uuid) {
    if (uuid == null || uuid.isEmpty) return null;

    final parts = uuid.split('-');
    if (parts.length < 4) return null;

    // Extract last 4 chars of the first block + full 2nd + full 3rd blocks
    final macHex = (parts[0].substring(parts[0].length - 4) + parts[1] + parts[2]).toUpperCase();

    // Format into standard MAC: XX:XX:XX:XX:XX:XX
    return macHex.replaceAllMapped(RegExp(r'.{2}'), (m) => '${m.group(0)}:').substring(0, 17);
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
    this.meshManagerApi,
    this.bleMeshManager,
  ) {
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

    onMeshPduCreatedSubscription = meshManagerApi.onMeshPduCreated.listen((
      event,
    ) async {
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
