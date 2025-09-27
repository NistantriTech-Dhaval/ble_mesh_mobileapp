import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/controller/device_setup_controller.dart';
import 'package:leafybot_flutter_app/screens/device_setup/soil_type_page.dart';
import '../../Comman_Widget/custom_button.dart';
import 'loaction_setup_page.dart';
import 'plant_setup_page.dart';

class DeviceSetupPage extends StatelessWidget {
  const DeviceSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final setupController = Get.put(DeviceSetupController());

    return WillPopScope(
        onWillPop: () async {
      setupController.onBack(); // ✅ call your existing logic
      return false; // prevent default pop, `onBack` handles it
    },
    child:Scaffold(
      body: Obx(() {
        // Show screen based on index
        switch (setupController.currentStep.value) {
          case 0:
            return  PlantSetupPage();
          case 1:
            return  SoilTypePage();
          case 2:
            return  PlantLocationSetupPage();
          default:
            return  PlantSetupPage();
        }
      }),
      bottomNavigationBar: Obx(
            () => Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(24, 19, 24, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CustomButton(
                text: "Continue",
                onPressed: setupController.currentStep.value != null
                    ? setupController.onContinue
                    : () {},
              ),
              const SizedBox(height: 18),
              GestureDetector(onTap:setupController.onContinue, child: Text(
                "Skip",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              )),
            ],
          ),
        ),
      ),
    )
    );
  }
}
