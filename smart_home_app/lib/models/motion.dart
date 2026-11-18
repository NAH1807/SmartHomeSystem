  class Motion {
  int id;
  int deviceId;
  bool enabled;
  int holdTime;
  int cooldownTime;
  

  Motion({
    required this.id,
    required this.deviceId,
    required this.enabled,
    required this.holdTime, 
    required this.cooldownTime,
  });

  factory Motion.fromJson(Map<String, dynamic> json) {
    return Motion(
      id: json['id'],
      deviceId: json['device_id'],
      enabled: _toBool(json['enabled']),
      holdTime: json['hold_seconds'],
      cooldownTime: json['cooldown_seconds'],
    );
  }

  bool get isEnabled => enabled;
  int get holdSeconds => holdTime;
  int get cooldownSeconds => cooldownTime;

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value == 1;
    }
    if (value is String) {
      return value == 'true';
    }
    return false;
  }



  Motion copyWith({
    int? id,
    int? deviceId,
    bool? enabled,
    int? holdTime,
    int? cooldownTime,
  }) {
    return Motion(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      enabled: enabled ?? this.enabled,
      holdTime: holdTime ?? this.holdTime,
      cooldownTime: cooldownTime ?? this.cooldownTime,
    );
  }
}