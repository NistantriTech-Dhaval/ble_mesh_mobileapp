import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/mesh/mesh_scan_and_provisioning.dart';
import '../../Comman_Widget/app_bar.dart';
import '../../Comman_Widget/custom_button.dart';
import '../Comman_Widget/custom_snackbar.dart';
import '../constant/appColors.dart';

class MeshSetupOption extends StatelessWidget {
  final int leafybot_count;
  final int leafystick_count;

  MeshSetupOption({
    super.key,
    required this.leafybot_count,
    required this.leafystick_count,
  });

  @override
  Widget build(BuildContext context) {
    // RxInt to track selected option: 1=LeafyBot, 2=LeafyStick
    final RxInt selected_mesh_type = 0.obs;

    return Scaffold(
      appBar: const CustomAppBar(
        showBack: true,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 34,
          top: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSuggestion(context, leafybot_count,leafystick_count),
            _buildLabel(context, "Select Option"),
            const SizedBox(height: 16),

            // Options
            _meshTypeCard(
              context,
              "Mesh Setup",
              1,
              selected_mesh_type,
            ),
            _meshTypeCard(
              context,
              "Standalone Setup",
              2,
              selected_mesh_type,
            ),

            const Spacer(),

            CustomButton(text: "Continue", onPressed: () {
              if(selected_mesh_type.value==0){
                AppSnackBar.show(
                  "error",
                  "Please select at least one option",
                );
              }else{
                Get.to(ScanningAndProvisioning(selected_mesh_option: selected_mesh_type.value,));
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestion(BuildContext context, int leafybotCount, int leafystickCount) {
    // Determine suggestion text based on counts
    String suggestionText;
    if (leafybotCount > 1 || leafystickCount > 1) {
      suggestionText = "We Recommend to use BLE Mesh";
    } else if (leafybotCount == 1 && leafystickCount == 1) {
      suggestionText = "We Recommend to use BLE Mesh";
    } else {
      suggestionText = "We Recommend to use Standalone";
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        suggestionText,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontSize: 14,
          letterSpacing: 0,
          color: AppColors.green,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontSize: 16,
        letterSpacing: 0,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _meshTypeCard(
    BuildContext context,
    String name,
    int optionValue,
    RxInt selected_mesh_type,
  ) {
    return Obx(() {
      final isSelected = selected_mesh_type.value == optionValue;

      return GestureDetector(
        onTap: () => selected_mesh_type.value = optionValue,
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
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 16,
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
