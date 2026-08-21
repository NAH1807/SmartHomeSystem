import 'package:flutter/material.dart';

import '../models/automation_rule.dart';

class AutomationCard extends StatelessWidget {
  final AutomationRule automation;

  final ValueChanged<bool> onChanged;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  const AutomationCard({
    super.key,
    required this.automation,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,

      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Padding(
        padding: const EdgeInsets.all(8),

        child: Column(
          children: [

            ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Colors.blue.shade50,

                child: Icon(
                  _getDeviceIcon(),
                  color: Colors.blue,
                ),
              ),

              title: Text(
                automation.name,

                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const SizedBox(height: 5),

                  Text(
                    automation.deviceName,
                  ),

                  const SizedBox(height: 3),

                  Text(
                    automation.scheduleString,

                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              trailing: Switch(
                value: automation.enabled,
                onChanged: onChanged,
              ),
            ),

            if (automation.temperatureMode)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),

                padding:
                    const EdgeInsets.all(12),

                decoration: BoxDecoration(
                  color:
                      Colors.orange.shade50,

                  borderRadius:
                      BorderRadius.circular(12),
                ),

                child: Row(
                  children: [

                    const Icon(
                      Icons.thermostat,
                      color: Colors.orange,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Auto temperature: '
                        '${automation.minTemperature.toStringAsFixed(0)}°C - '
                        '${automation.maxTemperature.toStringAsFixed(0)}°C',

                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,

              children: [

                TextButton.icon(
                  onPressed: onEdit,

                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                  ),

                  label: const Text(
                    'Edit',
                  ),
                ),

                TextButton.icon(
                  onPressed: onDelete,

                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                  ),

                  label: const Text(
                    'Delete',
                  ),

                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDeviceIcon() {
    switch (automation.deviceType) {
      case 'air_conditioner':
        return Icons.ac_unit;

      case 'light':
        return Icons.lightbulb_outline;

      case 'fan':
        return Icons.air;

      default:
        return Icons.devices_other;
    }
  }
}