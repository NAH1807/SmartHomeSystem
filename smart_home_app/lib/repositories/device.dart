import '../models/device.dart';
import '../models/automation.dart';
import '../services/api.dart';

class DeviceRepository {
  final ApiService apiService;

  DeviceRepository({required this.apiService});

  // ============================================================
  // DEVICE
  // ============================================================

  Future<List<Device>> getDevices() async {
    return apiService.getDevices();
  }

  Future<Device> getDevice(int deviceId) async {
    return apiService.getDevice(deviceId);
  }

  Future<Device> createDevice({
    required String name,
    required DeviceType type,
  }) async {
    return apiService.createDevice(
      name: name,
      type: type,
    );
  }

  Future<Device> updateDevice({
    required int deviceId,
    required String name,
    required DeviceType type,
  }) async {
    return apiService.updateDevice(
      deviceId: deviceId,
      name: name,
      type: type,
    );
  }

  Future<void> deleteDevice(int deviceId) async {
    await apiService.deleteDevice(deviceId);
  }

  Future<Device> setTargetTemperature(
    int deviceId,
    double value,
  ) async {
    return apiService.setDeviceTargetTemperature(
      deviceId: deviceId,
      temperature: value,
    );
  }

  Future<Device> setAcMode(
    int deviceId,
    String mode,
  ) async {
    return apiService.setDeviceAcMode(
      deviceId: deviceId,
      mode: mode,
    );
  }

  // ============================================================
  // AUTOMATION PROFILE
  // ============================================================

  /// Lấy cấu hình tự động hóa của thiết bị.
  ///
  /// Trả về null nếu thiết bị chưa có cấu hình.
  Future<Automation?> getAutomation(int deviceId) async {
    return apiService.getAutomation(deviceId);
  }

  /// Lưu cấu hình tự động hóa.
  ///
  /// Relay:
  /// - relayChannels: danh sách kênh được cấu hình.
  /// - scheduleTime: thời gian bật.
  /// - scheduleOffTime: thời gian tắt.
  ///
  /// Fan:
  /// - defaultLevel: mức quạt mặc định.
  /// - autoMode: chế độ tự động.
  /// - scenarioMode: chế độ kịch bản.
  /// - temperatureOn / temperatureOff: ngưỡng nhiệt độ.
  ///
  /// Các trường không áp dụng cho thiết bị có thể bỏ qua.
  Future<Automation> saveAutomation({
    required int deviceId,
    String? name,
    required bool enabled,
    required String timeOn,
    String? timeOff,
    required List<int> daysOnWeek,
    double? temperatureOn,
    double? temperatureOff,
    int? defaultLevel,
    bool? autoEnabled,
    String? autoMode,
    int? fanLevel,
    List<RelayAutomationChannel> relayChannels = const [],
    int? profileVersion,
  }) async {
    return apiService.saveAutomation(
      deviceId: deviceId,
      enabled: enabled,
      timeOn: timeOn,
      timeOff: timeOff,
      daysOnWeek: daysOnWeek,
      temperatureOn: temperatureOn,
      temperatureOff: temperatureOff,
      defaultLevel: defaultLevel,
      autoEnabled: autoEnabled,
      autoMode: autoMode,
      fanLevel: fanLevel,
      relayChannels: relayChannels,
      profileVersion: profileVersion,
    );
  }

  /// Xóa cấu hình tự động hóa.
  Future<void> deleteAutomation(int deviceId) async {
    await apiService.deleteAutomation(deviceId);
  }

  // ============================================================
  // MQTT - RELAY
  // ============================================================

  Future<void> relayChannel({
    required String deviceUid,
    required int channel,
    required bool state,
  }) async {
    await apiService.relayChannel(
      deviceUid: deviceUid,
      channel: channel,
      state: state,
    );
  }

  Future<void> relayAll({
    required String deviceUid,
    required bool state,
  }) async {
    await apiService.relayAll(
      deviceUid: deviceUid,
      state: state,
    );
  }

  // ============================================================
  // MQTT - FAN
  // ============================================================

  Future<void> fanLevel({
    required String deviceUid,
    required int level,
  }) async {
    await apiService.fanLevel(
      deviceUid: deviceUid,
      level: level,
    );
  }

  // ============================================================
  // MQTT - CAMERA
  // ============================================================

  Future<void> cameraSecurity({
    required String deviceUid,
    required String state,
  }) async {
    await apiService.cameraSecurity(
      deviceUid: deviceUid,
      state: state,
    );
  }

  // ============================================================
  // DEVICE SECURITY
  // ============================================================

  Future<void> quarantineDevice({
    required String deviceUid,
    String reason = 'Manual test',
  }) async {
    await apiService.quarantineDevice(
      deviceUid: deviceUid,
      reason: reason,
    );
  }

  Future<void> releaseDevice({
    required String deviceUid,
    String reason = 'Manual test',
  }) async {
    await apiService.releaseDevice(
      deviceUid: deviceUid,
      reason: reason,
    );
  }
}