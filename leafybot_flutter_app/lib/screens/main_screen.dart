import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/constant/assets_path.dart';
import 'package:leafybot_flutter_app/screens/homeScreen.dart';
import 'package:leafybot_flutter_app/screens/report_page.dart';
import 'package:leafybot_flutter_app/screens/setting/setting_page.dart';

import 'plants_page.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key});

  final RxInt selectedIndex = 0.obs;

  final List<Widget> pages =  [
    HomeScreen(),
    ReportPage(),
    MyPlantsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: pages[selectedIndex.value],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          currentIndex: selectedIndex.value,
          onTap: (index) => selectedIndex.value = index,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                AssetsPath.homeIcon,
                height: 24,
                width: 24,
              ),
              activeIcon: Image.asset(
                AssetsPath.homeFillIcon,
                color:  Theme.of(context).iconButtonTheme.style?.iconColor?.resolve({}),
                height: 24,
                width: 24,
              ),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                AssetsPath.reportIcon,
                height: 24,
                width: 24,
              ),
              activeIcon: Image.asset(
                AssetsPath.reportFillIcon,
                color:  Theme.of(context).iconButtonTheme.style?.iconColor?.resolve({}),
                height: 24,
                width: 24,
              ),
              label: "Report",
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                AssetsPath.plantIcon,
                height: 24,
                width: 24,
              ),
              activeIcon: Image.asset(
                AssetsPath.plantFillIcon,
                color:  Theme.of(context).iconButtonTheme.style?.iconColor?.resolve({}),
                height: 24,
                width: 24,
              ),
              label: "Plants",
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                AssetsPath.settingIcon,
                height: 24,
                width: 24,
              ),
              activeIcon: Image.asset(
                AssetsPath.settingFillIcon,
                color:  Theme.of(context).iconButtonTheme.style?.iconColor?.resolve({}),
                height: 24,
                width: 24,
              ),
              label: "Settings",
            ),
          ],
        ),
      );
    });
  }
}
