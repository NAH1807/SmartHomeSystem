import '../models/motion.dart';
import '../services/api.dart';

class MotionRepository {
  final ApiService apiService;

  MotionRepository({required this.apiService});

  // ============================================================
  // MOTION - GET CONFIG
  // ============================================================

  /// Lấy cấu hình Motion Sensor theo ID thiết bị.
  ///
  /// Trả về null nếu thiết bị chưa có cấu hình.
  Future<Motion?> getMotionConfig(int deviceId) async {
    return apiService.getMotionConfig(deviceId);
  }

  // ============================================================
  // MOTION - SAVE CONFIG
  // ============================================================
  /// Lưu cấu hình Motion Sensor.
  Future<Map<String, dynamic>> saveMotion({
    required int deviceId,
    required bool enabled,
    required int holdTime,
    required int cooldownTime,
  }) async {
    return apiService.saveMotion(
      deviceId: deviceId,
      enabled: enabled,
      holdTime: holdTime,
      cooldownTime: cooldownTime,
    );
  }

  // ============================================================
  // MQTT - MOTION
  // ============================================================
  Future<Map<String, dynamic>> motionFan({
    required int deviceId,
    required String deviceName,
    required bool enabled,
    required int holdTime,
    required int cooldownTime,
  }) async {
    return apiService.motionFan(
      deviceId: deviceId,
      deviceName: deviceName,
      settings: {
        'motion': {
          'enabled': enabled,
          'hold_seconds': holdTime,
          'cooldown_seconds': cooldownTime,
        },
      },
    );
  }

  Future<Map<String, dynamic>> motionRelay({
    required int deviceId,
    required String deviceName,
    required Map<int, String> sensorId,
    required String motionMode,
    required int holdTime,
    required int cooldownTime,
  }) async {
    return apiService.motionRelay(
      deviceId: deviceId,
      deviceName: deviceName,
      settings: {
        'channels': sensorId.entries.map((entry) {
          return {
            'id': entry.key,
            'automation_mode': motionMode,
            'motion': {
              'sensor_id': entry.value,
              'hold_seconds': holdTime,
              'cooldown_seconds': cooldownTime,
            },
          };
        }).toList(),
      },
    );
  }
}
