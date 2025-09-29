import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/models/plant_location_model.dart';
import 'package:leafybot_flutter_app/models/soil_type_model.dart';
import 'package:leafybot_flutter_app/repository/plantRepository.dart';
import 'package:leafybot_flutter_app/screens/main_screen.dart';

import '../Comman_Widget/custom_snackbar.dart';
import '../mesh/provisioned_devices_page.dart';
import '../models/plant_species_model.dart';
import '../utils/consstant_utils.dart';
class DeviceSetupController extends GetxController {
  /// Track the current step in setup flow (0–3)
  var currentStep = 0.obs;

  final RxList<PlantSpecies> plantsList = <PlantSpecies>[].obs;
  final RxList<PlantSpecies> filteredPlantsList = <PlantSpecies>[].obs;
  final RxList<SoilType> soilList = <SoilType>[].obs;
  final RxList<PlantLocation> plantlocationlist = <PlantLocation>[].obs;

  var selectedSoilType = Rxn<SoilType>();
  var selectedPlantSpecies = Rxn<PlantSpecies>();
  var selectedPlantLocation = Rxn<PlantLocation>();

  TextEditingController plantNickName = TextEditingController();
  TextEditingController plantLocationName = TextEditingController();

  // ✅ Loading indicators
  var isLoadingPlants = false.obs;
  var isLoadingSoil = false.obs;
  var isLoadingLocations = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadPlantSpecies();
    await loadSoilTypes();
    await loadPlantLocation();
  }

  Future<void> loadPlantSpecies() async {
    try {
      isLoadingPlants.value = true;
      final species = await PlantRepository.getAllPlantSpecies();
      plantsList.assignAll(species);
      filteredPlantsList.assignAll(species);
    } catch (e) {
      AppSnackBar.show("error", "Failed to load plants: $e");
    } finally {
      isLoadingPlants.value = false;
    }
  }

  Future<void> loadSoilTypes() async {
    try {
      isLoadingSoil.value = true;
      final soil = await PlantRepository.getAllSoilTypes();
      soilList.assignAll(soil);
    } catch (e) {
      AppSnackBar.show("error", "Failed to load soil types: $e");
    } finally {
      isLoadingSoil.value = false;
    }
  }

  Future<void> loadPlantLocation() async {
    try {
      isLoadingLocations.value = true;
      final plant_location = await PlantRepository.getAllPlantLocatinos();
      plantlocationlist.assignAll(plant_location);
    } catch (e) {
      AppSnackBar.show("error", "Failed to load plant locations: $e");
    } finally {
      isLoadingLocations.value = false;
    }
  }

  void onContinue() {
    if (currentStep.value < 2) {
      currentStep.value++;
    } else {
      Get.to(ProvisionedDevicesPage());
    }
  }

  void onBack() {
    if (currentStep.value > 0) {
      currentStep.value--;
    } else {
      Get.back();
    }
  }

  void selectSoil(SoilType soil) => selectedSoilType.value = soil;
  void selectLocation(PlantLocation location) => selectedPlantLocation.value = location;
  void selectPlant(PlantSpecies plant) => selectedPlantSpecies.value = plant;

  Future<void> addLocatino(String location_name) async {
    try {
      await PlantRepository.addPlantLocatino(location_name);
    } catch (e) {
      Get.snackbar("Error", "Failed to add location: $e");
    }
  }

  void searchPlants(String query) {
    if (query.isEmpty) {
      filteredPlantsList.assignAll(plantsList);
    } else {
      filteredPlantsList.assignAll(
        plantsList.where(
              (plant) => plant.plantName.toLowerCase().contains(query.toLowerCase()),
        ),
      );
    }
  }
}
