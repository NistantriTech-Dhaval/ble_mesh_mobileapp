import 'package:get/get.dart';

import '../Comman_Widget/custom_snackbar.dart';
import '../models/pot_device_model.dart';
import '../repository/plantRepository.dart';

class PlantsController extends GetxController {

  final isScanning = false.obs;
  final RxList<PotDeviceModel> potDeviceList = <PotDeviceModel>[].obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadPotDeviceList();
  }

  Future<void> loadPotDeviceList() async {
    try {
      isScanning.value = true;
      final pot_device = await PlantRepository.getAllPotDevices();
      potDeviceList.assignAll(pot_device);
    } catch (e) {
      AppSnackBar.show("error", "Failed to load Pots: $e");
    } finally {
      isScanning.value = false;
    }
  }

  /// Remove a plant by index
  void removePlant(int index) {
   // plants.removeAt(index);
  }

}
