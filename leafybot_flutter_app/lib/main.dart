import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/constant/appColors.dart';
import 'package:leafybot_flutter_app/screens/splashScreen.dart';
import 'controller/theme_controller.dart';

void main() {
  Get.put(ThemeController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return   Obx(
            () =>GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Splash Demo',
      themeMode: themeController.theme,
      theme: ThemeData(
        brightness: Brightness.light,
        cardColor: AppColors.white,
        scaffoldBackgroundColor: AppColors.white,
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.scaffoldBackground
        ),
        cardTheme: CardThemeData(color: AppColors.white),
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.darkBlue),
        textTheme: const TextTheme(
          labelSmall: TextStyle(color: AppColors.textSecondary),
          titleSmall: TextStyle(color: AppColors.textPrimary),
          headlineSmall: TextStyle(color: AppColors.white),
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            iconColor: MaterialStateProperty.all(AppColors.darkBlue), // color for dark mode
          ),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: AppColors.darkgreen, // background
          textTheme: ButtonTextTheme.primary, // makes text use primary color
        ),
        primaryTextTheme: TextTheme(
          labelSmall: TextStyle(color: Colors.white), // ✅ forces white text
          bodyMedium: TextStyle(color: AppColors.textPrimary),   // primary text
          titleSmall: TextStyle(color:  AppColors.textSecondary),
        ),
        snackBarTheme: SnackBarThemeData(
          actionTextColor: AppColors.darkBlue,
          backgroundColor: AppColors.grayLight,

        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        dialogTheme: DialogThemeData(
            backgroundColor: Colors.white10,

        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.gray,
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          labelSmall: TextStyle(color: AppColors.gray), // softer for dark
          titleSmall: TextStyle(color: AppColors.white), // primary text white
          headlineSmall: TextStyle(color: AppColors.white), // keep white
          bodyMedium: TextStyle(color: Colors.white),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            iconColor: MaterialStateProperty.all(AppColors.gray), // color for dark mode
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.gray, // icons white in dark mode
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gray,
            foregroundColor: Colors.white, // ✅ white text
          ),
        ),
        primaryTextTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),   // primary text
          titleSmall: TextStyle(color: Colors.white),
          labelSmall: TextStyle(color: Colors.white), // ✅ forces white text
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.textPrimary, // darker snackbar
          contentTextStyle: TextStyle(color: Colors.white),
          actionTextColor: AppColors.primaryLight,
        ),
      ),
      home: LoadingScreen(),
    ));
  }
}

// import 'package:flutter/material.dart';
// import 'package:leafybot_flutter_app/src/app.dart';
//
//
// void main() => runApp(const NordicNrfMeshExampleApp());