import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/Comman_Widget/app_bar.dart';
import 'package:leafybot_flutter_app/Comman_Widget/circular_progressbar.dart';
import 'package:leafybot_flutter_app/Comman_Widget/custom_textfield.dart';
import '../../controller/device_setup_controller.dart';
import '../../constant/appColors.dart';
import '../../constant/assets_path.dart';

class PlantSetupPage extends StatelessWidget {
  const PlantSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final setupController = Get.put(DeviceSetupController());

    return Scaffold(
      appBar: CustomAppBar(
        title: "Select Plant Type",
        showBack: true,
        centerTitle: false,
        onBack: setupController.onBack,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _progressBar(setupController),
          const SizedBox(height: 16),
          _subtitle(context),
          const SizedBox(height: 18),
          _searchField(context, setupController),
          const SizedBox(height: 16),
          _plantGrid(setupController),
        ],
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
                  : AppColors.grayExtrasLight,
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
        "Search by plant name or Not sure the type of plant? Click photo for us to identify",
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // --- Search Field ---
  Widget _searchField(BuildContext context, DeviceSetupController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: CustomTextField(
        hintText: "Search products",
        textStyle: Theme.of(context).textTheme.titleSmall,
        prefixIcon: const Icon(Icons.search, color: AppColors.gray),
        filterIcon: Image.asset(
          AssetsPath.selectImage,
          height: 25,
          width: 25,
        ),
        onFilterTap: () => print("Filter tapped"),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: 12,
        borderColor: AppColors.grayLight,
        errorBorderColor: Colors.red,
        borderWidth: 1,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        filterBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
        filterBorderColor: AppColors.grayLight,
        filterBorderWidth: 1,
        filterBorderRadius: 10,
        filterSpacing: 15,
        onChanged: (value) => controller.searchPlants(value??""),
      ),
    );
  }

  // --- Plant Grid ---
  Widget _plantGrid(DeviceSetupController controller) {
    return Expanded(
      child: Obx(() {
          if (controller.isLoadingPlants.value) {
          return const  CircularProgressLoader();
        } else {
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 16,
                childAspectRatio: 1.6,
              ),
              itemCount: controller.filteredPlantsList.length,
              itemBuilder: (context, index) {
                final plant = controller.filteredPlantsList[index];
                return _plantCard(controller, plant);
              },
            );
          }})
    );
  }

  // --- Plant Card ---
  Widget _plantCard(DeviceSetupController controller, dynamic plant) {
    return Obx(() {
      final isSelected = controller.selectedPlantSpecies == plant;

      return GestureDetector(
        onTap: () => controller.selectPlant(plant),
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
                child: Image.network(
                  plant.imageUrl ?? "",
                  height: 40,
                  width: 40,
                  fit: BoxFit.fitHeight,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child; // image loaded
                    return CircularProgressLoader();
                  },
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.local_florist, size: 40),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                plant.plantName ?? "Unknown Plant",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
