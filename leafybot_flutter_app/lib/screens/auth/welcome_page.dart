import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:leafybot_flutter_app/constant/appColors.dart';
import 'package:leafybot_flutter_app/Comman_Widget/custom_button.dart';
import 'package:leafybot_flutter_app/screens/device_setup/plant_setup_page.dart';

import '../../Comman_Widget/app_bar.dart';
import '../../constant/assets_path.dart';
import '../device_setup/device_setup_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  CustomAppBar(
        backButtonPath: AssetsPath.backButton,
        imagePath:  AssetsPath.nameLogo,
        showBack: false,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body:  Padding(
          padding:  EdgeInsets.only(left: 24.0,right: 24,bottom: 44,top: Get.height*0.25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                'assets/leafybot_green_logo.png', // your uploaded image path
                height: 100,width: 100,

              ),
            SizedBox(height: 24,),
               Text(
                'Welcome to LeafyBot',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 24,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w500,
                ),

              ),
              const SizedBox(height: 12),
              // Subtitle
               Text(
                'LeafyBot helps your plant speak with emotions!',
                textAlign: TextAlign.center,
                 style: Theme.of(context).textTheme.labelSmall?.copyWith(
                   fontSize: 16,
                   letterSpacing: 0,
                   fontWeight: FontWeight.w400,
                 ),
              ),
              Spacer(),
              // Get Started button
              CustomButton(text: "Get Started", onPressed:(){
                Get.to(DeviceSetupPage());
              })
            ],
          ),
        ),
    );
  }
}
