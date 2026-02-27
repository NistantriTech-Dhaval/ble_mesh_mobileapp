# Provisioner / group setup and firmware behavior

This document describes how the **app** (provisioner) and **firmware** (node and gateway) work together so that nodes publish sensor data to a group and the gateway receives it and uploads to ThingBoard.

## App side

The app configures publication (node) and subscription (gateway). It does **not** set the publication address on the firmware; the app configures it via mesh config messages.

### Node (sensor device)

- **Set Model Publication** for the node’s **Sensor Server (0x1100)** to group **0xC000**, and bind the same AppKey (index 0).
- The node then publishes to that group. The **firmware** only sets and publishes sensor data every 10 s; it does **not** set the publication address — the app configures publication to 0xC000 (see `mesh_controller.dart` after provisioning).

### Gateway

- **Subscribe** the **Sensor Client (0x1102)** to group **0xC000** so it receives all sensor publishes (see `provisioned_device_controller.dart` when setting a device as gateway).
- When data is received, the **app** (or **firmware** on the gateway) sends to ThingBoard:
  - **Own data** → device API: `v1/devices/me/telemetry`
  - **Other nodes’ data** → gateway API: `v1/gateway/telemetry` with the MAC key

---

## Firmware side

### Node firmware

- Only **sets and publishes** sensor data every 10 s.
- It does **not** set the publication address; the **app** configures publication to 0xC000 via Config Model Publication Set.
- Add a **short comment** above `sensor_group_publish_task` (or equivalent) to document this, for example:

  ```c
  /* Publication address (group 0xC000) is configured by the provisioner app; we only publish sensor data here every 10 s. */
  void sensor_group_publish_task(...) { ... }
  ```

### Gateway firmware

When the gateway receives sensor data in **SENSOR_CLIENT_PUBLISH_EVT** (because it is subscribed to 0xC000):

1. **Compare** the message’s **MAC** to the gateway’s **own BLE MAC**.
2. **Own data** → send to ThingBoard using the **device** method:
   - `publish_sensor_data("v1/devices/me/telemetry", json_params)`
3. **Other node’s data** → send to ThingBoard using the **gateway** method:
   - `publish_sensor_data("v1/gateway/telemetry", json_params)` with the **MAC** as the key (so ThingBoard associates telemetry with the correct device).

So: the **app** sets publication (node) and subscription (gateway); **firmware** on the node only publishes data, and on the gateway it chooses device vs gateway ThingBoard API based on own vs other MAC.
