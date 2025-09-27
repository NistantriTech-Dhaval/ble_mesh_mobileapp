import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import '../../constant/appColors.dart';
import '../../Comman_Widget/app_bar.dart';
import '../../Comman_Widget/custom_button.dart';
import '../../constant/assets_path.dart';
import '../../controller/login_page_contoller.dart';

class OtpVerificationPage extends GetView<LoginController> {
  final String phoneNumber;
  final String countryCode;

  const OtpVerificationPage({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
  });

  @override
  Widget build(BuildContext context) {
    // Start timer only once
    if (!controller.isTimerRunning.value) {
      controller.startTimer();
    }

    return Scaffold(
      appBar: const CustomAppBar(
        imagePath: AssetsPath.nameLogo,
        showBack: true,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: Get.height * 0.2),

                _buildTitle(context),
                const SizedBox(height: 12),

                _buildSubtext(context),
                const SizedBox(height: 24),

                _buildOtpInput(context),
                const SizedBox(height: 20),

                _buildTimer(context),
                const SizedBox(height: 33),

                CustomButton(text: "Verify", onPressed: controller.verifyOtp),
                const SizedBox(height: 24),

                _buildResendRow(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Title
  Widget _buildTitle(BuildContext context) {
    return Text(
      "OTP Verification",
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontSize: 24,
        letterSpacing: 0,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Subtext with phone number + edit icon
  Widget _buildSubtext(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: "Enter the 4 digit code sent to ",
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 14,
          letterSpacing: 0,
          fontWeight: FontWeight.w400,
        ),
        children: [
          TextSpan(
            text: "$countryCode $phoneNumber",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 14,
              letterSpacing: 0,
              fontWeight: FontWeight.w400,
            ),
          ),
          WidgetSpan(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Image.asset(
                AssetsPath.editName,
                height: 18,
                width: 18,
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  /// OTP Input
  Widget _buildOtpInput(BuildContext context) {
    return Pinput(
      length: 6,
      keyboardType: TextInputType.number,
      autofocus: true,
      showCursor: true,
      controller: controller.otpController,
      defaultPinTheme: PinTheme(
        width: 50,
        height: 50,
        textStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).primaryTextTheme.bodyMedium?.color,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCCCCCC), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Timer
  Widget _buildTimer(BuildContext context) {
    return Obx(() {
      final seconds = controller.secondsRemaining.value;
      return Text(
        seconds > 0
            ? "00:${seconds.toString().padLeft(2, '0')}"
            : "Expired",
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontSize: 16,
          letterSpacing: 0,
          fontWeight: FontWeight.w400,
        ),
      );
    });
  }

  /// Resend OTP
  Widget _buildResendRow(BuildContext context) {
    return Obx(() {
      final canResend = controller.secondsRemaining.value == 0;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Didn’t receive an code? ",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 14,
              letterSpacing: 0,
              fontWeight: FontWeight.w400,
            ),
          ),
          GestureDetector(
            onTap: (){
              if(canResend==true){
                controller.resendOtp(countryCode+phoneNumber);
              }
            },
            child: Text(
              "Resend OTP",
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 14,
                letterSpacing: 0,
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.underline,
                color: canResend
                    ? AppColors.green
                    : AppColors.gray,
              ),
            ),
          ),
        ],
      );
    });
  }
}
