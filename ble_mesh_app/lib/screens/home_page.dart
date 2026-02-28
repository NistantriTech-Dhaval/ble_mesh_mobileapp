import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ntpl_ble_mesh_demo/controller/tb_device_list_controller.dart';
import 'package:ntpl_ble_mesh_demo/controller/thingsboard_controller.dart';
import 'package:ntpl_ble_mesh_demo/mesh/mesh_network_list_page.dart';
import 'package:ntpl_ble_mesh_demo/screens/login_page.dart';
import '../constant/appColors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  static const List<String> _titles = [
    'Home',
    'Mesh Network'
  ];

  void _onLogout() async {
    try {
      await Get.find<ThingsBoardController>().logout();
      if (mounted) Get.off(() => const LoginPage());
    } catch (_) {
      if (mounted) Get.off(() => const LoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          _titles[_currentIndex],
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
            fontSize: 20
              ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _onLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          _MeshNetworkTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.darkgreen,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.network_wifi_outlined),
            activeIcon: Icon(Icons.network_wifi),
            label: 'Mesh Network',
          )
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TbDeviceListController>()) {
      Get.put(TbDeviceListController());
    }
    final c = Get.find<TbDeviceListController>();
    return RefreshIndicator(
      onRefresh: c.refreshDevices,
      color: AppColors.darkgreen,
      child: Obx(() {
        if (c.isLoading.value && c.devices.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.errorMessage.value != null && c.devices.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    c.errorMessage.value!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: c.subscribeToDevices,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (c.devices.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.darkgreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.devices_other,
                      size: 64,
                      color: AppColors.darkgreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No devices found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.isConnected.value
                        ? 'Waiting for devices to appear...'
                        : 'Pull down to refresh and connect',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (c.isConnected.value) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                      await c.refreshDevices();
                      },
                      icon: const Icon(Icons.sync, size: 18),
                      label: const Text('Fetch Devices'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkgreen.withValues(alpha: 0.1),
                        foregroundColor: AppColors.darkgreen,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.darkgreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: c.devices.length + (c.isLoading.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == c.devices.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final device = c.devices[index];
                  return _DeviceListTile(device: device);
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DeviceListTile extends StatelessWidget {
  const _DeviceListTile({required this.device});

  final Map<String, dynamic> device;

  @override
  Widget build(BuildContext context) {
    final name = device['name'] as String? ?? 'Device';
    final id = device['id'] as String? ?? '';
    final label = device['label'] as String? ?? '';
    final bulb = device['bulb'] as String?;
    final humidity = device['humidity'] as String?;
    final temp = device['temp'] as String?;
    final unicastAddress = device['unicastAddress'] as int?;

    final tempValue = temp != null && temp.isNotEmpty ? double.tryParse(temp) : null;
    final humidityValue = humidity != null && humidity.isNotEmpty ? double.tryParse(humidity) : null;
    final hasLiveData = tempValue != null ||
        humidityValue != null ||
        (bulb != null && bulb.isNotEmpty);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasLiveData
              ? AppColors.darkgreen.withValues(alpha: 0.2)
              : Theme.of(context).dividerColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final currentValue = bulb; // your telemetry value
                      final isOn = currentValue != null &&
                          (currentValue.toLowerCase() == "on" ||
                              currentValue == "1" ||
                              currentValue.toLowerCase() == "true");

                      final newState = isOn ? "off" : "on";

                      await Get.find<TbDeviceListController>()
                          .onOffRpcCommand(id, newState, unicastAddress!);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.darkgreen.withValues(alpha: 0.15),
                            AppColors.darkgreen.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        bulb != null &&
                            (bulb.toLowerCase() == "on" ||
                                bulb == "1" ||
                                bulb.toLowerCase() == "true") ? Icons.lightbulb : Icons.lightbulb_outline,
                        color: bulb != null &&
                            (bulb.toLowerCase() == "on" ||
                                bulb == "1" ||
                                bulb.toLowerCase() == "true") ? Colors.orange : AppColors.darkgreen,
                        size: 26,
                      )
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.2,
                                    ),
                              ),
                            ),
                            if (hasLiveData)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.success.withValues(alpha: 0.4),
                                      blurRadius: 4,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (label.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                label,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                              ),
                            ],
                          ),
                        ],
                        if (unicastAddress != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.pin_drop_rounded, size: 12, color: AppColors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'Unicast $unicastAddress',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.blue,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    )
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Divider
              if (tempValue != null || humidityValue != null || bulb != null) ...[
                const SizedBox(height: 16),
                Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
              ],
              // Telemetry row
              if (tempValue != null || humidityValue != null || bulb != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tempValue != null) ...[
                      Expanded(
                        child: _TelemetryChip(
                          icon: Icons.thermostat_rounded,
                          label: 'Temp',
                          value: '${tempValue.toStringAsFixed(1)}°C',
                          color: AppColors.red,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (humidityValue != null) ...[
                      Expanded(
                        child: _TelemetryChip(
                          icon: Icons.water_drop_rounded,
                          label: 'Humidity',
                          value: '${humidityValue.toStringAsFixed(0)}%',
                          color: AppColors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],

                    Expanded(
                      flex: 1,
                      child: _BulbStatusChip(bulbValue: bulb),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TelemetryChip extends StatelessWidget {
  const _TelemetryChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
          ),
        ],
      ),
    );
  }
}

class _BulbStatusChip extends StatelessWidget {
  const _BulbStatusChip({required this.bulbValue});

  final String? bulbValue;

  static bool _isOn(String? value) {
    if (value == null || value.isEmpty) return false;
    final v = value.trim().toLowerCase();
    if (v == 'on' || v == '1' || v == 'true' || v == 'yes') return true;
    if (v == 'off' || v == '0' || v == 'false' || v == 'no') return false;
    final n = double.tryParse(value);
    return n != null && n > 0;
  }

  @override
  Widget build(BuildContext context) {
    final isOn = _isOn(bulbValue);
    final color = isOn ? AppColors.orange : AppColors.gray;
    final statusText = isOn ? 'on' : 'off';

    return GestureDetector(
      onTap: ()async{
        // await Get.find<TbDeviceListController>().onOffRpcCommand(, , )
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isOn ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  'Bulb',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOn ? color : AppColors.gray,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusText.toUpperCase(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MeshNetworkTab extends StatelessWidget {
  const _MeshNetworkTab();

  @override
  Widget build(BuildContext context) {
    return const MeshNetworkListPage(embedInShell: true);
  }
}
