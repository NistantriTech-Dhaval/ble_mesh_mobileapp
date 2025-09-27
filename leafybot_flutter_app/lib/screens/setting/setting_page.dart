import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/constant/appColors.dart';
import 'package:leafybot_flutter_app/constant/assets_path.dart';
import 'package:leafybot_flutter_app/controller/theme_controller.dart';
import 'package:leafybot_flutter_app/screens/setting/contact_support.dart';
import 'package:leafybot_flutter_app/screens/setting/faqs_page.dart';
import 'package:leafybot_flutter_app/screens/setting/global_preference.dart';
import 'package:leafybot_flutter_app/screens/setting/notification_preferences.dart';
import 'package:leafybot_flutter_app/screens/setting/plants_care_page.dart';
import 'package:leafybot_flutter_app/screens/setting/reset_unpair_devise.dart';
import 'package:leafybot_flutter_app/screens/setting/troubleshooting_page.dart';
import '../../Comman_Widget/main_app_bar.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: CustomMainAppBar(title: "Settings"),
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("General"),
              const SizedBox(height: 16),
              _settingsCard(context, [
                _settingsTile(
                  context,
                  leading: Image.asset(AssetsPath.version_Icon, height: 24, width: 24),
                  title: 'Device Firmware Version',
                  onTap: () {},
                ),
                _divider(),
                _settingsTile(
                  context,
                  leading: Image.asset(AssetsPath.theme_Icon, height: 24, width: 24),
                  title: 'App Theme',
                  trailing: Switch(
                    value: themeController.isDarkMode.value,
                    onChanged: (val) => themeController.toggleTheme(val),
                    trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                    activeTrackColor: AppColors.green,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: AppColors.grayLight,
                  ),
                ),
                _divider(),
                _settingsTile(
                  context,
                  leading: Image.asset(AssetsPath.notificationIcon, height: 24, width: 24, color: AppColors.gray),
                  title: 'Notification Preferences',
                  onTap: () => Get.to(NotificationPreferences()),
                ),
                _divider(),
                _settingsTile(
                  context,
                  leading: Image.asset(AssetsPath.unpair_Icon, height: 24, width: 24),
                  title: 'Reset / Unpair device',
                  onTap: () => Get.to(ResetUnpairDevice()),
                ),
                _divider(),
                _settingsTile(
                  context,
                  leading: Image.asset(AssetsPath.settingIcon, height: 24, width: 24),
                  title: 'Global Preferences',
                  onTap: () => Get.to(GlobalPreferencesPage()),
                ),
              ]),
              const SizedBox(height: 20),
              _sectionTitle("Help & FAQs"),
              const SizedBox(height: 16),
              _settingsCard(context, [
                _settingsTile(
                  context,
                  leading: Image.asset(AssetsPath.faqs_Icon, height: 24, width: 24),
                  title: 'FAQs',
                  onTap: () => Get.to(FaqsPage()),
                ),
                _divider(),
                _settingsTile(
                  context,
                  leading: Image.asset(AssetsPath.plantIcon, height: 24, width: 24),
                  title: 'How to care for common plants',
                  onTap: () => Get.to(PlantCarePage()),
                ),
                _divider(),
                _settingsTile(
                  context,
                  leading: Image.asset(AssetsPath.alertIcon, height: 24, width: 24, color: AppColors.gray),
                  title: 'Troubleshooting Bluetooth / Power Issues',
                  onTap: () => Get.to(TroubleshootingPage()),
                ),
                _divider(),
                _settingsTile(
                  context,
                  leading: Image.asset(AssetsPath.support_Icon, height: 24, width: 24),
                  title: 'Contact Support',
                  onTap: () => Get.to(ContactSupportPage()),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // --- Section Title ---
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        letterSpacing: 0,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // --- Divider ---
  Widget _divider() => const Divider(height: 1, color: AppColors.grayLight);

  // --- Settings Card ---
  Widget _settingsCard(BuildContext context, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.grayLight, width: 1),
      ),
      color: Theme.of(context).cardColor,
      child: Column(children: children),
    );
  }

  // --- Settings Tile ---
  Widget _settingsTile(
      BuildContext context, {
        required String title,
        Widget? leading,
        Widget? trailing,
        VoidCallback? onTap,
      }) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontSize: 14,
          letterSpacing: 0,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
