import 'package:flutter/cupertino.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/models/plant_location_model.dart';
import 'package:leafybot_flutter_app/models/pot_register_model.dart';
import 'package:leafybot_flutter_app/models/soil_type_model.dart';
import 'package:leafybot_flutter_app/repository/plantRepository.dart';
import 'package:nordic_nrf_mesh/nordic_nrf_mesh.dart';
import '../Comman_Widget/custom_snackbar.dart';
import '../mesh/provisioned_devices_page.dart';
import '../models/plant_species_model.dart';

class DeviceSetupController extends GetxController {
  /// Track the current step in setup flow (0–3)
  var currentStep = 0.obs;

  final RxList<PlantSpecies> plantsList = <PlantSpecies>[].obs;
  final RxList<PlantSpecies> filteredPlantsList = <PlantSpecies>[].obs;
  final RxList<SoilType> soilList = <SoilType>[].obs;
  final RxList<PlantLocation> plantlocationlist = <PlantLocation>[].obs;
  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
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

  Future<void> onContinue(   DiscoveredDevice device,ProvisionedMeshNode meshNode) async {
    if (currentStep.value < 2) {
      currentStep.value++;
    } else {
      try {
        int unicastAddress=await meshNode.unicastAddress;
        await PlantRepository.registerDevice(
          PotRegisterModel(
            deviceId: unicastAddress.toString(),
            plantTypeId: selectedPlantSpecies.value!.id,
            soilTypes: [selectedSoilType.value!.id],
            nickName: device.id.isNotEmpty ? device.id : "Unknown Device", // dummy if empty
            plantLocation: selectedPlantLocation.value!.location.isNotEmpty
                ? selectedPlantLocation.value!.location
                : "Default Location", // dummy if empty
            deviceNetworkTypeId: 1,
            isWifiConnected: false,
            networkDetailsJson: "{}",
            firmwareVersion: "1.0.0",
            timezone: "UTC",
            otherPlantType: selectedPlantSpecies.value!.plantName.isNotEmpty
                ? selectedPlantSpecies.value!.plantName
                : "Other Plant",
          ),
        );

        Get.to(ProvisionedDevicesPage());
      } catch (e) {
        AppSnackBar.show("error", "Failed to Register Pot: $e");
      }
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
