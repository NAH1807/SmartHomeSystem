import 'package:flutter/foundation.dart';

import '../models/device.dart';
import '../models/automation.dart';
import '../repositories/device.dart';

class DeviceProvider extends ChangeNotifier {
  final DeviceRepository repository;

  DeviceProvider({required this.repository});

  // ============================================================
  // STATE
  // ============================================================

  List<Device> _devices = [];

  bool _loading = false;

  String? _error;

  // Trạng thái riêng cho Automation
  bool _automationLoading = false;
  bool _automationSaving = false;

  // Lưu profile đã tải theo ID thiết bị
  final Map<int, Automation> _automationProfiles = {};
  String? _automationError;

  // ============================================================
  // GETTERS
  // ============================================================

  List<Device> get devices => List.unmodifiable(_devices);

  bool get loading => _loading;

  String? get error => _error;

  int get totalCount => _devices.length;

  int get onlineCount {
    return _devices.where((device) => device.isOnline).length;
  }

  int get activeCount {
    return _devices.where((device) => device.isOn).length;
  }

  bool get automationLoading => _automationLoading;
  bool get automationSaving => _automationSaving;
  String? get automationError => _automationError;
  Automation? getAutomationProfile(int deviceId) {
    return _automationProfiles[deviceId];
  }
  // ============================================================
  // LOAD ALL DEVICES
  // ============================================================

  Future<void> loadDevices() async {
    _loading = true;
    _error = null;

    notifyListeners();

    try {
      final devices = await repository.getDevices();

      _devices = devices;
    } catch (e) {
      _error = _cleanError(e);
    } finally {
      _loading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // GET DEVICE BY ID
  // ============================================================

  Device? getDeviceById(int deviceId) {
    try {
      return _devices.firstWhere((device) => device.id == deviceId);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // LOAD ONE DEVICE
  // ============================================================

  Future<Device?> loadDevice(int deviceId) async {
    try {
      final device = await repository.getDevice(deviceId);

      final index = _devices.indexWhere((item) => item.id == deviceId);

      if (index == -1) {
        _devices = [..._devices, device];
      } else {
        final newDevices = List<Device>.from(_devices);

        newDevices[index] = device;

        _devices = newDevices;
      }

      notifyListeners();

      return device;
    } catch (e) {
      _error = _cleanError(e);

      notifyListeners();

      return null;
    }
  }

  // ============================================================
  // CREATE DEVICE
  // ============================================================

  Future<Device?> createDevice({
    required String name,
    required DeviceType type,
  }) async {
    _error = null;

    try {
      final device = await repository.createDevice(name: name, type: type);

      _devices = [..._devices, device];

      notifyListeners();

      return device;
    } catch (e) {
      _error = _cleanError(e);

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // UPDATE DEVICE
  // ============================================================

  Future<Device?> updateDevice({
    required int deviceId,
    required String name,
    required DeviceType type,
  }) async {
    _error = null;

    try {
      final updatedDevice = await repository.updateDevice(
        deviceId: deviceId,
        name: name,
        type: type,
      );

      final index = _devices.indexWhere((device) => device.id == deviceId);

      if (index != -1) {
        final newDevices = List<Device>.from(_devices);

        newDevices[index] = updatedDevice;

        _devices = newDevices;
      }

      notifyListeners();

      return updatedDevice;
    } catch (e) {
      _error = _cleanError(e);

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // DELETE DEVICE
  // ============================================================

  Future<void> deleteDevice(int deviceId) async {
    _error = null;

    try {
      await repository.deleteDevice(deviceId);

      _devices = _devices.where((device) => device.id != deviceId).toList();

      notifyListeners();
    } catch (e) {
      _error = _cleanError(e);

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // RELAY - SINGLE CHANNEL
  //
  // channel: 1 -> 4
  // ============================================================

  Future<void> relayChannel({
    required int deviceId,
    required int channel,
    required bool state,
  }) async {
    final device = getDeviceById(deviceId);

    if (device == null) {
      throw Exception('Device not found');
    }

    debugPrint('Device UID: ${device.deviceUid}');
    if (device.type != DeviceType.relay) {
      throw Exception('This device is not a relay');
    }

    if (!device.isOnline) {
      throw Exception('Device is offline');
    }

    if (channel < 1 || channel > 4) {
      throw Exception('Relay channel must be between 1 and 4');
    }

    final deviceUid = device.deviceUid;

    if (deviceUid == null || deviceUid.isEmpty) {
      throw Exception('This device is not connected to MQTT');
    }

    // ----------------------------------------------------------
    // Optimistic local update
    // ----------------------------------------------------------

    final index = _devices.indexWhere((item) => item.id == deviceId);

    if (index != -1) {
      final channels = List<bool>.from(_devices[index].relayChannels);

      channels[channel - 1] = state;

      _devices[index] = _devices[index].copyWith(
        relayChannels: channels,
        isOn: channels.any((value) => value),
      );

      notifyListeners();
    }

    try {
      await repository.relayChannel(
        deviceUid: deviceUid,
        channel: channel,
        state: state,
      );

      _error = null;

      notifyListeners();
    } catch (e) {
      // Load lại thiết bị để lấy trạng thái
      // chính xác từ backend.
      await loadDevice(deviceId);

      _error = _cleanError(e);

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // RELAY - ALL CHANNELS
  // ============================================================

  Future<void> relayAll({required int deviceId, required bool state}) async {
    final device = getDeviceById(deviceId);

    if (device == null) {
      throw Exception('Device not found');
    }

    if (device.type != DeviceType.relay) {
      throw Exception('This device is not a relay');
    }

    if (!device.isOnline) {
      throw Exception('Device is offline');
    }

    final deviceUid = device.deviceUid;

    if (deviceUid == null || deviceUid.isEmpty) {
      throw Exception('This device is not connected to MQTT');
    }

    // ----------------------------------------------------------
    // Optimistic update
    // ----------------------------------------------------------

    final index = _devices.indexWhere((item) => item.id == deviceId);

    if (index != -1) {
      _devices[index] = _devices[index].copyWith(
        relayChannels: List<bool>.filled(4, state),
        isOn: state,
      );

      notifyListeners();
    }

    try {
      await repository.relayAll(deviceUid: deviceUid, state: state);

      _error = null;

      notifyListeners();
    } catch (e) {
      await loadDevice(deviceId);

      _error = _cleanError(e);

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // FAN - SET LEVEL
  //
  // Level:
  // 0 = OFF
  // 1 = Low
  // 2 = Medium
  // 3 = High
  // ============================================================

  Future<void> fanLevel({required int deviceId, required int level}) async {
    final device = getDeviceById(deviceId);

    if (device == null) {
      throw Exception('Device not found');
    }

    if (device.type != DeviceType.fan) {
      throw Exception('This device is not a fan');
    }

    if (!device.isOnline) {
      throw Exception('Device is offline');
    }

    if (level < 0 || level > 3) {
      throw Exception('Fan level must be between 0 and 3');
    }

    final deviceUid = device.deviceUid;

    if (deviceUid == null || deviceUid.isEmpty) {
      _error = 'This device is not connected to MQTT';

      notifyListeners();

      throw Exception(_error);
    }

    // ----------------------------------------------------------
    // Optimistic update
    // ----------------------------------------------------------

    final index = _devices.indexWhere((item) => item.id == deviceId);

    if (index != -1) {
      _devices[index] = _devices[index].copyWith(
        isOn: level > 0,
        fanSpeed: level,
      );

      notifyListeners();
    }

    try {
      await repository.fanLevel(deviceUid: deviceUid, level: level);

      _error = null;

      notifyListeners();
    } catch (e) {
      await loadDevice(deviceId);

      _error = _cleanError(e);

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // CAMERA SECURITY
  // ============================================================

  Future<void> cameraSecurity({
    required int deviceId,
    required String state,
  }) async {
    final device = getDeviceById(deviceId);

    if (device == null) {
      throw Exception('Device not found');
    }

    if (device.type != DeviceType.camera) {
      throw Exception('This device is not a camera');
    }

    if (!device.isOnline) {
      throw Exception('Device is offline');
    }

    final deviceUid = device.deviceUid;

    if (deviceUid == null || deviceUid.isEmpty) {
      throw Exception('This device is not connected to MQTT');
    }

    try {
      await repository.cameraSecurity(deviceUid: deviceUid, state: state);

      // Cập nhật trạng thái local.
      final index = _devices.indexWhere((item) => item.id == deviceId);

      if (index != -1) {
        _devices[index] = _devices[index].copyWith(securityState: state);
      }

      _error = null;

      notifyListeners();
    } catch (e) {
      _error = _cleanError(e);

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // QUARANTINE
  // ============================================================

  Future<void> quarantineDevice(
    int deviceId, {
    String reason = 'Manual test',
  }) async {
    final device = getDeviceById(deviceId);

    if (device == null) {
      throw Exception('Device not found');
    }

    final deviceUid = device.deviceUid;

    if (deviceUid == null || deviceUid.isEmpty) {
      throw Exception('This device is not connected to MQTT');
    }

    try {
      await repository.quarantineDevice(deviceUid: deviceUid, reason: reason);

      // Thiết bị sau khi quarantine
      // không được coi là online.
      final index = _devices.indexWhere((item) => item.id == deviceId);

      if (index != -1) {
        _devices[index] = _devices[index].copyWith(
          isOnline: false,
          securityState: 'quarantine',
        );
      }

      _error = null;

      notifyListeners();
    } catch (e) {
      _error = _cleanError(e);

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // RELEASE
  // ============================================================

  Future<void> releaseDevice(
    int deviceId, {
    String reason = 'Manual test',
  }) async {
    final device = getDeviceById(deviceId);

    if (device == null) {
      throw Exception('Device not found');
    }

    final deviceUid = device.deviceUid;

    if (deviceUid == null || deviceUid.isEmpty) {
      throw Exception('This device is not connected to MQTT');
    }

    try {
      await repository.releaseDevice(deviceUid: deviceUid, reason: reason);

      final index = _devices.indexWhere((item) => item.id == deviceId);

      if (index != -1) {
        _devices[index] = _devices[index].copyWith(
          securityState: 'normal',
          isOnline: true,
        );
      }

      _error = null;

      notifyListeners();
    } catch (e) {
      _error = _cleanError(e);

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // AUTOMATION - LOAD PROFILE
  // ============================================================

  Future<Automation?> getAutomation(int deviceId) async {
    _automationLoading = true;
    _automationError = null;
    notifyListeners();

    try {
      final automation = await repository.getAutomation(deviceId);
      if (automation != null) {
        _automationProfiles[deviceId] = automation;
      } else {
        _automationProfiles.remove(deviceId);
      }

      return automation;
    } catch (e) {
      _automationError = _cleanError(e);
      _error = _automationError;
      rethrow;
    } finally {
      _automationLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // AUTOMATION - SAVE PROFILE
  // ============================================================

  Future<Automation> saveAutomation({
    required int deviceId,
    required bool enabled,

    // Lịch hoạt động
    required String timeOn,
    String? timeOff,
    required List<int> daysOnWeek,

    // Điều kiện nhiệt độ
    double? temperatureOn,
    double? temperatureOff,

    // Fan profile
    int? defaultLevel,
    bool? autoEnabled,
    String? autoMode,
    int? fanLevel,

    // Relay profile
    List<RelayAutomationChannel> relayChannels = const [],

    // Phiên bản cấu hình
    int? profileVersion,
  }) async {
    _automationSaving = true;
    _automationError = null;
    _error = null;
    notifyListeners();

    try {
      final automation = await repository.saveAutomation(
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

      // Cập nhật cache sau khi backend xác nhận lưu thành công.
      _automationProfiles[deviceId] = automation;

      return automation;
    } catch (e) {
      _automationError = _cleanError(e);
      _error = _automationError;
      rethrow;
    } finally {
      _automationSaving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // AUTOMATION - DELETE PROFILE
  // ============================================================

  Future<void> deleteAutomation(int deviceId) async {
    _automationError = null;
    _error = null;
    notifyListeners();

    try {
      await repository.deleteAutomation(deviceId);

      _automationProfiles.remove(deviceId);
    } catch (e) {
      _automationError = _cleanError(e);
      _error = _automationError;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // ============================================================
  // AUTOMATION - CLEAR ERROR
  // ============================================================

  void clearAutomationError() {
    if (_automationError == null) return;

    _automationError = null;
    notifyListeners();
  }

  // ============================================================
  // UPDATE FAN TEMPERATURE
  //
  // Dữ liệu nhiệt độ từ MQTT / Backend
  // ============================================================

  void updateFanTemperature({
    required int deviceId,
    required double temperature,
  }) {
    final index = _devices.indexWhere((device) => device.id == deviceId);

    if (index == -1) {
      return;
    }

    final device = _devices[index];

    if (device.type != DeviceType.fan) {
      return;
    }

    _devices[index] = device.copyWith(temperature: temperature);

    notifyListeners();
  }

  // ============================================================
  // UPDATE SENSOR DATA
  //
  // Dùng khi MQTT/WebSocket/backend
  // gửi trạng thái realtime về Flutter.
  // ============================================================

  void updateSensorData({
    required int deviceId,
    double? temperature,
    bool? isOnline,
    bool? isOn,
    int? fanSpeed,
  }) {
    final index = _devices.indexWhere((device) => device.id == deviceId);

    if (index == -1) {
      return;
    }

    final device = _devices[index];

    _devices[index] = device.copyWith(
      temperature: temperature ?? device.temperature,
      isOnline: isOnline ?? device.isOnline,
      isOn: isOn ?? device.isOn,
      fanSpeed: fanSpeed ?? device.fanSpeed,
    );

    notifyListeners();
  }

  // ============================================================
  // UPDATE RELAY STATUS
  //
  // channel: 1 -> 4
  // ============================================================

  void updateRelayChannel({
    required int deviceId,
    required int channel,
    required bool state,
  }) {
    if (channel < 1 || channel > 4) {
      return;
    }

    final index = _devices.indexWhere((device) => device.id == deviceId);

    if (index == -1) {
      return;
    }

    final device = _devices[index];

    if (device.type != DeviceType.relay) {
      return;
    }

    final channels = List<bool>.from(device.relayChannels);

    channels[channel - 1] = state;

    _devices[index] = device.copyWith(
      relayChannels: channels,
      isOn: channels.any((value) => value),
    );

    notifyListeners();
  }

  // ============================================================
  // UPDATE LOCAL DEVICE
  //
  // Dùng khi nhận dữ liệu realtime
  // từ MQTT/WebSocket.
  // ============================================================

  void updateLocalDevice(Device updatedDevice) {
    final index = _devices.indexWhere(
      (device) => device.id == updatedDevice.id,
    );

    if (index == -1) {
      _devices = [..._devices, updatedDevice];
    } else {
      final newDevices = List<Device>.from(_devices);

      newDevices[index] = updatedDevice;

      _devices = newDevices;
    }

    notifyListeners();
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh() async {
    await loadDevices();
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    if (_error == null) {
      return;
    }

    _error = null;

    notifyListeners();
  }

  // ============================================================
  // REMOVE LOCAL DEVICE
  // ============================================================

  void removeLocalDevice(int deviceId) {
    _devices = _devices.where((device) => device.id != deviceId).toList();

    notifyListeners();
  }

  // ============================================================
  // CLEAN ERROR
  // ============================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }
}
