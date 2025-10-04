import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/Comman_Widget/app_bar.dart';
import 'package:leafybot_flutter_app/constant/appColors.dart';

class NotificationPreferences extends StatelessWidget {
  NotificationPreferences({super.key});

  // 👇 Rx attributes directly here
  final RxBool waterReminders = false.obs;
  final RxBool weeklyReport = false.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Notification Preferences",showBack: true,centerTitle: false,),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(
              color: AppColors.grayLight,
              width: 1,
            ),
          ),
          color: Theme.of(context).cardColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 1, color: AppColors.grayLight),
              // 👇 Water Reminders switch
              Obx(() => ListTile(
                title:  Text('Water Reminders',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                trailing: Switch(
                  value: waterReminders.value,
                  onChanged: (val) => waterReminders.value = val,
                  trackOutlineColor:
                  MaterialStateProperty.all(Colors.transparent),
                  activeTrackColor: AppColors.green,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: AppColors.grayLight,
                ),
              )),
              const Divider(height: 1, color: AppColors.grayLight),
              // 👇 Weekly Report switch
              Obx(() => ListTile(
                title:  Text('Weekly Report',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                trailing: Switch(
                  value: weeklyReport.value,
                  onChanged: (val) => weeklyReport.value = val,
                  trackOutlineColor:
                  MaterialStateProperty.all(Colors.transparent),
                  activeTrackColor: AppColors.green,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: AppColors.grayLight,
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
