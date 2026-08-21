import 'package:flutter/material.dart';

import '../models/device.dart';
import '../widgets/device_card.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  static final devices = [
    Device(
      id: 'light_001',
      name: 'Living Room Light',
      room: 'Living Room',
      type: DeviceType.light,
      icon: Icons.lightbulb_outline,
      isOn: true,
    ),

    Device(
      id: 'ac_001',
      name: 'Bedroom AC',
      room: 'Bedroom',
      type: DeviceType.airConditioner,
      icon: Icons.ac_unit,
      isOn: false,
    ),

    Device(
      id: 'plug_001',
      name: 'Kitchen Plug',
      room: 'Kitchen',
      type: DeviceType.smartPlug,
      icon: Icons.power,
      isOn: true,
    ),

    Device(
      id: 'sensor_001',
      name: 'Temperature Sensor',
      room: 'Living Room',
      type: DeviceType.temperatureSensor,
      icon: Icons.thermostat_outlined,
    ),

  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Devices',

              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Manage all smart devices',

              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(16),

                border: Border.all(
                  color:
                      Colors.grey.shade200,
                ),
              ),

              child: const TextField(
                decoration:
                    InputDecoration(
                  icon: Icon(
                    Icons.search,
                  ),

                  hintText:
                      'Search devices...',

                  border:
                      InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount:
                    devices.length,

                itemBuilder:
                    (context, index) {
                  return DeviceCard(
                    device: devices[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}