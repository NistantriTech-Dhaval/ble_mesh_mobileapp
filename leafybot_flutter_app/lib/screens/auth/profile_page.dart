import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';

import '../../Comman_Widget/app_bar.dart';
import '../../Comman_Widget/custom_button.dart';
import '../../Comman_Widget/custom_snackbar.dart';
import '../../Comman_Widget/custom_textfield.dart';
import '../../constant/appColors.dart';
import '../../constant/assets_path.dart';
import '../../controller/login_page_contoller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController()); // or Get.find()

    return Scaffold(
      appBar: const CustomAppBar(
        imagePath: AssetsPath.nameLogo,
        showBack: false,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FormBuilder(
    key: controller.formKey,
    child:SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: Get.height * 0.25),

            // Full Name
            _buildLabel(context, "Full Name"),
            const SizedBox(height: 10),
            CustomTextField(
              hintText: "Enter your full name",
              controller: controller.fullNameController,
              textStyle: Theme.of(context).textTheme.titleSmall,
              filled: true,
              isRequired: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: 12,
              borderColor: AppColors.grayLight,
              errorBorderColor: Colors.red,
              borderWidth: 1,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
            ),

            const SizedBox(height: 24),

            // Email
            _buildLabel(context, "Email"),
            const SizedBox(height: 10),
            CustomTextField(
              hintText: "Enter your email",
              controller: controller.emailController,
              textStyle: Theme.of(context).textTheme.titleSmall,
              filled: true,
              isRequired: true,
              isvalidemail: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: 12,
              borderColor: AppColors.grayLight,
              errorBorderColor: Colors.red,
              borderWidth: 1,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
            ),

            const SizedBox(height: 24),

            // Continue Button
            CustomButton(
              text: "Continue",
              onPressed: controller.updateProfile, // call API or next step
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildLabel(BuildContext context, String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontSize: 14,
        letterSpacing: 0,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
