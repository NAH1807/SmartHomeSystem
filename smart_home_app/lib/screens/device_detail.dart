import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../providers/camera.dart';
import '../repositories/camera.dart';
import '../services/camera_recording.dart';

import 'package:video_player/video_player.dart';

import '../models/device.dart';
import '../models/motion.dart';

import '../providers/motion.dart';
import '../providers/device.dart';
import 'automation.dart';

class DeviceDetailScreen extends StatefulWidget {
  final int deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  bool _motionEnabled = true;
  final Map<int, String> _selectedSensors = {
    1: 'PIR-SR602-01',
    2: 'PIR-SR602-02',
    3: 'PIR-SR602-03',
    4: 'PIR-SR602-04',
  };

  // final Map<int, bool> _relayMotionEnabled = {
  //   1: false,
  //   2: false,
  //   3: false,
  //   4: false,
  // };

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, child) {
        final device = provider.getDeviceById(widget.deviceId);
        if (device == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Device')),
            body: const Center(child: Text('Device not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(device.name)),

          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // =================================================
              // HEADER
              // =================================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        child: Icon(device.icon, size: 42),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        device.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(device.typeName),

                      const SizedBox(height: 12),

                      Chip(
                        avatar: Icon(
                          device.isOnline ? Icons.check : Icons.close,
                          size: 18,
                        ),
                        label: Text(device.isOnline ? 'Online' : 'Offline'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              if (device.type != DeviceType.camera)
                // MOTION CARD
                _MotionCard(
                  device: device,
                  selectedSensors: _selectedSensors,
                  onMotionEnabledChanged: (value) {
                    setState(() {
                      _motionEnabled = value;
                    });
                  },
                ),

              // =================================================
              // RELAY
              // =================================================
              if (device.type == DeviceType.relay)
                _RelayCard(
                  device: device,
                  motionEnabled: _motionEnabled,
                  selectedSensors: _selectedSensors,
                  onSensorSelected: (channel, sensor) {
                    setState(() {
                      _selectedSensors[channel] = sensor;
                    });
                  },
                ),
              // =================================================
              // FAN
              // =================================================
              if (device.type == DeviceType.fan) _FanCard(device: device),

              // =================================================
              // CAMERA
              // =================================================
              if (device.type == DeviceType.camera) _CameraCard(device: device),

              // =================================================
              // AUTOMATION
              // =================================================
              const SizedBox(height: 16),
              if (device.type != DeviceType.camera)
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.auto_mode)),
                    title: const Text(
                      'Automation',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Schedule and automatic control'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AutomationScreen(deviceId: device.id),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================================
// MOTION CARD
// ==========================================================
class _MotionCard extends StatefulWidget {
  final Device device;
  final Map<int, String> selectedSensors;
  final ValueChanged<bool> onMotionEnabledChanged;

  const _MotionCard({
    required this.device,
    required this.selectedSensors,
    required this.onMotionEnabledChanged,
  });

  @override
  State<_MotionCard> createState() => _MotionCardState();
}

class _MotionCardState extends State<_MotionCard> {
  bool _automationEnabled = false;

  bool _motionEnabled = true;

  int _holdSeconds = 30;
  int _cooldownSeconds = 30;

  String _motionMode = 'manual';

  bool _isLoading = true;
  bool _isSaving = false;

  // --------------------------------------------------
  // INIT STATE
  // --------------------------------------------------
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMotionConfig();
      _loadAutomation();
    });
  }

  // CHECK AUTOMATION
  Future<void> _loadAutomation() async {
    try {
      final automation = await context.read<DeviceProvider>().getAutomation(
        widget.device.id,
      );

      if (!mounted) return;

      setState(() {
        _automationEnabled = automation?.enabled ?? false;
      });
    } catch (error) {
      debugPrint('Load automation error: $error');
    }
  }

  // --------------------------------------------------
  // LOAD MOTION CONFIG
  // --------------------------------------------------
  Future<void> _loadMotionConfig() async {
    try {
      final Motion? motion = await context
          .read<MotionProvider>()
          .loadMotionConfig(widget.device.id);

      if (!mounted) return;

      if (motion != null) {
        setState(() {
          _motionEnabled = motion.enabled;
          _holdSeconds = motion.holdTime;
          _cooldownSeconds = motion.cooldownTime;
        });

        widget.onMotionEnabledChanged(motion.enabled);
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải cấu hình Motion: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // SAVE MOTION CONFIG
  // --------------------------------------------------
  Future<void> _saveMotion() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await context.read<MotionProvider>().saveMotion(
        deviceId: widget.device.id,
        enabled: _motionEnabled,
        holdTime: _holdSeconds,
        cooldownTime: _cooldownSeconds,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật Motion thất bại: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // MQTT - MOTION
  // --------------------------------------------------
  Future<void> _motionFan() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await context.read<MotionProvider>().motionFan(
        deviceId: widget.device.id,
        deviceName: widget.device.name,
        enabled: _motionEnabled,
        holdTime: _holdSeconds,
        cooldownTime: _cooldownSeconds,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật Motion thất bại: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _motionRelay() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    if (_motionEnabled && _automationEnabled) {
      _motionMode = 'schedule_motion';
    } else if (_motionEnabled) {
      _motionMode = 'motion';
    } else if (_automationEnabled) {
      _motionMode = 'schedule';
    } else {
      _motionMode = 'manual';
    }

    try {
      await context.read<MotionProvider>().motionRelay(
        deviceId: widget.device.id,
        deviceName: widget.device.name,
        sensorId: widget.selectedSensors,
        motionMode: _motionMode,
        holdTime: _holdSeconds,
        cooldownTime: _cooldownSeconds,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật Motion thất bại: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bool isOnline = widget.device.isOnline;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =========================
                  // HEADER
                  // =========================
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.sensors,
                          color: Colors.orange,
                          size: 26,
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Text(
                          'Motion Sensor',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // ON / OFF
                      Switch(
                        value: _motionEnabled,
                        onChanged: isOnline && !_isSaving
                            ? (value) async {
                                setState(() {
                                  _motionEnabled = value;
                                });

                                widget.onMotionEnabledChanged(value);

                                if (widget.device.type == DeviceType.fan) {
                                  await _motionFan();
                                } else if (widget.device.type ==
                                    DeviceType.relay) {
                                  await _motionRelay();
                                }

                                await _saveMotion();
                              }
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // STATUS
                  // =========================
                  Row(
                    children: [
                      Icon(
                        _motionEnabled ? Icons.sensors : Icons.sensors_off,
                        size: 20,
                        color: _motionEnabled ? Colors.green : Colors.grey,
                      ),

                      const SizedBox(width: 8),

                      Text(
                        _motionEnabled
                            ? 'Motion detection is enabled'
                            : 'Motion detection is disabled',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _motionEnabled ? Colors.green : Colors.grey,
                        ),
                      ),

                      const Spacer(),

                      if (!isOnline)
                        const Text(
                          'Offline',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),

                  // =========================
                  // MOTION CONFIGURATION
                  // =========================
                  if (_motionEnabled) ...[
                    const SizedBox(height: 20),

                    // --------------------------------------------------
                    // HOLD TIME
                    // --------------------------------------------------
                    const Text(
                      'Hold Time',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<int>(
                      initialValue: _holdSeconds,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                      items: [5, 10, 15, 20, 30, 45, 60, 90, 120].map((
                        seconds,
                      ) {
                        return DropdownMenuItem<int>(
                          value: seconds,
                          child: Text('$seconds giây'),
                        );
                      }).toList(),
                      onChanged: isOnline && !_isSaving
                          ? (value) async {
                              if (value == null) return;

                              setState(() {
                                _holdSeconds = value;
                              });

                              if (widget.device.type == DeviceType.fan) {
                                await _motionFan();
                              } else if (widget.device.type ==
                                  DeviceType.relay) {
                                await _motionRelay();
                              }
                              await _saveMotion();
                            }
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // --------------------------------------------------
                    // COOLDOWN TIME
                    // --------------------------------------------------
                    const Text(
                      'Cooldown Time',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<int>(
                      initialValue: _cooldownSeconds,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.hourglass_bottom),
                      ),
                      items: [3, 5, 10, 15, 20, 30, 45, 60, 90, 120].map((
                        seconds,
                      ) {
                        return DropdownMenuItem<int>(
                          value: seconds,
                          child: Text('$seconds giây'),
                        );
                      }).toList(),
                      onChanged: isOnline && !_isSaving
                          ? (value) async {
                              if (value == null) return;

                              setState(() {
                                _cooldownSeconds = value;
                              });

                              if (widget.device.type == DeviceType.fan) {
                                await _motionFan();
                              } else if (widget.device.type ==
                                  DeviceType.relay) {
                                await _motionRelay();
                              }
                              await _saveMotion();
                            }
                          : null,
                    ),
                  ],

                  // =========================
                  // LOADING / SYNC STATUS
                  // =========================
                  if (_isSaving) ...[
                    const SizedBox(height: 16),

                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),

                        SizedBox(width: 10),

                        Text(
                          'Updating configuration...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ===========================================================
// RELAY CARD
// ===========================================================

class _RelayCard extends StatefulWidget {
  final Device device;
  final bool motionEnabled;
  final Map<int, String> selectedSensors;
  final void Function(int channel, String sensor) onSensorSelected;

  const _RelayCard({
    required this.device,
    required this.motionEnabled,
    required this.selectedSensors,
    required this.onSensorSelected,
  });

  @override
  State<_RelayCard> createState() => _RelayCardState();
}

class _RelayCardState extends State<_RelayCard> {
  final List<String> _motionSensors = [
    'PIR-SR602-01',
    'PIR-SR602-02',
    'PIR-SR602-03',
    'PIR-SR602-04',
  ];

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final provider = context.read<DeviceProvider>();

    final bool allOn = device.areAllRelaysOn;
    final bool anyOn = device.hasAnyRelayOn;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TITLE
            const Text(
              'Relay Control',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            Text(
              'Control 4 lights',
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 16),

            // =================================================
            // ALL ON / OFF
            // =================================================
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Icon(allOn ? Icons.lightbulb : Icons.lightbulb_outline),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All lights',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        Text(
                          allOn
                              ? 'All 4 lights are ON'
                              : anyOn
                              ? 'Some lights are ON'
                              : 'All lights are OFF',
                        ),
                      ],
                    ),
                  ),

                  // Công tắc nằm cùng vị trí với công tắc các kênh
                  SizedBox(
                    width: 104,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Switch(
                        value: allOn,
                        onChanged: device.isOnline
                            ? (value) async {
                                try {
                                  await provider.relayAll(
                                    deviceId: device.id,
                                    state: value,
                                  );
                                } catch (_) {
                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        provider.error ??
                                            'Failed to control all lights',
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // =================================================
            // RELAY CHANNEL 1
            // =================================================
            _RelayChannelTile(
              device: device,
              channel: 1,
              name: 'Light 1',
              provider: provider,
              motionEnabled: widget.motionEnabled,
              motionSensors: _motionSensors,
              selectedSensor: widget.selectedSensors[1] ?? _motionSensors[0],
              onSensorSelected: (sensor) {
                widget.onSensorSelected(1, sensor);
              },
            ),

            const SizedBox(height: 8),

            // =================================================
            // RELAY CHANNEL 2
            // =================================================
            _RelayChannelTile(
              device: device,
              channel: 2,
              name: 'Light 2',
              provider: provider,
              motionEnabled: widget.motionEnabled,
              motionSensors: _motionSensors,
              selectedSensor: widget.selectedSensors[2] ?? _motionSensors[1],
              onSensorSelected: (sensor) {
                widget.onSensorSelected(2, sensor);
              },
            ),

            const SizedBox(height: 8),

            // =================================================
            // RELAY CHANNEL 3
            // =================================================
            _RelayChannelTile(
              device: device,
              channel: 3,
              name: 'Light 3',
              provider: provider,
              motionEnabled: widget.motionEnabled,
              motionSensors: _motionSensors,
              selectedSensor: widget.selectedSensors[3] ?? _motionSensors[2],
              onSensorSelected: (sensor) {
                widget.onSensorSelected(3, sensor);
              },
            ),

            const SizedBox(height: 8),

            // =================================================
            // RELAY CHANNEL 4
            // =================================================
            _RelayChannelTile(
              device: device,
              channel: 4,
              name: 'Light 4',
              provider: provider,
              motionEnabled: widget.motionEnabled,
              motionSensors: _motionSensors,
              selectedSensor: widget.selectedSensors[3] ?? _motionSensors[2],
              onSensorSelected: (sensor) {
                widget.onSensorSelected(3, sensor);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// RELAY CHANNEL TILE
// ===========================================================

class _RelayChannelTile extends StatelessWidget {
  final Device device;
  final int channel;
  final String name;
  final DeviceProvider provider;

  final bool motionEnabled;
  final String? selectedSensor;
  final List<String> motionSensors;
  final ValueChanged<String> onSensorSelected;

  const _RelayChannelTile({
    required this.device,
    required this.channel,
    required this.name,
    required this.provider,
    required this.motionEnabled,
    required this.selectedSensor,
    required this.motionSensors,
    required this.onSensorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOn = device.isRelayChannelOn(channel);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

        // ICON
        leading: Icon(
          isOn ? Icons.lightbulb : Icons.lightbulb_outline,
          color: isOn ? Colors.orange : null,
        ),

        // NAME + STATUS
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isOn ? 'ON' : 'OFF'),

            if (motionEnabled)
              Text(
                selectedSensor!,
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
          ],
        ),

        // =================================================
        // THREE DOTS + RELAY SWITCH
        // =================================================
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // THREE DOTS
            if (motionEnabled)
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48),
                tooltip: 'Chọn cảm biến chuyển động',
                onSelected: onSensorSelected,
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      'Chọn cảm biến chuyển động',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  ...motionSensors.map(
                    (sensor) => PopupMenuItem<String>(
                      value: sensor,
                      child: Row(
                        children: [
                          Icon(
                            selectedSensor == sensor
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 20,
                            color: selectedSensor == sensor
                                ? Colors.orange
                                : Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Text(sensor),
                        ],
                      ),
                    ),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.more_vert),
                ),
              )
            else
              const SizedBox(width: 48),

            // RELAY ON / OFF
            Switch(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: isOn,
              onChanged: device.isOnline
                  ? (value) async {
                      try {
                        await provider.relayChannel(
                          deviceId: device.id,
                          channel: channel,
                          state: value,
                        );
                      } catch (_) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.error ?? 'Failed to control $name',
                            ),
                          ),
                        );
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// // ============================================================
// // FAN CARD
// // ============================================================
class _FanCard extends StatelessWidget {
  final Device device;

  const _FanCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DeviceProvider>();

    final bool isOn = device.isOn;
    final int currentLevel = device.fanSpeed;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // HEADER
            // =========================
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.air, color: Colors.blue, size: 26),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Text(
                    'Fan Control',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),

                // ON / OFF
                Switch(
                  value: isOn,
                  onChanged: device.isOnline
                      ? (value) async {
                          if (value) {
                            // Bật quạt -> mặc định Level 1
                            await provider.fanLevel(
                              deviceId: device.id,
                              level: 1,
                            );
                          } else {
                            // Tắt quạt -> Level 0
                            await provider.fanLevel(
                              deviceId: device.id,
                              level: 0,
                            );
                          }
                        }
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // =========================
            // STATUS
            // =========================
            Row(
              children: [
                Icon(
                  isOn ? Icons.power : Icons.power_off,
                  size: 20,
                  color: isOn ? Colors.green : Colors.grey,
                ),

                const SizedBox(width: 8),

                Text(
                  isOn ? 'Fan is running' : 'Fan is off',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isOn ? Colors.green : Colors.grey,
                  ),
                ),

                const Spacer(),

                if (isOn)
                  Text(
                    'Level $currentLevel',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // =========================
            // LEVEL BUTTONS
            // =========================
            Row(
              children: [
                Expanded(
                  child: _FanLevelButton(
                    level: 1,
                    currentLevel: currentLevel,
                    enabled: device.isOnline,
                    onPressed: () {
                      provider.fanLevel(deviceId: device.id, level: 1);
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _FanLevelButton(
                    level: 2,
                    currentLevel: currentLevel,
                    enabled: device.isOnline,
                    onPressed: () {
                      provider.fanLevel(deviceId: device.id, level: 2);
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _FanLevelButton(
                    level: 3,
                    currentLevel: currentLevel,
                    enabled: device.isOnline,
                    onPressed: () {
                      provider.fanLevel(deviceId: device.id, level: 3);
                    },
                  ),
                ),
              ],
            ),

            // =========================
            // TEMPERATURE
            // =========================
            if (device.temperature != null) ...[
              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(Icons.thermostat, size: 20, color: Colors.orange),

                  const SizedBox(width: 8),

                  Text(
                    '${device.temperature!.toStringAsFixed(1)} °C',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FAN LEVEL BUTTON
// ============================================================
class _FanLevelButton extends StatelessWidget {
  final int level;
  final int currentLevel;
  final bool enabled;
  final VoidCallback onPressed;

  const _FanLevelButton({
    required this.level,
    required this.currentLevel,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = currentLevel == level;

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: selected ? Colors.blue : Colors.grey.shade100,
          foregroundColor: selected ? Colors.white : Colors.black87,
          disabledBackgroundColor: Colors.grey.shade200,
          disabledForegroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Level $level',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ============================================================
// CAMERA CARD
// ============================================================
class _CameraCard extends StatelessWidget {
  final Device device;

  const _CameraCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final bool online = device.isOnline;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: online ? Colors.green : Colors.red,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Text(
                            online ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 13,
                              color: online ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.camera_alt_outlined,
                  color: online ? Colors.blue : Colors.grey,
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: online
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CameraScreen(device: device),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'Xem camera',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraScreen extends StatelessWidget {
  final Device device;

  const CameraScreen({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = CameraProvider(
          repository: CameraRepository(CameraRecordingService()),
          cameraId: device.deviceUid.toString(),
        );

        provider.initialize();

        return provider;
      },
      child: _CameraScreenView(device: device),
    );
  }
}

class _CameraScreenView extends StatefulWidget {
  const _CameraScreenView({required this.device});

  final Device device;

  @override
  State<_CameraScreenView> createState() => _CameraScreenViewState();
}

class _CameraScreenViewState extends State<_CameraScreenView> {
  // Trạng thái hiển thị khung tìm kiếm lịch sử.
  bool _showSearch = true;
  Map<String, dynamic>? _selectedSegment;

  // ==================================================
  // DATE / TIME PICKER
  // ==================================================

  Future<DateTime?> _selectDateTime(
    BuildContext context,
    DateTime initial,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date == null || !context.mounted) {
      return null;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (time == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDateTime(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year} '
        '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
  }

  // ==================================================
  // MAIN UI
  // ==================================================

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: Text(widget.device.name), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _modeButton(
                    title: 'Xem trực tiếp',
                    icon: Icons.videocam_rounded,
                    selected: camera.selectedMode == 0,
                    onTap: () => camera.changeMode(0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _modeButton(
                    title: 'Xem lịch sử',
                    icon: Icons.history_rounded,
                    selected: camera.selectedMode == 1,
                    onTap: () => camera.changeMode(1),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: camera.selectedMode == 0
                ? _buildLiveView(camera)
                : _buildHistoryView(context, camera),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // MODE BUTTON
  // ==================================================

  Widget _modeButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.blue : Colors.white,
        foregroundColor: selected ? Colors.white : Colors.black87,
        elevation: selected ? 2 : 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? Colors.blue : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  // ==================================================
  // LIVE VIEW
  // ==================================================
  Widget _buildLiveView(CameraProvider camera) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            width: double.infinity,
            child: camera.liveLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : camera.liveError || camera.liveStreamUrl == null
                ? _liveErrorWidget(camera)
                : InAppWebView(
                    key: ValueKey(camera.liveSessionId),
                    initialUrlRequest: URLRequest(
                      url: WebUri(camera.liveStreamUrl!),
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      transparentBackground: false,
                      supportZoom: false,
                      disableHorizontalScroll: true,
                      disableVerticalScroll: true,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, color: Colors.red, size: 12),
            SizedBox(width: 8),
            Text(
              'Đang xem trực tiếp',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  /// Giao diện khi không kết nối được camera.
  Widget _liveErrorWidget(CameraProvider camera) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off, color: Colors.white, size: 56),
          const SizedBox(height: 12),
          const Text(
            'Không thể kết nối camera',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: camera.createLiveSession,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // HISTORY VIEW
  // ==================================================

  Widget _buildHistoryView(BuildContext context, CameraProvider camera) {
    final isVideoPlaying =
        camera.videoController != null &&
        camera.videoController!.value.isInitialized;

    return Column(
      children: [
        // ==================================================
        // SEARCH HEADER
        // ==================================================

        if (_showSearch)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khoảng thời gian xem lại',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                _dateTimeRow(
                  title: 'Bắt đầu',
                  value: camera.startDateTime,
                  onTap: () async {
                    final result = await _selectDateTime(
                      context,
                      camera.startDateTime,
                    );

                    if (result != null) {
                      camera.setStartDateTime(result);
                    }
                  },
                ),

                const SizedBox(height: 12),

                _dateTimeRow(
                  title: 'Kết thúc',
                  value: camera.endDateTime,
                  onTap: () async {
                    final result = await _selectDateTime(
                      context,
                      camera.endDateTime,
                    );

                    if (result != null) {
                      camera.setEndDateTime(result);
                    }
                  },
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: camera.historyLoading
                        ? null
                        : camera.loadHistory,
                    icon: const Icon(Icons.search),
                    label: const Text('Tìm video'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // ==================================================
        // VIDEO PLAYER
        // ==================================================
        if (isVideoPlaying) _buildVideoPlayer(camera),

        if (camera.videoLoading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),

        if (camera.videoError != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              camera.videoError!,
              style: const TextStyle(color: Colors.red),
            ),
          ),

        // ==================================================
        // HISTORY LIST
        // ==================================================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.video_library_outlined, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Danh sách video',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${camera.segments.length} video',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),

        Expanded(
          child: camera.historyLoading
              ? const Center(child: CircularProgressIndicator())
              : camera.historyError != null && camera.segments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      camera.historyError!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : camera.segments.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có video. Hãy chọn khoảng thời gian để tìm kiếm.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: camera.segments.length,
                  itemBuilder: (context, index) {
                    final segment = camera.segments[index];

                    final start = DateTime.tryParse(
                      segment['start_time_local']?.toString() ??
                          segment['start_time']?.toString() ??
                          '',
                    );

                    final end = DateTime.tryParse(
                      segment['end_time_local']?.toString() ??
                          segment['end_time']?.toString() ??
                          '',
                    );

                    final fileSize = segment['file_size'] is num
                        ? (segment['file_size'] as num).toDouble()
                        : double.tryParse(
                                segment['file_size']?.toString() ?? '0',
                              ) ??
                              0;

                    final isSelected = _selectedSegment == segment;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),

                      // Nền xanh nhạt khi video được chọn.
                      color: isSelected ? Colors.blue.shade50 : Colors.white,

                      // Viền xanh khi video được chọn.
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.blue
                              : Colors.grey.shade200,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),

                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? Colors.blue
                              : Colors.blue.shade100,
                          child: Icon(
                            isSelected ? Icons.check : Icons.play_arrow,
                            color: isSelected ? Colors.white : Colors.blue,
                          ),
                        ),

                        title: Text(
                          start != null && end != null
                              ? '${_formatDateTime(start.toUtc().add(const Duration(hours: 7)))} - '
                                    '${_formatDateTime(end.toUtc().add(const Duration(hours: 7)))}'
                              : 'Đoạn video ${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSelected
                                ? Colors.blue.shade800
                                : Colors.black87,
                          ),
                        ),

                        subtitle: Text(
                          'Dung lượng: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                          ),
                        ),

                        trailing: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.play_circle_outline,
                          color: Colors.blue,
                          size: 26,
                        ),

                        onTap: () {
                          setState(() {
                            _showSearch = false;
                            _selectedSegment = segment;
                          });

                          camera.playVideo(segment);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==================================================
  // DATE TIME ROW
  // ==================================================

  Widget _dateTimeRow({
    required String title,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Colors.blue),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(value),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const Icon(Icons.edit, size: 18),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // VIDEO PLAYER
  // ==================================================

  Widget _buildVideoPlayer(CameraProvider camera) {
    final controller = camera.videoController!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Khung phát video.
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),

          const SizedBox(height: 8),

          // Thanh tiến trình.
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            colors: VideoProgressColors(
              playedColor: Colors.blue,
              bufferedColor: Colors.blue.withValues(alpha: 0.25),
              backgroundColor: Colors.grey.shade300,
            ),
          ),

          // Nút điều khiển video.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: 'Lùi 10 giây',
                onPressed: () => camera.seekVideo(-10),
                icon: const Icon(Icons.replay_10),
                iconSize: 32,
              ),

              IconButton(
                onPressed: camera.toggleVideo,
                icon: Icon(
                  controller.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                ),
                iconSize: 42,
                color: Colors.blue,
              ),

              IconButton(
                tooltip: 'Tiến 10 giây',
                onPressed: () => camera.seekVideo(10),
                icon: const Icon(Icons.forward_10),
                iconSize: 32,
              ),
            ],
          ),

          // Thời gian hiện tại và tổng thời lượng.
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              String format(Duration duration) {
                final minutes = duration.inMinutes
                    .remainder(60)
                    .toString()
                    .padLeft(2, '0');

                final seconds = duration.inSeconds
                    .remainder(60)
                    .toString()
                    .padLeft(2, '0');

                final hours = duration.inHours;

                return hours > 0
                    ? '$hours:$minutes:$seconds'
                    : '$minutes:$seconds';
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(format(value.position)),
                  Text(format(value.duration)),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // Nút đóng video.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await camera.disposeVideo();

                if (!mounted) return;

                setState(() {
                  _showSearch = true;
                  _selectedSegment = null;
                });
              },
              icon: const Icon(Icons.close),
              label: const Text('Đóng video'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
