import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ntpl_ble_mesh_demo/Comman_Widget/custom_snackbar.dart';
import 'package:ntpl_ble_mesh_demo/controller/thingsboard_controller.dart';
import 'package:ntpl_ble_mesh_demo/mesh/leafy_device_count_page.dart';

class LoginController extends GetxController {
  final usernameController = TextEditingController(text: "dhaval+mesh@nistantritech.com");
  final passwordController = TextEditingController(text: "Anil#123");

  final isLoading = false.obs;

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  bool _validate() {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty) {
      AppSnackBar.show('error', 'Please enter your email.');
      return false;
    }
    if (!GetUtils.isEmail(username)) {
      AppSnackBar.show('error', 'Please enter a valid email.');
      return false;
    }
    if (password.isEmpty) {
      AppSnackBar.show('error', 'Please enter your password.');
      return false;
    }
    return true;
  }

  Future<void> login() async {
    if (!_validate()) return;

    final username = usernameController.text.trim();
    final password = passwordController.text;

    isLoading.value = true;
    try {
      final tb = Get.find<ThingsBoardController>();
      final ok = await tb.login(username, password);
      if (ok) {
        AppSnackBar.show('success', 'Login successful.');
        Get.off(() => const LeafyDeviceCountPage());
      } else {
        AppSnackBar.show('error', 'Invalid email or password.');
      }
    } catch (e) {
      AppSnackBar.show('error', 'Login failed. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
}
