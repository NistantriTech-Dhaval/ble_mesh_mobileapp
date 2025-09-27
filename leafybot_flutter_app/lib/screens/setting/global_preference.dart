import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/utils/consstant_utils.dart';
import '../../Comman_Widget/app_bar.dart';
import '../../Comman_Widget/custom_button.dart';
import '../../constant/appColors.dart';
import '../../constant/assets_path.dart';
import '../../controller/global_preference_controller.dart';

class GlobalPreferencesPage extends StatelessWidget {
  final controller = Get.put(GlobalPreferencesController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Global Preferences",
        showBack: true, // first page no back button
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            "Sleep Schedule Configuration",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 16,
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          Obx(
            () => Column(
              children: List.generate(controller.devices.length, (index) {
                final device = controller.devices[index];
                final Duration? goal = (device["goal"] as Rxn<Duration>).value;

                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.grayLight, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Device name + id
                        Flexible(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device["name"].toString(),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontSize: 14,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                device["id"].toString(),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontSize: 14,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Flexible(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () async {
                              showSleepScheduleDialog();
                            },
                            child: goal == null
                                ? OutlinedButton(
                                    style: ButtonStyle(
                                      shape: MaterialStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ), // square corners
                                        ),
                                      ),
                                      side: MaterialStateProperty.all(
                                        BorderSide(
                                          color: AppColors.darkgreen,
                                          width: 1,
                                        ), // border color & width
                                      ),
                                    ),
                                    onPressed: () {
                                      showSleepScheduleDialog();
                                    },
                                    child: Text(
                                      "Set Sleep Goal",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                    ),
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          controller.formatDuration(
                                            goal ?? Duration(),
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                              ),
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),
          Text(
            "Display Brightness",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 16,
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grayLight, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Brightness Level",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Obx(() {
                  return SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 8.0, // set your desired height here
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                      ),
                    ),
                    child: Slider(
                      padding: EdgeInsets.only(left: 0, right: 0, top: 14),
                      value: controller.brightness_level.value,
                      inactiveColor: AppColors.grayLight,
                      onChanged: (val) =>
                          controller.brightness_level.value = val,
                      activeColor: AppColors.green,
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            "Reading Frequency",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 16,
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 73,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grayLight, width: 1),
            ),
            child: Row(
              children: [
                Flexible(
                  flex: 3,
                  child: Text(
                    "Sensor Sampling Interval",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Spacer(),
                Flexible(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => reading_frequency_ui(context),
                    child: Obx(
                      () => Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              controller.selected_reading_frequency.value,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                              softWrap: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showSleepScheduleDialog() {
    final RxInt selectedHour = 2.obs;
    final RxInt selectedMinute = 20.obs;

    final List<int> hours = List.generate(25, (index) => index); // 0 to 24
    final List<int> minutes = List.generate(7, (index) => index * 10);

    Get.defaultDialog(
      contentPadding: EdgeInsets.only(left: 24, right: 24, bottom: 10),
      titlePadding: EdgeInsets.all(0),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.grayLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Set Sleep Schedule",
                  style: Theme.of(Get.context!).textTheme.titleSmall?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                GestureDetector(
                  onTap: () => Get.back(),
                  child: Icon(
                    Icons.close,
                    color: Theme.of(Get.context!).iconTheme.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  child: Obx(
                    () => CupertinoPicker(
                      itemExtent: 40,
                      looping: true,
                      scrollController: FixedExtentScrollController(
                        initialItem: selectedHour.value,
                      ),
                      onSelectedItemChanged: (index) {
                        selectedHour.value = hours[index];
                      },
                      selectionOverlay: Container(
                        height: 40, // same as itemExtent
                        padding: EdgeInsets.only(top: 10, bottom: 10),
                        margin: EdgeInsets.only(left: 10, right: 10),
                        decoration: BoxDecoration(
                          color: Colors.transparent, // red overlay
                          border: Border(
                            top: BorderSide(color: AppColors.gray, width: 0.7),
                            bottom: BorderSide(
                              color: AppColors.gray,
                              width: 0.7,
                            ),
                          ),
                        ),
                      ),
                      children: hours.map((h) {
                        final isSelected =
                            h == selectedHour.value; // check if selected
                        return Center(
                          child: Text(
                            isSelected
                                ? '${h.toString().padLeft(2, '0')} Hours'
                                : '${h.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: isSelected ? 18 : 16,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(
                    () => CupertinoPicker(
                      itemExtent: 40,
                      looping: true,
                      selectionOverlay: Container(
                        height: 40, // same as itemExtent
                        padding: EdgeInsets.only(top: 10, bottom: 10),
                        margin: EdgeInsets.only(left: 10, right: 10),
                        decoration: BoxDecoration(
                          color: Colors.transparent, // red overlay
                          border: Border(
                            top: BorderSide(color: AppColors.gray, width: 0.7),
                            bottom: BorderSide(
                              color: AppColors.gray,
                              width: 0.7,
                            ),
                          ),
                        ),
                      ),
                      scrollController: FixedExtentScrollController(
                        initialItem: minutes.indexOf(selectedMinute.value),
                      ),
                      onSelectedItemChanged: (index) {
                        selectedMinute.value = minutes[index];
                      },
                      children: minutes.asMap().entries.map((entry) {
                        final isSelected =
                            entry.value ==
                            selectedMinute.value; // check if selected
                        return Center(
                          child: Text(
                            isSelected
                                ? '${entry.value.toString().padLeft(2, '0')} Min'
                                : '${entry.value.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: isSelected ? 18 : 16,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  "Cancel",
                  style: Theme.of(Get.context!).textTheme.labelSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              CustomButton(
                text: "Set",
                onPressed: () {},
                width: 84,
                height: 40,
              ),
            ],
          ),
        ],
      ),
      radius: 10,
    );
  }

  reading_frequency_ui(BuildContext context) {
    final tempSelected = controller.selected_reading_frequency.value.obs;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets, // safe padding
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(
                    left: 24.0,
                    right: 24,
                    bottom: 20,
                    top: 20,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.grayLight),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Reading Frequency",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Icon(
                          Icons.close,
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Options list
                ...ConstantUtils.reading_frequency_options.map((option) {
                  final isSelected = tempSelected.value == option;
                  return GestureDetector(
                    onTap: () => tempSelected.value = option,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.bgLightGreen
                            : AppColors.white,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.green
                              : AppColors.grayLight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            option,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check, color: Colors.green),
                        ],
                      ),
                    ),
                  );
                }),

                // Save button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: CustomButton(
                    text: "Save",
                    onPressed: () {
                      controller.selected_reading_frequency.value =
                          tempSelected.value;
                      Get.back();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
