import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import '../../Comman_Widget/circular_progressbar.dart';
import '../../controller/device_setup_controller.dart';
import '../../Comman_Widget/app_bar.dart';
import '../../Comman_Widget/custom_textfield.dart';
import '../../Comman_Widget/custom_button.dart';
import '../../constant/appColors.dart';
import '../../constant/assets_path.dart';
import '../../utils/consstant_utils.dart';

class PlantLocationSetupPage extends StatelessWidget {
  const PlantLocationSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final setupController = Get.find<DeviceSetupController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: "Nickname & Plant Location",
        showBack: true,
        centerTitle: false,
        onBack: setupController.onBack,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(setupController),
          const SizedBox(height: 20),
          _buildPlantNameInput(context, setupController),
          const SizedBox(height: 27),
          _buildLocationLabel(context),
          const SizedBox(height: 16),
          _buildLocationGrid(context, setupController),
        ],
    ));
  }

  // --- Progress Bar ---
  Widget _buildProgressBar(DeviceSetupController controller) {
    return Obx(
          () => Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: index <= controller.currentStep.value
                    ? AppColors.green
                    : AppColors.grayExtrasLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- Plant Name Input ---
  Widget _buildPlantNameInput(BuildContext context, DeviceSetupController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Plant Name",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          CustomTextField(
            hintText: "Enter Plant name",
            controller: controller.plantNickName,
            textStyle: Theme.of(context).textTheme.titleSmall,
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: 12,
            borderColor: AppColors.grayLight,
            errorBorderColor: Colors.red,
            borderWidth: 1,
          ),
          const SizedBox(height: 8),
          Text(
            "Length (max 20 chars), special characters",
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  // --- Location Label ---
  Widget _buildLocationLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        "Select Plant Location",
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // --- Location Grid ---
  Widget _buildLocationGrid(BuildContext context, DeviceSetupController controller) {
    return Expanded(
      child: Obx(() {
        if (controller.isLoadingPlants.value) {
          return const CircularProgressLoader();
        } else {
          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 16,
              childAspectRatio: 1.6,
            ),
            itemCount: controller.plantlocationlist.length + 1,
            itemBuilder: (context, index) {
              if (index == controller.plantlocationlist.length) {
                return _buildAddLocationCard(context, controller);
              }
              final location = controller.plantlocationlist[index];
              return _buildLocationCard(controller, location);
            },
          );
        }
      }
      ),
    );
  }

  // --- Add Location Card ---
  Widget _buildAddLocationCard(BuildContext context, DeviceSetupController controller) {
    return GestureDetector(
      onTap: () => _showAddLocationModal(context, controller),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grayLight, width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                AssetsPath.addIcon,
                height: 24,
                width: 24,
              ),
              const SizedBox(height: 10),
              Text(
                "Other",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Location Card ---
  Widget _buildLocationCard(DeviceSetupController controller, dynamic location) {
    return Obx(
          () {
        final isSelected =
            controller.selectedPlantLocation.value?.id == location.id;

        return GestureDetector(
          onTap: () => controller.selectLocation(location),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.bgLightGreen
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.green : AppColors.grayLight,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    ConstantUtils.getLocationImage(location.location),
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  location.location,
                  style: Theme.of(Get.context!).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Add Location Modal ---
  void _showAddLocationModal(BuildContext context, DeviceSetupController controller) {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Important: allows full height modal
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return  FormBuilder(
            key: controller.formKey,
            child:Padding(
          // This padding allows the sheet to move up when the keyboard opens
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Important: shrink to content
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.grayLight)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text(
                        "Add Plant Location",
                        style: Theme.of(Get.context!).textTheme.titleSmall?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child:  Icon(Icons.close, color: AppColors.gray),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child:  Text(
                    "Location Name",
                    style: Theme.of(Get.context!).textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CustomTextField(
                    hintText: "Enter Location name",
                    controller: textController,
                    textStyle: Theme.of(context).textTheme.titleSmall,
                    filled: true,
                    isRequired: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: 12,
                    borderColor: AppColors.grayLight,
                    errorBorderColor: Colors.red,
                    borderWidth: 1,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  child: CustomButton(
                    text: "Add",
                    onPressed: () async {
                      if (controller.formKey.currentState!.validate()) {
                        await controller.addLocatino(textController.text);
                        await controller.loadPlantLocation();
                        Get.back();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ));
      },
    );

  }
}
