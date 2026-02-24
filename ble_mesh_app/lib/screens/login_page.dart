import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:ntpl_ble_mesh_demo/Comman_Widget/custom_button.dart';
import 'package:ntpl_ble_mesh_demo/Comman_Widget/custom_textfield.dart';
import 'package:ntpl_ble_mesh_demo/constant/appColors.dart';
import 'package:ntpl_ble_mesh_demo/controller/login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  LoginController get controller => Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.darkgreen,
                    AppColors.darkgreen.withOpacity(0.95),
                    const Color(0xFF0D1A1E),
                  ]
                : [
                    AppColors.darkgreen,
                    AppColors.darkgreen.withOpacity(0.92),
                    AppColors.scaffoldBackground,
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),
                _buildHeader(context),
                const SizedBox(height: 40),
                _buildCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.lock_outline_rounded,
            size: 48,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome back',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                fontSize: 28,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue to BLE Mesh',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white.withOpacity(0.9),
                fontSize: 15,
              ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: FormBuilder(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(context, 'Email'),
            const SizedBox(height: 10),
            CustomTextField(
              name: 'email',
              controller: controller.usernameController,
              hintText: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: 12,
              borderColor: AppColors.grayLight,
              errorBorderColor: AppColors.error,
              borderWidth: 1,
              textStyle: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 24),
            _buildLabel(context, 'Password'),
            const SizedBox(height: 10),
            CustomTextField(
              name: 'password',
              controller: controller.passwordController,
              hintText: 'Enter your password',
              isPassword: true,
              textInputAction: TextInputAction.done,
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: 12,
              borderColor: AppColors.grayLight,
              errorBorderColor: AppColors.error,
              borderWidth: 1,
              textStyle: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 36),
            Obx(
              () => CustomButton(
                text: controller.isLoading.value
                    ? 'Logging in...'
                    : 'Sign in',
                onPressed: controller.isLoading.value
                    ? () {}
                    : controller.login,
                height: 52,
                borderRadius: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 15,
            letterSpacing: 0,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
