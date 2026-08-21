import 'package:flutter/material.dart';

import '../models/automation_rule.dart';
import '../widgets/automation_card.dart';

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() =>
      _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  // ============================================================
  // AUTOMATION DATA
  // ============================================================

  final List<AutomationRule> automations = [
    AutomationRule(
      id: '1',
      name: 'Turn on living room AC',
      deviceName: 'Living Room AC',
      deviceType: 'air_conditioner',
      hour: 18,
      minute: 0,
      weekdays: [1, 2, 3, 4, 5, 6, 7],
      action: 'turn_on',
      temperatureMode: true,
      minTemperature: 24,
      maxTemperature: 28,
    ),

    AutomationRule(
      id: '2',
      name: 'Turn off bedroom AC',
      deviceName: 'Bedroom AC',
      deviceType: 'air_conditioner',
      hour: 6,
      minute: 30,
      weekdays: [1, 2, 3, 4, 5],
      action: 'turn_off',
    ),

    AutomationRule(
      id: '3',
      name: 'Turn on living room light',
      deviceName: 'Living Room Light',
      deviceType: 'light',
      hour: 18,
      minute: 30,
      weekdays: [1, 2, 3, 4, 5, 6, 7],
      action: 'turn_on',
    ),
  ];

  // ============================================================
  // ADD AUTOMATION
  // ============================================================

  Future<void> _addAutomation() async {
    final result = await Navigator.push<AutomationRule>(
      context,
      MaterialPageRoute(
        builder: (_) => const AutomationEditor(),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      automations.add(result);
    });
  }

  // ============================================================
  // EDIT AUTOMATION
  // ============================================================

  Future<void> _editAutomation(
    AutomationRule automation,
  ) async {
    final result = await Navigator.push<AutomationRule>(
      context,
      MaterialPageRoute(
        builder: (_) => AutomationEditor(
          automation: automation,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      final index = automations.indexWhere(
        (item) => item.id == result.id,
      );

      if (index != -1) {
        automations[index] = result;
      }
    });
  }

  // ============================================================
  // DELETE AUTOMATION
  // ============================================================

  void _deleteAutomation(
    AutomationRule automation,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete automation?',
          ),

          content: Text(
            'Are you sure you want to delete '
            '"${automation.name}"?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              onPressed: () {
                setState(() {
                  automations.remove(automation);
                });

                Navigator.pop(context);
              },

              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),

              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Automation',
        ),

        actions: [
          IconButton(
            onPressed: _addAutomation,
            icon: const Icon(
              Icons.add,
            ),
          ),
        ],
      ),

      body: automations.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeader(),

                const SizedBox(height: 20),

                ...automations.map(
                  (automation) {
                    return AutomationCard(
                      automation: automation,

                      onChanged: (value) {
                        setState(() {
                          automation.enabled = value;
                        });
                      },

                      onEdit: () {
                        _editAutomation(
                          automation,
                        );
                      },

                      onDelete: () {
                        _deleteAutomation(
                          automation,
                        );
                      },
                    );
                  },
                ),

                // Khoảng trống cho FloatingActionButton
                const SizedBox(height: 80),
              ],
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAutomation,

        icon: const Icon(
          Icons.add,
        ),

        label: const Text(
          'Add Rule',
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final enabledCount = automations
        .where(
          (item) => item.enabled,
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.blue.shade50,

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.auto_awesome,
              color: Colors.blue,
              size: 28,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Smart Automation',

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '$enabledCount active automation rules',

                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons.auto_awesome,
              size: 70,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 20),

            const Text(
              'No automation rules',

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Create your first automation '
              'to control your Smart Home.',

              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 25),

            FilledButton.icon(
              onPressed: _addAutomation,

              icon: const Icon(
                Icons.add,
              ),

              label: const Text(
                'Create Automation',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// AUTOMATION EDITOR
// ==================================================================

class AutomationEditor extends StatefulWidget {
  final AutomationRule? automation;

  const AutomationEditor({
    super.key,
    this.automation,
  });

  @override
  State<AutomationEditor> createState() =>
      _AutomationEditorState();
}

class _AutomationEditorState
    extends State<AutomationEditor> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  late TextEditingController nameController;

  // ============================================================
  // TIME
  // ============================================================

  late int selectedHour;
  late int selectedMinute;

  // ============================================================
  // DEVICE
  // ============================================================

  late String selectedDevice;
  late String selectedDeviceType;

  // ============================================================
  // ACTION
  // ============================================================

  late String selectedAction;

  // ============================================================
  // TEMPERATURE
  // ============================================================

  late bool temperatureMode;

  late double minTemperature;
  late double maxTemperature;

  // ============================================================
  // DAYS
  // ============================================================

  final List<int> selectedDays = [];

  // ============================================================
  // AVAILABLE DEVICES
  // ============================================================

  final List<Map<String, String>> devices = [
    {
      'name': 'Living Room AC',
      'type': 'air_conditioner',
    },

    {
      'name': 'Bedroom AC',
      'type': 'air_conditioner',
    },

    {
      'name': 'Living Room Light',
      'type': 'light',
    },

    {
      'name': 'Bedroom Light',
      'type': 'light',
    },

    {
      'name': 'Bedroom Fan',
      'type': 'fan',
    },

    {
      'name': 'Living Room Fan',
      'type': 'fan',
    },

    {
      'name': 'Smart TV',
      'type': 'tv',
    },

    {
      'name': 'Smart Plug',
      'type': 'plug',
    },
  ];

  // ============================================================
  // CHECK AIR CONDITIONER
  // ============================================================

  bool get isAirConditioner =>
      selectedDeviceType ==
      'air_conditioner';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final automation = widget.automation;

    // NAME
    nameController =
        TextEditingController(
      text: automation?.name ?? '',
    );

    // TIME
    selectedHour =
        automation?.hour ?? 18;

    selectedMinute =
        automation?.minute ?? 0;

    // DEVICE
    selectedDevice =
        automation?.deviceName ??
        devices.first['name']!;

    selectedDeviceType =
        automation?.deviceType ??
        devices.first['type']!;

    // ACTION
    selectedAction =
        automation?.action ??
        'turn_on';

    // TEMPERATURE
    temperatureMode =
        automation?.temperatureMode ??
        false;

    minTemperature =
        automation?.minTemperature ??
        24;

    maxTemperature =
        automation?.maxTemperature ??
        28;

    // DAYS
    if (automation != null) {
      selectedDays.addAll(
        automation.weekdays,
      );
    } else {
      // Mặc định tất cả các ngày
      selectedDays.addAll([
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      ]);
    }

    // Nếu thiết bị hiện tại không phải AC
    // thì chắc chắn tắt temperature mode.
    if (!isAirConditioner) {
      temperatureMode = false;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();

    super.dispose();
  }

  // ============================================================
  // TIME PICKER
  // ============================================================

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,

      initialTime: TimeOfDay(
        hour: selectedHour,
        minute: selectedMinute,
      ),
    );

    if (time == null) {
      return;
    }

    setState(() {
      selectedHour = time.hour;
      selectedMinute = time.minute;
    });
  }

  // ============================================================
  // SAVE
  // ============================================================

  void _save() {
    // ------------------------------------------
    // CHECK NAME
    // ------------------------------------------

    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter automation name',
          ),
        ),
      );

      return;
    }

    // ------------------------------------------
    // CHECK DAYS
    // ------------------------------------------

    if (selectedDays.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one day',
          ),
        ),
      );

      return;
    }

    // ------------------------------------------
    // IMPORTANT
    // ------------------------------------------
    // Chỉ AC mới được phép có temperatureMode.
    // ------------------------------------------

    final bool finalTemperatureMode =
        isAirConditioner &&
        temperatureMode;

    // ------------------------------------------
    // CREATE AUTOMATION
    // ------------------------------------------

    final result = AutomationRule(
      id: widget.automation?.id ??
          DateTime.now()
              .millisecondsSinceEpoch
              .toString(),

      name: nameController.text.trim(),

      deviceName: selectedDevice,

      deviceType: selectedDeviceType,

      hour: selectedHour,

      minute: selectedMinute,

      weekdays:
          List<int>.from(selectedDays),

      action: selectedAction,

      enabled:
          widget.automation?.enabled ??
          true,

      temperatureMode:
          finalTemperatureMode,

      minTemperature:
          minTemperature,

      maxTemperature:
          maxTemperature,
    );

    Navigator.pop(
      context,
      result,
    );
  }

  // ============================================================
  // BUILD EDITOR
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.automation == null
              ? 'Add Automation'
              : 'Edit Automation',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [
          // ======================================================
          // AUTOMATION NAME
          // ======================================================

          const Text(
            'Automation Name',

            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: nameController,

            decoration: InputDecoration(
              hintText:
                  'Example: Turn on AC',

              prefixIcon: const Icon(
                Icons.edit_outlined,
              ),

              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // ======================================================
          // DEVICE
          // ======================================================

          const Text(
            'Device',

            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: selectedDevice,

            decoration: InputDecoration(
              prefixIcon: Icon(
                _getDeviceIcon(
                  selectedDeviceType,
                ),
              ),

              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
              ),
            ),

            items: devices.map(
              (device) {
                return DropdownMenuItem<String>(
                  value: device['name'],

                  child: Text(
                    device['name']!,
                  ),
                );
              },
            ).toList(),

            onChanged: (value) {
              if (value == null) {
                return;
              }

              final device =
                  devices.firstWhere(
                (item) =>
                    item['name'] == value,
              );

              setState(() {
                selectedDevice =
                    device['name']!;

                selectedDeviceType =
                    device['type']!;

                // ==================================================
                // Nếu không phải AC
                // thì tắt Temperature Automation
                // ==================================================

                if (!isAirConditioner) {
                  temperatureMode = false;
                }
              });
            },
          ),

          const SizedBox(height: 25),

          // ======================================================
          // SCHEDULE TIME
          // ======================================================

          const Text(
            'Schedule Time',

            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 8),

          InkWell(
            onTap: _selectTime,

            borderRadius:
                BorderRadius.circular(15),

            child: Container(
              padding:
                  const EdgeInsets.all(18),

              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      Colors.grey.shade400,
                ),

                borderRadius:
                    BorderRadius.circular(15),
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.blue,
                  ),

                  const SizedBox(width: 15),

                  Text(
                    '${selectedHour.toString().padLeft(2, '0')}:'
                    '${selectedMinute.toString().padLeft(2, '0')}',

                    style:
                        const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  const Text(
                    'Change',

                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          // ======================================================
          // REPEAT
          // ======================================================

          const Text(
            'Repeat',

            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 12),

          _buildDaySelector(),

          const SizedBox(height: 25),

          // ======================================================
          // ACTION
          // ======================================================

          // Nếu temperatureMode = true
          // thì Action sẽ được điều khiển bởi nhiệt độ.
          //
          // Nếu temperatureMode = false
          // thì hiển thị Action bình thường.

          if (!temperatureMode)
            _buildActionSection(),

          // ======================================================
          // AIR CONDITIONER TEMPERATURE
          // ======================================================

          // QUAN TRỌNG:
          // Phần này CHỈ xuất hiện khi thiết bị là AC.

          if (isAirConditioner)
            _buildAirConditionerSection(),

          const SizedBox(height: 30),

          // ======================================================
          // SAVE BUTTON
          // ======================================================

          SizedBox(
            height: 52,

            child: FilledButton.icon(
              onPressed: _save,

              icon: const Icon(
                Icons.save_outlined,
              ),

              label: const Text(
                'Save Automation',
              ),

              style:
                  FilledButton.styleFrom(
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION SECTION
  // ============================================================

  Widget _buildActionSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        const Text(
          'Action',

          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          value: selectedAction,

          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.power_settings_new,
            ),

            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(15),
            ),
          ),

          items: const [
            DropdownMenuItem(
              value: 'turn_on',

              child: Text(
                'Turn On',
              ),
            ),

            DropdownMenuItem(
              value: 'turn_off',

              child: Text(
                'Turn Off',
              ),
            ),
          ],

          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              selectedAction = value;
            });
          },
        ),

        const SizedBox(height: 25),
      ],
    );
  }

  // ============================================================
  // DAY SELECTOR
  // ============================================================

  Widget _buildDaySelector() {
    const days = [
      'M',
      'T',
      'W',
      'T',
      'F',
      'S',
      'S',
    ];

    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children: List.generate(
        7,
        (index) {
          final int day = index + 1;

          final bool selected =
              selectedDays.contains(day);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (selected) {
                  selectedDays.remove(day);
                } else {
                  selectedDays.add(day);
                }
              });
            },

            child: AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 200,
              ),

              width: 40,
              height: 40,

              decoration:
                  BoxDecoration(
                color: selected
                    ? Colors.blue
                    : Colors.grey.shade200,

                shape: BoxShape.circle,
              ),

              child: Center(
                child: Text(
                  days[index],

                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.black,

                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // AIR CONDITIONER AUTOMATION
  // ============================================================

  Widget _buildAirConditionerSection() {
    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.blue.shade50,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: Colors.blue.shade100,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ======================================================
          // HEADER
          // ======================================================

          Row(
            children: [
              Container(
                width: 42,
                height: 42,

                decoration:
                    BoxDecoration(
                  color:
                      Colors.blue.shade100,

                  shape:
                      BoxShape.circle,
                ),

                child: const Icon(
                  Icons.ac_unit,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Temperature Automation',

                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      'Automatically control AC '
                      'according to room temperature',

                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              Switch(
                value: temperatureMode,

                onChanged: (value) {
                  setState(() {
                    temperatureMode =
                        value;
                  });
                },
              ),
            ],
          ),

          // ======================================================
          // TEMPERATURE SETTINGS
          // ======================================================

          if (temperatureMode) ...[
            const SizedBox(height: 20),

            // MIN TEMPERATURE

            Text(
              'Minimum temperature: '
              '${minTemperature.toStringAsFixed(0)}°C',

              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            Slider(
              min: 16,
              max: 30,
              divisions: 14,

              value: minTemperature,

              label:
                  '${minTemperature.toStringAsFixed(0)}°C',

              onChanged: (value) {
                setState(() {
                  minTemperature = value;

                  if (maxTemperature <
                      minTemperature) {
                    maxTemperature =
                        minTemperature;
                  }
                });
              },
            ),

            // MAX TEMPERATURE

            const SizedBox(height: 5),

            Text(
              'Maximum temperature: '
              '${maxTemperature.toStringAsFixed(0)}°C',

              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            Slider(
              min: 16,
              max: 35,
              divisions: 19,

              value: maxTemperature,

              label:
                  '${maxTemperature.toStringAsFixed(0)}°C',

              onChanged: (value) {
                setState(() {
                  maxTemperature = value;

                  if (minTemperature >
                      maxTemperature) {
                    minTemperature =
                        maxTemperature;
                  }
                });
              },
            ),

            const SizedBox(height: 10),

            // ==================================================
            // DESCRIPTION
            // ==================================================

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(14),

              decoration:
                  BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(12),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.blue,
                      ),

                      SizedBox(width: 8),

                      Text(
                        'Automation Rule',

                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '• Room > '
                    '${maxTemperature.toStringAsFixed(0)}°C '
                    '→ Turn ON AC\n'
                    '• Room < '
                    '${minTemperature.toStringAsFixed(0)}°C '
                    '→ Turn OFF AC\n'
                    '• ${minTemperature.toStringAsFixed(0)}°C - '
                    '${maxTemperature.toStringAsFixed(0)}°C '
                    '→ Keep current state',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DEVICE ICON
  // ============================================================

  IconData _getDeviceIcon(
    String type,
  ) {
    switch (type) {
      case 'air_conditioner':
        return Icons.ac_unit;

      case 'light':
        return Icons.lightbulb_outline;

      case 'fan':
        return Icons.air;

      case 'tv':
        return Icons.tv;

      case 'plug':
        return Icons.power;

      default:
        return Icons.devices_other;
    }
  }
}