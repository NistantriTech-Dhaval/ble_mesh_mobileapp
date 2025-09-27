import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/Comman_Widget/custom_button.dart';
import 'package:leafybot_flutter_app/constant/appColors.dart';
import 'package:leafybot_flutter_app/constant/assets_path.dart';

import '../../Comman_Widget/app_bar.dart';

class TroubleshootingPage extends StatelessWidget {
  const TroubleshootingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Troubleshooting",
        showBack: true, // first page no back button
        centerTitle: false,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Bluetooth Connectivity",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Image.asset(
                    AssetsPath.alertIcon,
                    height: 24,
                    width: 24,
                    color: AppColors.red,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Power Issue",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Image.asset(AssetsPath.successIcon, height: 24, width: 24),
                ],
              ),
            ),
            Spacer(),
            CustomButton(text: "Troubleshoot Now", onPressed: () {}),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
