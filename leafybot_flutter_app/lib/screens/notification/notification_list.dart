import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/Comman_Widget/app_bar.dart';
import 'package:leafybot_flutter_app/constant/assets_path.dart';

import '../../constant/appColors.dart';
import '../../controller/notification_page_controller.dart';

class NotificationListPage extends StatelessWidget {
  final NotificationController controller = Get.put(NotificationController());

  NotificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Notifications / Alerts",
        showBack: true,
        centerTitle: false,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Obx(() {
        return ListView.builder(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
          itemCount: controller.notifications.length,
          itemBuilder: (context, sectionIndex) {
            final section = controller.notifications[sectionIndex];
            final sectionTitle = section["dateGroup"];
            final items = section["items"] as List<dynamic>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title (Today / Yesterday)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    sectionTitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      letterSpacing: 0,
                    ),
                  ),
                ),

                // Notifications inside this section
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Slidable(
                      key: ValueKey(item["id"] ?? UniqueKey()),

                      // Swipe from right to left
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.30, // width of the delete action (adjust for half-open)
                        children: [
                          SlidableAction(
                            onPressed: (context) {
                              controller.removeNotification(sectionIndex, index);
                            },
                            backgroundColor: AppColors.red, // same as before
                            foregroundColor: Colors.white,   // icon color
                            icon: Icons.delete_outline_outlined,
                            borderRadius: BorderRadius.only(bottomRight: Radius.circular(12),topRight: Radius.circular(12)),
                          ),
                        ],
                      ),

                      child: Container(
                        width: Get.width,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dialogTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.grayLight, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["message"],
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item["time"],
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  // return Dismissible(
                  //   key: UniqueKey(),
                  //   direction: DismissDirection.endToStart,
                  //   background: Container(
                  //     alignment: Alignment.centerRight,
                  //     padding: const EdgeInsets.symmetric(horizontal: 27),
                  //     decoration: BoxDecoration(
                  //       color: AppColors.red,
                  //       borderRadius: BorderRadius.circular(12),
                  //     ),
                  //     child: Image.asset(AssetsPath.deleteIcon,height: 18,width: 16)
                  //   ),
                  //   onDismissed: (_) {
                  //     controller.removeNotification(sectionIndex, index);
                  //   },
                  //   child: Container(
                  //     width: Get.width,
                  //     margin: const EdgeInsets.only(bottom: 16),
                  //     padding: const EdgeInsets.symmetric(
                  //         vertical: 14, horizontal: 14),
                  //     decoration: BoxDecoration(
                  //       color:
                  //       Theme.of(context).dialogTheme.backgroundColor,
                  //       borderRadius: BorderRadius.circular(12),
                  //       border: Border.all(
                  //           color: AppColors.grayLight, width: 1),
                  //     ),
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Text(
                  //           item["message"],
                  //           style: Theme.of(context)
                  //               .textTheme
                  //               .titleSmall
                  //               ?.copyWith(
                  //             fontWeight: FontWeight.w400,
                  //             fontSize: 16,
                  //             letterSpacing: 0,
                  //           ),
                  //         ),
                  //         const SizedBox(height: 6),
                  //         Text(
                  //           item["time"],
                  //           style: Theme.of(context)
                  //               .textTheme
                  //               .labelSmall
                  //               ?.copyWith(
                  //             fontWeight: FontWeight.w400,
                  //             fontSize: 12,
                  //             letterSpacing: 0,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // );
                }).toList(),
              ],
            );
          },
        );
      }),
    );
  }
}
