import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/Comman_Widget/app_bar.dart';
import 'package:leafybot_flutter_app/constant/appColors.dart';
import 'package:leafybot_flutter_app/constant/assets_path.dart';

import '../../Comman_Widget/custom_dialog.dart';

class ResetUnpairDevice extends StatelessWidget {
  ResetUnpairDevice({super.key});

  // Sample device list
  final List<Map<String, String>> devices = [
    {"name": "Rosie", "id": "LeafyBot #2432"},
    {"name": "Demona", "id": "LeafyBot #1152"},
    {"name": "Comy", "id": "LeafyBot #7545"},
    {"name": "Laky", "id": "LeafyBot #2344"},
    {"name": "Giyan", "id": "LeafyBot #4356"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Reset / Unpair Device",
        showBack: true, // first page no back button
        centerTitle: false,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: devices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final device = devices[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grayLight, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Device name + id
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device["name"]!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device["id"]!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 14,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                // Delete button
                IconButton(
                  icon: Image.asset(
                    AssetsPath.deleteIcon,
                    color: AppColors.gray,
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () async {
                    await delete_plant(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  delete_plant(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(
            context,
          ).viewInsets, // shift UI when keyboard opens
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
                                side: BorderSide(
                                  color: AppColors.red, // ✅ red border
                                  width: 1,
                                ),
                              ),
                            ),
                            onPressed: () {
                              Get.dialog(
                                SuccessPopup(
                                  title: 'Success!',
                                  message: 'You have been done successfully Remove device',
                                  imageAsset:  AssetsPath.successIcon,
                                  buttonText: 'Continue',
                                  onButtonPressed: () {
                                    Get.back();
                                  },
                                ),
                                barrierDismissible: false, // optional: prevent closing by tapping outside
                              );
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
                            onPressed: () {
                              Get.back();

                              Get.dialog(
                                SuccessPopup(
                                  title: 'Success!',
                                  message: 'You have been done successfully Remove device',
                                  imageAsset:  AssetsPath.successIcon,
                                  buttonText: 'Continue',
                                  onButtonPressed: () {
                                    Get.back();
                                  },
                                ),
                                barrierDismissible: false, // optional: prevent closing by tapping outside
                              );
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
