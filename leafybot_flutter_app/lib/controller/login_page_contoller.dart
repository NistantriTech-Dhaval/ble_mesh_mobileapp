import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:leafybot_flutter_app/constant/appColors.dart';
import 'package:leafybot_flutter_app/screens/auth/otp_verification.dart';
import 'package:leafybot_flutter_app/screens/auth/profile_page.dart';
import 'package:leafybot_flutter_app/screens/auth/welcome_page.dart';
import 'package:leafybot_flutter_app/screens/main_screen.dart';
import 'package:leafybot_flutter_app/utils/sharedPrefrenceUtils.dart';

import '../Comman_Widget/custom_dialog.dart';
import '../Comman_Widget/custom_snackbar.dart';
import '../constant/assets_path.dart';
import '../repository/authRepository.dart';

class LoginController extends GetxController {
  // Observables
  var countryCode = "+91".obs;
  var phoneNumber = "".obs;
  RxInt secondsRemaining = 60.obs;
  // Text controller
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  Timer? _timer;
  var isTimerRunning = false.obs;
  // Update phone number
  void updatePhone(String number) {
    phoneNumber.value = number;
  }

  // Update country code
  void updateCountryCode(String code) {
    countryCode.value = code;
  }

  Future<void> continueLogin() async {
    if (phoneNumber.value.isEmpty) {
      AppSnackBar.show("Error", "Please enter phone number");
      return;
    }

    try {
      // Call API
      final response = await AuthRepository.sendOtp(
        countryCode.value + phoneNumber.value,
      );

      if (response.success) {
        // ✅ OTP Sent, navigate to verification screen
        AppSnackBar.show("Success", "OTP sent successfully");

        Get.to(
          () => OtpVerificationPage(
            phoneNumber: phoneNumber.value,
            countryCode: countryCode.value,
          ),
        );
      } else {
        // ❌ API returned failure
        AppSnackBar.show("Error", response.message);
      }
    } catch (e) {
      // ❌ Handle exceptions like network error, parsing error
      AppSnackBar.show("Error", e.toString());
    }
  }

  void startTimer() {
    isTimerRunning.value = true;
    secondsRemaining.value = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        timer.cancel();
        isTimerRunning.value = false;
      }
    });
  }

  Future<void> verifyOtp() async {
    if (otpController.text.isEmpty || otpController.text.length < 6) {
      AppSnackBar.show("error", "Please enter the OTP");
      return;
    }
    try {
      final response = await AuthRepository.login(
        countryCode.value + phoneNumber.value,
        otpController.text,
      );
      await Preferences.setString(LeafPreferences.accessToken, response.token);
      await Preferences.setString(LeafPreferences.userId, response.userId);
      await Preferences.setString(LeafPreferences.phoneNumber, response.phoneNumber,);

      Get.dialog(
        SuccessPopup(
          title: 'Success!',
          message: 'Congratulations! You have been successfully authenticated',
          imageAsset: AssetsPath.successIcon,
          buttonText: 'Continue',
          onButtonPressed: () {
            Get.back();
            if (response.isProfileComplete == true) {
              Get.offAll(MainScreen());
            } else {
              Get.offAll(ProfilePage());
            }
          },
        ),
        barrierDismissible:
            false, // optional: prevent closing by tapping outside
      );
    } catch (e) {
      // Close loader if error
      if (Get.isDialogOpen ?? false) Get.back();

      // 🔹 Show error snackbar
      AppSnackBar.show("error", e.toString());
    }
  }

  Future<void> resendOtp(String number) async {
    try {
      // Call API
      final response = await AuthRepository.sendOtp(number);

      if (response.success) {
        // ✅ OTP Sent, navigate to verification screen
        startTimer();
        AppSnackBar.show("Success", "OTP sent successfully");
      } else {
        // ❌ API returned failure
        AppSnackBar.show("Error", response.message);
      }
    } catch (e) {
      // ❌ Handle exceptions like network error, parsing error
      AppSnackBar.show("Error", e.toString());
    }
  }

  Future<void> updateProfile() async {
    final name = fullNameController.text.trim();
    final email = emailController.text.trim();
    try {
      if (!isValidEmail(email)) {
        AppSnackBar.show("error", "Please enter a valid email");
        return;
      }
      final response = await AuthRepository.updateProfile(name, email);
      if(response.success==true){
        Get.to(WelcomePage());
      }
    } catch (e) {
      // ❌ Handle exceptions like network error, parsing error
      AppSnackBar.show("Error", e.toString());
    }
  }

  bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    return emailRegex.hasMatch(email);
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }
}
