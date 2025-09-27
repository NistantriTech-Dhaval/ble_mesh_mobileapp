import 'package:flutter/material.dart';
import 'package:flutter_intl_phone_field/flutter_intl_phone_field.dart';
import 'package:get/get.dart';

import '../../Comman_Widget/app_bar.dart';
import '../../Comman_Widget/custom_button.dart';
import '../../constant/assets_path.dart';
import '../../controller/login_page_contoller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController()); // consider Get.find()

    return Scaffold(
      appBar: const CustomAppBar(
        imagePath: AssetsPath.nameLogo,
        showBack: false,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: Get.height * 0.2),
            _buildTitle(context),
            const SizedBox(height: 12),
            _buildSubtitle(context),
            const SizedBox(height: 24),
            _buildPhoneLabel(context),
            const SizedBox(height: 10),
            _buildPhoneField(context, controller),
            const SizedBox(height: 24),
            CustomButton(
              text: "Continue",
              onPressed: controller.continueLogin,
            ),
          ],
        ),
      ),
    );
  }

  // --- UI helpers ---
  Widget _buildTitle(BuildContext context) => Text(
    "Login or Sign Up",
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: 24,
      letterSpacing: 0,
    ),
  );

  Widget _buildSubtitle(BuildContext context) => Text(
    "Please confirm your country code and\nenter your phone number",
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 14,
      letterSpacing: 0,
      fontWeight: FontWeight.w400,
    ),
  );

  Widget _buildPhoneLabel(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      "Phone number",
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontSize: 14,
        letterSpacing: 0,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _buildPhoneField(BuildContext context, LoginController controller) {
    return IntlPhoneField(
      controller: controller.phoneController,

      initialCountryCode: 'IN',
      keyboardType: TextInputType.number,
      dialogType: DialogType.showModalBottomSheet,
      dropdownIconPosition: IconPosition.trailing,
      flagsButtonPadding: const EdgeInsets.only(left: 17),
      decoration: InputDecoration(
        hintText: 'Enter phone number',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
        ),
      ),
      dropdownIcon: Icon(
        Icons.keyboard_arrow_down_outlined,
        color: Theme.of(context).iconTheme.color,
      ),
      style: TextStyle(
        color: Theme.of(context).primaryTextTheme.bodyMedium?.color,
      ),
      onChanged: (phone) {
        controller.updatePhone(phone.number);
        controller.updateCountryCode(phone.countryCode);
      },
    );
  }
}
