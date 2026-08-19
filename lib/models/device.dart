import 'package:flutter/material.dart';

enum DeviceType {
  light,
  airConditioner,
  smartPlug,
  temperatureSensor,
  doorSensor,
}

class Device {
  final String id;
  final String name;
  final String room;
  final DeviceType type;
  final IconData icon;
  bool isOn;
  bool isOnline;

  Device({
    required this.id,
    required this.name,
    required this.room,
    required this.type,
    required this.icon,
    this.isOn = false,
    this.isOnline = true,
  });
}