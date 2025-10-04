import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/Comman_Widget/app_bar.dart';
import 'package:leafybot_flutter_app/Comman_Widget/custom_button.dart';
import 'package:leafybot_flutter_app/constant/appColors.dart';
import 'package:leafybot_flutter_app/constant/assets_path.dart';
import '../Comman_Widget/main_app_bar.dart';
import '../controller/home_page_controller.dart';
import '../utils/consstant_utils.dart';

class HomeScreen extends StatelessWidget {
  final bool ?isDetailPage; // New bool parameter
  Map<String, dynamic> ?selectedPlant;
   HomeScreen({
    super.key,
    this.selectedPlant,
     this.isDetailPage=false, // Mark as required
  });


  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());

    return Scaffold(
      appBar: isDetailPage==true?
          CustomAppBar(
            title: selectedPlant!["name"],
            centerTitle: false,
            showBack: true,
          ):CustomMainAppBar(
        selectedBot: controller.selectedBot,
        deviceList: controller.deviceList,
        showActiveStatus: true,
        onDeviceSelected: (selectedBot) {
          controller.selectBot(selectedBot);
        },
      ),
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              if(isDetailPage==true)
                Image.asset(
                  ConstantUtils.getPlantImage(selectedPlant!["plantsName"]),
                  height: Get.height*0.3,
                  width: Get.width,
                  fit: BoxFit.fitWidth,
                  filterQuality: FilterQuality.high,
                ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 20,
                  bottom: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Warning Banner
                    _buildWarningBanner(
                      context: context,
                      message: "Battery Low. Please recharge or change battery.",
                    ),
                    const SizedBox(height: 16),

                    /// Greeting Card
                    _buildGreetingCard(
                      context: context,
                      greeting: "Good morning, David",
                      status: "“Rosie is feeling happy!”",
                      iconPath: AssetsPath.happyIcon,
                    ),
                    const SizedBox(height: 24),

                    /// Live Sensor Stats
                    Text(
                      "Live Sensor Stats",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 16,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Moisture Level
                    _buildStatsCard(
                      title: "Moisture Level",
                      icon: AssetsPath.moisture_Icon,
                      color: AppColors.blue,
                      backgroundcolor: AppColors.grayExtrasLight,
                      progress: 0.5,
                      value: "50%",
                      context: context,
                    ),
                    const SizedBox(height: 12),

                    /// Light
                    _buildStatsCard(
                      title: "Light Qualitative",
                      icon: AssetsPath.lightIcon,
                      value: "Medium",
                      valueicon: AssetsPath.mediumLight,
                      context: context,
                    ),
                    const SizedBox(height: 12),

                    /// Battery
                    _buildStatsCard(
                      title: "Battery Level",
                      icon: AssetsPath.battery_level_Icon,
                      progress: 0.95,
                      color: AppColors.green,
                      backgroundcolor: AppColors.grayExtrasLight,
                      value: "95%",
                      subtitle: "Power(3h)",
                      context: context,
                    ),
                    const SizedBox(height: 12),

                    /// Water Level
                    _buildStatsCard(
                      title: "Water Level",
                      icon: AssetsPath.water_level_Icon,
                      value: "15% left",
                      valueicon: AssetsPath.water_value_icon,
                      context: context,
                    ),
                    const SizedBox(height: 12),

                    ///Temperature
                    _buildStatsCard(
                      title: "Temperature",
                      icon: AssetsPath.temp_Icon,
                      progress: 0.70,
                      color: AppColors.purple,
                      backgroundcolor: AppColors.grayExtrasLight,
                      value: "70 C",
                      context: context,
                    ),
                    if(isDetailPage==false)
                      ...[
                        const SizedBox(height: 12),
                          CustomButton(text: "Sync Now",
                              assetPath: AssetsPath.sync_Icon,
                              onPressed: (){

                              }),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              "Last Sync Time:- ${DateTime.now()}",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 14,
                                letterSpacing: 0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                      ]

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// =========================
  /// Widget Methods
  /// =========================

  Widget _buildWarningBanner({
    required BuildContext context,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Image.asset(AssetsPath.alertIcon, height: 24, width: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 12,
                letterSpacing: 0,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingCard({
    required BuildContext context,
    required String greeting,
    required String status,
    required String iconPath,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 14,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        status,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 22,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Image.asset(iconPath, height: 34, width: 40),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable card builder (unchanged sizes/colors)
  Widget _buildStatsCard({
    required String title,
    required String icon,
    Color? color,
    String? value,
    double? progress,
    Color? backgroundcolor,
    String? subtitle,
    required BuildContext context,
    String? valueicon,
  }) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: AppColors.grayLight, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(icon, height: 32, width: 32),
              const SizedBox(width: 7.5),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    letterSpacing: 0,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              if (valueicon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Image.asset(valueicon, height: 65, width: 70),
                ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    color: color,
                    minHeight: 8,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    backgroundColor: backgroundcolor ?? Colors.grey.shade200,
                  ),
                ),
                if (value != null && value.isNotEmpty) ...[
                  const SizedBox(width: 21),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
