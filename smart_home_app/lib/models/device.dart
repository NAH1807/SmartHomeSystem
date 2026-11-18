import 'package:flutter/material.dart';

enum DeviceType {
  relay,
  fan,
  camera,
}

class Device {
  int id;
  String name;
  DeviceType type;
  String iconName;

  bool isOnline;
  bool isOn;

  List<bool> relayChannels;
  int fanSpeed;
  double? temperature;

  // =========================
  // CAMERA
  // =========================

  /// Trạng thái bảo mật camera
  ///
  /// normal      = Bình thường
  /// quarantine  = Đang bị cô lập
  /// release     = Đã gỡ cô lập
  String securityState;

  // =========================
  // MQTT
  // =========================

  String? mqttTopic;
  String? deviceUid;
  String? deviceIp;
  String? configTopic;
  String? controlTopic;
  String? securityTopic;

  // =========================
  // Profile / Firmware
  // =========================

  int profileVersion;
  int deviceVersion;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.iconName,
    required this.isOnline,
    required this.isOn,

    // Relay
    List<bool>? relayChannels,

    // Fan
    this.fanSpeed = 0,
    this.temperature,

    // Camera
    this.securityState = 'normal',

    // MQTT
    this.mqttTopic,
    this.deviceUid,
    this.deviceIp,
    this.configTopic,
    this.controlTopic,
    this.securityTopic,

    // Profile
    this.profileVersion = 0,
    this.deviceVersion = 0,
  }) : relayChannels = relayChannels ??
            List<bool>.filled(4, false);

  // ============================================================
  // JSON -> Device
  // ============================================================

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: int.tryParse(
            json['id']?.toString() ?? '',
          ) ??
          0,

      name: json['name']?.toString() ?? '',

      type: _parseType(
        json['device_type'] ?? json['type'],
      ),

      iconName:
          json['icon']?.toString() ??
          json['icon_name']?.toString() ??
          'devices',

      isOnline: _toBool(
        json['is_online'],
      ),

      isOn: _toBool(
        json['is_on'],
      ),

      // =========================
      // Relay
      // =========================

      relayChannels: _parseRelayChannels(
        json['relay_channels'],
      ),

      // =========================
      // Fan
      // =========================

      fanSpeed:
          _toNullableInt(
            json['fan_speed'],
          ) ??
          0,

      temperature:
          _toNullableDouble(
            json['temperature'],
          ),

      // =========================
      // Camera
      // =========================

      securityState:
          json['security_state']?.toString() ??
          'normal',

      // =========================
      // MQTT
      // =========================

      mqttTopic:
          json['mqtt_topic']?.toString(),

      deviceUid:
          json['device_uid']?.toString(),

      deviceIp:
          json['device_ip']?.toString(),

      configTopic:
          json['config_topic']?.toString(),

      controlTopic:
          json['control_topic']?.toString(),

      securityTopic:
          json['security_topic']?.toString(),

      // =========================
      // Profile
      // =========================

      profileVersion:
          _toNullableInt(
            json['profile_version'],
          ) ??
          0,

      deviceVersion:
          _toNullableInt(
            json['device_version'],
          ) ??
          0,
    );
  }

  // ============================================================
  // Device Type
  // ============================================================

  static DeviceType _parseType(dynamic value) {
    switch (value?.toString()) {
      case 'relay':
        return DeviceType.relay;

      case 'fan':
        return DeviceType.fan;

      case 'camera':
        return DeviceType.camera;

      default:
        return DeviceType.relay;
    }
  }

  // ============================================================
  // Parse Relay Channels
  // ============================================================

  static List<bool> _parseRelayChannels(
    dynamic value,
  ) {
    if (value is List) {
      final channels = value.map(
        (item) => _toBool(item),
      ).toList();

      // Đảm bảo luôn có đúng 4 channel
      while (channels.length < 4) {
        channels.add(false);
      }

      if (channels.length > 4) {
        return channels.sublist(0, 4);
      }

      return channels;
    }

    // Nếu backend chưa trả relay_channels
    return List<bool>.filled(4, false);
  }

  // ============================================================
  // Convert Bool
  // ============================================================

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      return value == '1' ||
          value.toLowerCase() == 'true';
    }

    return false;
  }

  // ============================================================
  // Convert Double
  // ============================================================

  static double? _toNullableDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // Convert Int
  // ============================================================

  static int? _toNullableInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // Type Name
  // ============================================================

  String get typeName {
    switch (type) {
      case DeviceType.relay:
        return 'Relay';

      case DeviceType.fan:
        return 'Fan';

      case DeviceType.camera:
        return 'Camera';
    }
  }

  // ============================================================
  // Icon
  // ============================================================

  IconData get icon {
    switch (type) {
      case DeviceType.relay:
        return Icons.lightbulb;

      case DeviceType.fan:
        return Icons.air;

      case DeviceType.camera:
        return Icons.camera_alt;
    }
  }

  // ============================================================
  // Relay
  // ============================================================

  /// Kiểm tra một kênh relay có đang ON không
  bool isRelayChannelOn(int channel) {
    if (channel < 1 || channel > 4) {
      return false;
    }

    return relayChannels[channel - 1];
  }

  /// Có ít nhất một bóng đèn đang bật
  bool get hasAnyRelayOn {
    return relayChannels.any(
      (channel) => channel,
    );
  }

  /// Có phải cả 4 bóng đều bật
  bool get areAllRelaysOn {
    return relayChannels.every(
      (channel) => channel,
    );
  }

  // ============================================================
  // Copy With
  // ============================================================

  Device copyWith({
    int? id,
    String? name,
    DeviceType? type,
    String? iconName,
    bool? isOnline,
    bool? isOn,

    List<bool>? relayChannels,

    int? fanSpeed,
    double? temperature,

    String? securityState,

    String? mqttTopic,
    String? deviceUid,
    String? deviceIp,
    String? configTopic,
    String? controlTopic,
    String? securityTopic,

    int? profileVersion,
    int? deviceVersion,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconName: iconName ?? this.iconName,
      isOnline: isOnline ?? this.isOnline,
      isOn: isOn ?? this.isOn,

      // Relay
      relayChannels:
          relayChannels ??
          List<bool>.from(
            this.relayChannels,
          ),

      // Fan
      fanSpeed:
          fanSpeed ??
          this.fanSpeed,

      temperature:
          temperature ??
          this.temperature,

      // Camera
      securityState:
          securityState ??
          this.securityState,

      // MQTT
      mqttTopic:
          mqttTopic ??
          this.mqttTopic,

      deviceUid:
          deviceUid ??
          this.deviceUid,

      deviceIp:
          deviceIp ??
          this.deviceIp,

      configTopic:
          configTopic ??
          this.configTopic,

      controlTopic:
          controlTopic ??
          this.controlTopic,

      securityTopic:
          securityTopic ??
          this.securityTopic,

      // Profile
      profileVersion:
          profileVersion ??
          this.profileVersion,

      deviceVersion:
          deviceVersion ??
          this.deviceVersion,
    );
  }
}