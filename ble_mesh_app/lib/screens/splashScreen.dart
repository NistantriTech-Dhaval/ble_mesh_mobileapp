import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ntpl_ble_mesh_demo/constant/assets_path.dart';
import 'package:ntpl_ble_mesh_demo/controller/thingsboard_controller.dart';
import 'package:ntpl_ble_mesh_demo/screens/home_page.dart';
import 'package:ntpl_ble_mesh_demo/screens/login_page.dart';

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      final tb = Get.find<ThingsBoardController>();
      await tb.ensureValidToken();
      if (tb.isAuthenticated) {
        Get.off(() => const HomePage());
      } else {
        Get.off(() => const LoginPage());
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(color: Color(0xFF002B34)),
        child: Center(
          child: Image(
            image: AssetImage(AssetsPath.splashLogo),
          ),
        ));
  }
}
