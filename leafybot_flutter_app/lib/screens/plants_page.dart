import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/Comman_Widget/custom_snackbar.dart';
import 'package:leafybot_flutter_app/constant/appColors.dart';
import 'package:leafybot_flutter_app/constant/assets_path.dart';
import 'package:leafybot_flutter_app/mesh/leafy_device_count_page.dart';
import 'package:leafybot_flutter_app/mesh/mesh_scan_and_provisioning.dart';
import 'package:leafybot_flutter_app/models/pot_device_model.dart';
import 'package:leafybot_flutter_app/repository/plantRepository.dart';
import 'package:leafybot_flutter_app/screens/homeScreen.dart';
import 'package:leafybot_flutter_app/utils/consstant_utils.dart';
import '../../controller/plants_controller.dart';
import '../Comman_Widget/main_app_bar.dart';

class MyPlantsPage extends StatelessWidget {
  MyPlantsPage({super.key});

  final PlantsController controller = Get.put(PlantsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomMainAppBar(title: "My Plants"),
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Device Gallery",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 16,
                letterSpacing: 0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // ✅ List of Plant Cards
            Expanded(
              child: Obx(() {
                return ListView.builder(
                  itemCount: controller.potDeviceList.length,
                  itemBuilder: (context, index) {
                    final pot = controller.potDeviceList[index];
                    Map<String ,dynamic> detaildata= json.decode(pot.nickName);
                    return GestureDetector(
                      onTap: (){
                       // Get.to(HomeScreen(selectedPlant: pot,isDetailPage:true ));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.only(left: 16, right: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border.all(
                            color: pot.isBlank.isBlank==false
                                ? AppColors.green
                                : AppColors.grayLight,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // ✅ Plant Image
                            Image.network(
                             pot.imageUrl,
                              height: 70,
                              width: 70,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                      
                            // ✅ Plant Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Row(
                                      children: [
                                        Text(
                                          detaildata["nickname"],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontSize: 16,
                                                letterSpacing: 0,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        Spacer(),
                                        // ✅ Delete Icon
                                        IconButton(
                                          icon: Image.asset(
                                            AssetsPath.deleteIcon,
                                            color: Theme.of(
                                              context,
                                            ).iconTheme.color,
                                            width: 24,
                                            height: 24,
                                          ),
                                          onPressed: () {
                                            delete_plant(context,pot);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min, // make row wrap content
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          pot.deviceId,
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            fontSize: 14,
                                            letterSpacing: 0,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          overflow: TextOverflow.ellipsis, // prevent overflow
                                        ),
                                      ),
                                      const SizedBox(width: 6), // spacing between text and circle
                                      Container(
                                        height: 8,
                                        width: 8,
                                        decoration: BoxDecoration(
                                          color: pot.isBlank == false ? AppColors.green : AppColors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 6,
                                      bottom: 19,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.bgLightGreen,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        pot.plantLocation,
                                        style: TextStyle(
                                          color: AppColors.green,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
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
              }),
            ),
          ],
        ),
      ),

      // ✅ Floating Add Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(LeafyDeviceCountPage());
        },
        backgroundColor: AppColors.green,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
  delete_plant(BuildContext context,PotDeviceModel pot) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets, // shift UI when keyboard opens
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Close button on left
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Label
                  Center(
                    child: Text(
                      "Are you sure you want to remove or unpair Rosie device (LeafyBot #2432)?",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Horizontal buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side:  BorderSide(
                                  color: AppColors.red, // ✅ red border
                                  width: 1,
                                ),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Unpair device",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async{
                              Get.back();
                            var response= await PlantRepository.deletePotDeviceByid(pot.appDeviceId);
                            if(response==true){
                              AppSnackBar.show("success", "Plant deleted Successfully");
                              await controller.loadPotDeviceList();
                            }
                            },
                            child: const Text(
                              "Remove from app",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ), // spacing between buttons
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


}
