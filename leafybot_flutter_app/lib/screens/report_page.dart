import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/constant/appColors.dart';
import 'package:leafybot_flutter_app/constant/assets_path.dart';
import 'package:leafybot_flutter_app/utils/consstant_utils.dart';
import '../Comman_Widget/main_app_bar.dart';
import '../controller/home_page_controller.dart';
import '../controller/report_page_controller.dart';
import 'package:intl/intl.dart';

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
                _dateRangeWidget(context, controller),
                showDeviceStatus(
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
                  barValues: [0.2, 0.8, 0.6, 0.7, 0.4], // last 2 active
                  barColor: AppColors.blue,
                ),
                const SizedBox(height: 12),

                /// Example Report Card 2
                _buildReportCard(
                  title: "Light Qualitative",
                  icon: AssetsPath.lightIcon,
                  subtitle: "Low",
                  context: context,
                  barValues: [0.2, 0.8, 0.6, 0.7, 0.4], // last 2 active
                  barColor: AppColors.yellow,
                ),
                const SizedBox(height: 12),

                /// Example Report Card 3
                _buildReportCard(
                  title: "Temperature",
                  icon: AssetsPath.temp_Icon,
                  subtitle: "Ideal",
                  context: context,
                  barValues: [0.2, 0.8, 0.6, 0.7], // last 2 active
                  barColor: AppColors.purple,
                ),
                const SizedBox(height: 12),
                Text(
                  "Mood Timeline",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 16,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMoodTimeline(context),
                const SizedBox(height: 12),
                Text(
                  "Care Score",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 16,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCareScore(context),
                const SizedBox(height: 12),
                Text(
                  "Leafy's Tips",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 16,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTipWidget(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateRangeWidget(
    BuildContext context,
    ReportPageController controller,
  ) {
    return Obx(() {
      String displayText;

      if (controller.currentRange != null) {
        final start = controller.currentRange!.start;
        final end = controller.currentRange!.end;
        displayText =
            "${DateFormat.yMMMd().format(start)} - ${DateFormat.yMMMd().format(end)}";
      } else {
        displayText = controller.selected_date_range.value.isEmpty
            ? "Select Date Range"
            : controller.selected_date_range.value;
      }

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
            value: controller.selected_date_range.value.isEmpty
                ? null
                : controller.selected_date_range.value,
            dropdownStyleData: DropdownStyleData(
              offset: const Offset(0, -4),
              isOverButton: false,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).scaffoldBackgroundColor,
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
              return ConstantUtils.date_range_options.map((range) {
                if (controller.currentRange != null) {
                  final start = controller.currentRange!.start;
                  final end = controller.currentRange!.end;
                  displayText =
                      "${DateFormat.yMMMd().format(start)} - ${DateFormat.yMMMd().format(end)}";
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      displayText,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                } else {
                  return Align(
                      alignment: Alignment.centerLeft,
                      child:Text(
                    range,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ));
                }
              }).toList();
            },

            items: ConstantUtils.date_range_options.map((range) {
              final isSelected = controller.selected_date_range.value == range;

              final dateRange = controller.getPresetRange(range);
              final formattedRange = dateRange != null
                  ? "${DateFormat.yMMMd().format(dateRange.start)} - ${DateFormat.yMMMd().format(dateRange.end)}"
                  : "";

              return DropdownMenuItem<String>(
                value: range,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (isSelected)
                      Icon(Icons.check, color: AppColors.darkBlue, size: 18),
                    SizedBox(width: isSelected == false ? 28 : 10),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          range,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        if (formattedRange.isNotEmpty)
                          Text(
                            formattedRange,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (range) async {
              if (range == null) return;

              if (range == 'Custom date range') {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDateRange:
                      controller.currentRange ??
                      DateTimeRange(start: DateTime.now(), end: DateTime.now()),
                );

                if (picked != null) {
                  controller.currentRange = picked;
                  controller.selected_date_range.value = 'Custom date range';
                }
              } else {
                controller.selected_date_range.value = range;
                controller.currentRange = controller.getPresetRange(range);
              }
            },
          ),
        ),
      );
    });
  }

  /// Reusable Report Card
  Widget showDeviceStatus({
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
    List<double>? barValues,
    BuildContext? context,
    required Color barColor,
  }) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context!).cardColor,
        border: Border.all(color: AppColors.grayLight, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Column(
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
          Spacer(),
          SizedBox(
            width: 80,
            height: 50,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                barGroups: barValues!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final v = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: v * 10, // scale (0–10)
                        width: 6,
                        borderRadius: BorderRadius.circular(4),
                        color: (index >= barValues.length - 2)
                            ? barColor
                            : Colors.grey.shade300,
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(show: false), // hide labels
                gridData: FlGridData(show: false), // hide grid
                borderData: FlBorderData(show: false), // hide borders
                barTouchData: BarTouchData(enabled: false), // no touch
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipWidget(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context!).cardColor,
        border: Border.all(color: AppColors.grayLight, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Rules-based suggestions:",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 14,
              letterSpacing: 0,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          _buildTip(
            context: context,
            text: "☀️ Move me closer to light",
            bgColor: AppColors.lightOrange,
          ),
          const SizedBox(height: 8),
          _buildTip(
            context: context,
            text: "💧 You watered me well this week. Thank you!",
            bgColor: AppColors.lightBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildTip({
    required String text,
    required Color bgColor,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: Get.width,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildCareScore(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: AppColors.grayLight, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(AssetsPath.care_score_icon, height: 44, width: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "This week’s care score",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgLightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "7.8/10",
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Encourage improvement",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 14,
              letterSpacing: 0,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: Get.width,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgLightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "🌱 Let’s aim for 9 next week!",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 14,
                letterSpacing: 0,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTimeline(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: AppColors.grayLight, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildMoodItem("Mon", AssetsPath.angryIcon),
          _buildMoodItem("Tue", AssetsPath.surprisedIcon),
          _buildMoodItem("Wed", AssetsPath.sadIcon),
          _buildMoodItem("Thu", AssetsPath.happyIcon),
          _buildMoodItem("Fri", AssetsPath.sleepyIcon),
          _buildMoodItem("Sat", AssetsPath.neutralIcon),
          _buildMoodItem("Sun", AssetsPath.angryIcon),
        ],
      ),
    );
  }

  Widget _buildMoodItem(String day, String assetPath) {
    return Column(
      children: [
        Text(
          day,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Image.asset(assetPath, height: 37, width: 37),
        //   Text(emoji, style: TextStyle(fontSize: 22, color: color)),
      ],
    );
  }
}
