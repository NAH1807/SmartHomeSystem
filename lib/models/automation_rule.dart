class AutomationRule {
  final String id;
  String name;

  String deviceName;
  String deviceType;

  int hour;
  int minute;

  List<int> weekdays;

  String action;

  bool enabled;

  // Chế độ tự động theo nhiệt độ
  bool temperatureMode;

  double targetTemperature;

  double minTemperature;
  double maxTemperature;

  AutomationRule({
    required this.id,
    required this.name,
    required this.deviceName,
    required this.deviceType,
    required this.hour,
    required this.minute,
    required this.weekdays,
    required this.action,
    this.enabled = true,
    this.temperatureMode = false,
    this.targetTemperature = 24,
    this.minTemperature = 24,
    this.maxTemperature = 28,
  });

  String get timeString {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');

    return '$h:$m';
  }

  String get scheduleString {
    if (weekdays.length == 7) {
      return 'Every day at $timeString';
    }

    if (weekdays.isEmpty) {
      return 'No schedule';
    }

    if (weekdays.length == 5 &&
        weekdays.every(
          (day) => day >= 1 && day <= 5,
        )) {
      return 'Monday - Friday at $timeString';
    }

    if (weekdays.length == 2 &&
        weekdays.contains(6) &&
        weekdays.contains(7)) {
      return 'Weekend at $timeString';
    }

    const names = [
      '',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    final days = weekdays
        .map((day) => names[day])
        .join(', ');

    return '$days at $timeString';
  }
}