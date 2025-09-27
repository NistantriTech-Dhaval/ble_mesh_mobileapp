import 'dart:ffi' hide Size;

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/constant/appColors.dart';
import 'package:leafybot_flutter_app/constant/assets_path.dart';
import 'package:leafybot_flutter_app/screens/notification/notification_list.dart';

class CustomMainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final RxMap<String, dynamic> ? selectedBot;
  final RxList<Map<String, dynamic>> ?deviceList; // Dynamic device list
  final ValueChanged<Map<String, dynamic>>? onDeviceSelected;
  final VoidCallback? onMenuTap;
  final bool ? showActiveStatus;
  final VoidCallback? onNotificationTap;
  final String ?title;

  const CustomMainAppBar({
    super.key,
    this.selectedBot,
    this.deviceList,
    this.onDeviceSelected,
    this.onMenuTap,
    this.showActiveStatus = false,
    this.onNotificationTap,
    this.title
  });


  @override
  Widget build(BuildContext context) {
    RxBool isOpen = false.obs;
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Menu button
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border.all(
                color: AppColors.grayLight,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: GestureDetector(
                onTap: (){},
                child: Image.asset(AssetsPath.menuIcon,height: 12,width: 18,
                  color: Theme.of(context)
                      .iconButtonTheme
                      .style
                      ?.iconColor
                      ?.resolve({}) ?? Colors.black),
              ),
            ),
          ),

          /// Bot dropdown
            if (selectedBot != null && title == null)
              Obx(() {
                  return Container(
                    width: Get.width *0.5,
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border.all(color: AppColors.grayLight),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        value: selectedBot?.value["name"], // ✅ ensure correct type
                        dropdownStyleData: DropdownStyleData(
                          width: Get.width * 0.5,
                          offset: const Offset(-15, -2),
                          isOverButton: false,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).scaffoldBackgroundColor,
                          ),
                        ),
                        hint: Text(
                          "Select Bot",
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 14,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        iconStyleData: IconStyleData(
                          icon: Transform.rotate(
                            angle: isOpen.value ? 3.1416 : 0,
                            child: Image.asset(
                              AssetsPath.downArrow,
                              height: 16,
                              width: 16,
                            ),
                          ),
                        ),
                        items: deviceList?.map((device) {
                          final bool isOnline = device['status'] == 'online';
                          return DropdownMenuItem<String>(
                            value: device["name"],
                            child: Row(
                              children: [
                              Text(
                                    device["name"] ?? "Unnamed Device",
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontSize: 14,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                const SizedBox(width: 6),
                                if (showActiveStatus == true)
                                  Icon(Icons.circle,
                                      size: 10,
                                      color: isOnline ? Colors.green : Colors.red),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (device) {
                          if (device != null) {
                            // selectedBot?.assignAll(device);
                            // onDeviceSelected?.call(device);
                          }
                        },
                        onMenuStateChange: (opened) {
                          isOpen.value=opened;

                        },
                      ),
                    ),
                  );
                }),

          if(title!=null)
            Text(
              title!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                letterSpacing: 0,
                fontWeight: FontWeight.w600,
              ),
            ),
          /// Notification button
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border.all(
                color: AppColors.grayLight,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Get.to(NotificationListPage());
                  },
                  child: Image.asset(
                    AssetsPath.notificationIcon,
                    height: 21,
                    width: 18,
                    color: Theme.of(context)
                        .iconButtonTheme
                        .style
                        ?.iconColor
                        ?.resolve({}) ?? Colors.black,
                  ),
                ),
                  Positioned(
                    top: 8,
                    right: 9,
                    child: Container(
                      height: 8,
                      width: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          )

        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
