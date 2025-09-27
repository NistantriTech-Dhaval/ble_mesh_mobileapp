import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/constant/appColors.dart';
import 'package:leafybot_flutter_app/constant/assets_path.dart';
import 'package:leafybot_flutter_app/utils/consstant_utils.dart';
import '../Comman_Widget/main_app_bar.dart';
import '../controller/home_page_controller.dart';
import '../controller/report_page_controller.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ReportPageController controller = Get.put(ReportPageController());

    return Scaffold(
      appBar: CustomMainAppBar(
        selectedBot: controller.selectedBot,
        deviceList: controller.deviceList,
        onDeviceSelected: (selectedBot) {
          controller.selectBot(selectedBot);
        },
      ),
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Report Title
                Text(
                  "Date Range",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 10),
                Obx(() {
                  return Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border.all(color: AppColors.grayLight),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        value: controller
                            .selected_date_range
                            .value, // ✅ ensure correct type
                        dropdownStyleData: DropdownStyleData(
                          offset: const Offset(0, -4),
                          isOverButton: false,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context).scaffoldBackgroundColor,
                          ),
                        ),
                        hint: Text(
                          "Select Bot",
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontSize: 14,
                                letterSpacing: 0,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                        items: ConstantUtils.date_range_options.map((device) {
                          return DropdownMenuItem<String>(
                            value: device,
                            child: Row(
                              children: [
                                Text(
                                  device,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontSize: 14,
                                        letterSpacing: 0,
                                        fontWeight: FontWeight.w400,
                                      ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (device) {
                          if (device != null) {
                            // selectedBot?.assignAll(device);
                            // onDeviceSelected?.call(device);
                          }
                        },
                        onMenuStateChange: (opened) {},
                      ),
                    ),
                  );
                }),
                buildReportCard(
                  name: "Rosie",
                  message: "I had a great week!",
                  iconPath: AssetsPath.happyIcon,
                  backgroundColor: AppColors.bgLightGreen,
                  context: context,
                ),

                Text(
                  "Health Summary",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 16,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                /// Example Report Card 1
                _buildReportCard(
                  title: "Moisture Level",
                  icon: AssetsPath.moisture_Icon,
                  subtitle: "Good",
                  context: context,
                ),
                const SizedBox(height: 12),

                /// Example Report Card 2
                _buildReportCard(
                  title: "Light Qualitative",
                  icon: AssetsPath.lightIcon,
                  subtitle: "Low",
                  context: context,
                ),
                const SizedBox(height: 12),

                /// Example Report Card 3
                _buildReportCard(
                  title: "Temperature",
                  icon: AssetsPath.temp_Icon,
                  subtitle: "Ideal",
                  context: context,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Reusable Report Card
  Widget buildReportCard({
    required String name,
    required String message,
    required String iconPath,
    required Color backgroundColor,
    BuildContext? context,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      child: Container(
        width: Get.width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name
            Text(
              "Hi, I'm $name!",
              style: Theme.of(context!).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 5),

            // Icon
            Image.asset(iconPath, height: 66, width: 66),
            const SizedBox(height: 5),

            // Message
            Text(
              '"$message"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable Report Card
  Widget _buildReportCard({
    required String title,
    required String icon,
    String? subtitle,
    BuildContext? context,
  }) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context!).cardColor,
        border: Border.all(color: AppColors.grayLight, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(icon, height: 24, width: 24),
              const SizedBox(width: 7.5),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
