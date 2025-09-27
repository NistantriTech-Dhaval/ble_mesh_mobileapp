
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/screens/device_setup/device_setup_page.dart';
import 'package:leafybot_flutter_app/screens/main_screen.dart';

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Get.off(() =>  MainScreen());
    });
  }


  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(color: Color(0xFF002B34)),
        child: Center(
          child: Image(
            image: AssetImage('assets/splash_logo.png'),
          ),
        ));
  }
}
