class Automation {
  final int? id;
  final int? deviceId;
  final bool enabled;

  // Lịch tự động
  final String? timeOn;
  final String? timeOff;
  final List<int> daysOnWeek;

  // Cấu hình nhiệt độ
  final bool temperatureEnabled;
  final double? temperatureOn;
  final double? temperatureOff;

  // Cấu hình Fan
  final int? defaultLevel;
  final bool autoEnabled;
  final String autoMode;
  final int? fanLevel;

  // Cấu hình Relay
  final List<RelayAutomationChannel> relayChannels;

  // Đồng bộ profile MQTT
  final int? profileVersion;
  final String? syncStatus;

  const Automation({
    this.id,
    required this.deviceId,
    required this.enabled,
    this.timeOn,
    this.timeOff,
    required this.daysOnWeek,
    required this.temperatureEnabled,
    this.temperatureOn,
    this.temperatureOff,
    this.defaultLevel,
    this.autoEnabled = false,
    this.autoMode = 'both',
    this.fanLevel,
    this.relayChannels = const [],
    this.profileVersion,
    this.syncStatus,
  });

  factory Automation.fromJson(Map<String, dynamic> json) {
    final rawChannels = json['relay_channels'] ?? json['channels'];

    return Automation(
      id: _toInt(json['id']),
      deviceId: _toInt(json['device_id']),
      enabled: _toBool(json['enabled']),
      timeOn: (json['time_on'])?.toString(),
      timeOff: (json['time_off'])?.toString(),
      daysOnWeek: _parseDays(json['day_on_week']),

      temperatureEnabled: _toBool(json['temperature_enabled']),
      temperatureOn: _toDouble(json['temperature_on']),
      temperatureOff: _toDouble(json['temperature_off']),
      defaultLevel: _toInt(json['default_level']),
      autoEnabled: _toBool(json['auto_enabled']),
      autoMode: (json['auto_mode'] ?? 'both').toString(),
      fanLevel: _toInt(json['fan_level']),
      relayChannels: _parseChannels(rawChannels),
      profileVersion: _toInt(json['profile_version']),
      syncStatus: (json['sync_status'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'enabled': enabled,
      'time_on': timeOn,
      'time_off': timeOff,
      'day_on_week': daysOnWeek,
      'temperature_enabled': temperatureEnabled,
      'temperature_on': temperatureOn,
      'temperature_off': temperatureOff,
      'default_level': defaultLevel,
      'auto_enabled': autoEnabled,
      'auto_mode': autoMode,
      'fan_level': fanLevel,
      'relay_channels': relayChannels
          .map((channel) => channel.toJson())
          .toList(),
      'profile_version': profileVersion,
    };
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }

    return false;
  }

  static List<int> _parseDays(dynamic value) {
    List<int> days;

    if (value is List) {
      days = value
          .map((item) => int.tryParse(item.toString()))
          .whereType<int>()
          .toList();
    } else if (value is String) {
      days = value
          .split(',')
          .map((item) => int.tryParse(item.trim()))
          .whereType<int>()
          .toList();
    } else {
      return [];
    }

    return days.where((day) => day >= 1 && day <= 7).toSet().toList()..sort();
  }

  static List<RelayAutomationChannel> _parseChannels(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map(
          (item) =>
              RelayAutomationChannel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList()
      ..sort((a, b) => a.channel.compareTo(b.channel));
  }
}

class RelayAutomationChannel {
  final int channel;
  final String name;
  final bool enabled;
  final String? timeOn;
  final String? timeOff;
  final List<int> daysOnWeek;

  const RelayAutomationChannel({
    required this.channel,
    required this.name,
    this.enabled = true,
    this.timeOn,
    this.timeOff,
    this.daysOnWeek = const [],
  });

  factory RelayAutomationChannel.fromJson(Map<String, dynamic> json) {
    return RelayAutomationChannel(
      channel:
          int.tryParse((json['channel'] ?? json['id'] ?? 1).toString()) ?? 1,
      name: (json['name'] ?? 'Light ${json['channel'] ?? json['id'] ?? 1}')
          .toString(),
      enabled: Automation._toBool(json['enabled'] ?? true),
      timeOn: (json['time_on'])?.toString(),
      timeOff: (json['time_off'])?.toString(),
      daysOnWeek: Automation._parseDays(json['day_on_week']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel': channel,
      'name': name,
      'enabled': enabled,
      'time_on': timeOn,
      'time_off': timeOff,
      'day_on_week': daysOnWeek,
    };
  }

  RelayAutomationChannel copyWith({
    int? channel,
    String? name,
    bool? enabled,
    String? timeOn,
    String? timeOff,
    List<int>? daysOnWeek,
  }) {
    return RelayAutomationChannel(
      channel: channel ?? this.channel,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      timeOn: timeOn ?? this.timeOn,
      timeOff: timeOff ?? this.timeOff,
      daysOnWeek: daysOnWeek ?? this.daysOnWeek,
    );
  }
}
