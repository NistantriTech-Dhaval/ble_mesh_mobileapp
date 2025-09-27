import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/Comman_Widget/app_bar.dart';
import 'package:leafybot_flutter_app/controller/device_setup_controller.dart';
import '../../constant/appColors.dart';
import '../../constant/assets_path.dart';

class SoilTypePage extends StatelessWidget {
  const SoilTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    final setupController = Get.find<DeviceSetupController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: "Select Soil Type",
        showBack: true,
        centerTitle: false,
        onBack: setupController.onBack,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _progressBar(setupController),
            const SizedBox(height: 16),
            _subtitle(context),
            const SizedBox(height: 16),
            _soilList(context, setupController),
          ],
        ),
      ),
    );
  }

  // --- Progress Bar ---
  Widget _progressBar(DeviceSetupController controller) {
    return Obx(() => Row(
      children: List.generate(4, (index) {
        return Expanded(
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: index <= controller.currentStep.value
                  ? AppColors.green
                  : AppColors.grayLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    ));
  }

  // --- Subtitle Text ---
  Widget _subtitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        "This will help us adjust the need to water for your plant",
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // --- Soil List ---
  Widget _soilList(BuildContext context, DeviceSetupController controller) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      itemCount: controller.soilList.length,
      itemBuilder: (context, index) {
        final soil = controller.soilList[index];
        return _soilCard(context, controller, soil);
      },
    );
  }

  // --- Soil Card ---
  Widget _soilCard(BuildContext context, DeviceSetupController controller, dynamic soil) {
    return Obx(() {
      final isSelected = controller.selectedSoilType.value?.id == soil.id;

      return GestureDetector(
        onTap: () => controller.selectSoil(soil),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.bgLightGreen
                : Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.green : AppColors.grayLight,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// Left side: checkmark + text
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? AppColors.green : AppColors.gray,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      color: isSelected ? Colors.white : Colors.transparent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    soil.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              /// Info icon
              GestureDetector(
                onTap: () => _showSoilInfo(context, soil),
                child: Image.asset(
                  AssetsPath.infoIcon,
                  height: 24,
                  width: 24,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // --- Soil Info Dialog ---
  void _showSoilInfo(BuildContext context, dynamic soil) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            soil.description,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      },
    );
  }
}
