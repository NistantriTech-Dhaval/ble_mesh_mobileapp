import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ntpl_ble_mesh_demo/Comman_Widget/custom_snackbar.dart';
import 'package:ntpl_ble_mesh_demo/mesh/mesh_setup_option.dart';
import '../../Comman_Widget/app_bar.dart';
import '../../Comman_Widget/custom_button.dart';
import '../../constant/appColors.dart';
import '../../constant/assets_path.dart';

class LeafyDeviceCountPage extends StatelessWidget {
  const LeafyDeviceCountPage({super.key});

  @override
  Widget build(BuildContext context) {
    RxInt selected_device_count = 0.obs;
    RxInt selected_leafystick_count = 0.obs;

    return Scaffold(
      appBar: const CustomAppBar(
        showBack: false,
        title: "Ble Mesh",
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 34, top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Count
            _buildLabel(context, "How many devices do you have?"),
            const SizedBox(height: 10),
            _numberDropdownWidget(context, selected_device_count),
            const SizedBox(height: 24),

            // Leafystick Count
            _buildLabel(context, "How many Leafysticks do you have?"),
            const SizedBox(height: 10),
            _numberDropdownWidget(context, selected_leafystick_count),
            const SizedBox(height: 24),

            Spacer(),

            // Continue Button
            CustomButton(
              text: "Continue",
              onPressed: () {
                // Require at least one selection
                if ((selected_device_count.value <= 0) &&
                    (selected_leafystick_count.value <= 0)) {
                  AppSnackBar.show(
                    "error",
                    "Please select at least one option",
                  );
                  return;
                } else {
                  Get.to(MeshSetupOption(
                    device_count: selected_device_count.value,
                    leafystick_count: selected_leafystick_count.value,
                  ));
                }
              },
            ),
          ],
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

  Widget _numberDropdownWidget(BuildContext context, RxInt selected_number) {
    return Obx(() {
      RxBool isOpen = false.obs;
      String displayText =  selected_number.value.toString();

      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(color: AppColors.grayLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<int>(
            isExpanded: true,
            value: selected_number.value <= 0 ? null : selected_number.value,
            dropdownStyleData: DropdownStyleData(
              offset: const Offset(0, -4),
              isOverButton: false,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).scaffoldBackgroundColor,
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
            hint: Text(
              displayText,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            selectedItemBuilder: (context) {
              // Display items 0 to 10
              return List.generate(11, (index) {
                final number = index;
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    number.toString(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              });
            },
            items: List.generate(11, (index) {
              final number = index;
              final isSelected = selected_number.value == number;

              return DropdownMenuItem<int>(
                value: number,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (isSelected)
                      Icon(Icons.check, color: AppColors.darkBlue, size: 18),
                    SizedBox(width: isSelected ? 10 : 28),
                    Text(
                      number.toString(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
            onMenuStateChange: (opened) {
              isOpen.value = opened;
            },
            onChanged: (value) {
              if (value != null) {
                selected_number.value = value;
              }
            },
          ),
        ),
      );
    });
  }
}
