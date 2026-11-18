import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/motion.dart';
import '../models/device.dart';
import '../models/automation.dart';

class ApiService {
  // ============================================================
  // BASE URL
  // ============================================================
  //
  // Android Emulator:
  //   http://10.0.2.2:3000/api
  //
  // Chrome/Desktop:
  //   http://localhost:3000/api
  //

  static const String baseUrl = 'http://10.0.2.2:3000/api';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // ============================================================
  // COMMON HEADERS
  // ============================================================

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ============================================================
  // GET ALL DEVICES
  //
  // GET /api/devices
  // ============================================================

  Future<List<Device>> getDevices() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/devices'),
      headers: _headers,
    );

    _checkResponse(response);

    final dynamic decoded = jsonDecode(response.body);

    // Trường hợp API trả:
    // [
    //   {...},
    //   {...}
    // ]
    if (decoded is List) {
      return decoded
          .map((item) => Device.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    // Trường hợp API trả:
    // {
    //   "data": [...]
    // }
    if (decoded is Map && decoded['data'] is List) {
      return (decoded['data'] as List)
          .map((item) => Device.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    throw Exception('Invalid response format from GET /devices');
  }

  // ============================================================
  // GET DEVICE BY ID
  //
  // GET /api/devices/:id
  // ============================================================

  Future<Device> getDevice(int deviceId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/devices/$deviceId'),
      headers: _headers,
    );

    _checkResponse(response);

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      // API:
      // {
      //   "data": {...}
      // }
      if (decoded['data'] is Map) {
        return Device.fromJson(Map<String, dynamic>.from(decoded['data']));
      }

      // API trả trực tiếp:
      // {
      //   "id": 1,
      //   "name": "...",
      //   ...
      // }
      return Device.fromJson(decoded);
    }

    throw Exception('Invalid response format from GET /devices/$deviceId');
  }

  // ============================================================
  // CREATE DEVICE
  //
  // POST /api/devices
  // ============================================================

  Future<Device> createDevice({
    required String name,
    required DeviceType type,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/devices'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'device_type': _deviceTypeToApiValue(type),
      }),
    );

    _checkResponse(response);

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map) {
        return Device.fromJson(Map<String, dynamic>.from(decoded['data']));
      }

      return Device.fromJson(decoded);
    }

    throw Exception('Invalid response format from POST /devices');
  }

  // ============================================================
  // UPDATE DEVICE
  //
  // PUT /api/devices/:id
  // ============================================================

  Future<Device> updateDevice({
    required int deviceId,
    required String name,
    required DeviceType type,
  }) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/devices/$deviceId'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'device_type': _deviceTypeToApiValue(type),
      }),
    );

    _checkResponse(response);

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      if (decoded['data'] is Map) {
        return Device.fromJson(Map<String, dynamic>.from(decoded['data']));
      }

      return Device.fromJson(decoded);
    }

    throw Exception('Invalid response format from PUT /devices/$deviceId');
  }

  // ============================================================
  // DELETE DEVICE
  //
  // DELETE /api/devices/:id
  // ============================================================

  Future<void> deleteDevice(int deviceId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/devices/$deviceId'),
      headers: _headers,
    );

    _checkResponse(response);
  }

  // ============================================================
  // SET INTENSITY
  //
  // PATCH /api/devices/:id/intensity
  //
  // Dùng cho:
  // - Fan
  // - Air Conditioner
  //
  // Giá trị: 0 -> 100
  // ============================================================

  Future<Device> setDeviceIntensity({
    required int deviceId,
    required double intensity,
  }) async {
    final value = intensity.clamp(0.0, 100.0).toDouble();

    final response = await _client.patch(
      Uri.parse('$baseUrl/devices/$deviceId/intensity'),
      headers: _headers,
      body: jsonEncode({'intensity': value}),
    );

    _checkResponse(response);

    return _parseDeviceResponse(
      response,
      endpoint: 'PATCH /devices/$deviceId/intensity',
    );
  }

  // ============================================================
  // SET TARGET TEMPERATURE
  //
  // PATCH /api/devices/:id/temperature
  //
  // Chỉ dành cho Air Conditioner.
  //
  // 16 -> 30 °C
  // ============================================================

  Future<Device> setDeviceTargetTemperature({
    required int deviceId,
    required double temperature,
  }) async {
    final value = temperature.clamp(16.0, 30.0).toDouble();

    final response = await _client.patch(
      Uri.parse('$baseUrl/devices/$deviceId/temperature'),
      headers: _headers,
      body: jsonEncode({'target_temperature': value}),
    );

    _checkResponse(response);

    return _parseDeviceResponse(
      response,
      endpoint: 'PATCH /devices/$deviceId/temperature',
    );
  }

  // ============================================================
  // SET AIR CONDITIONER MODE
  //
  // PATCH /api/devices/:id/ac-mode
  //
  // cool / fan / dry / auto
  // ============================================================

  Future<Device> setDeviceAcMode({
    required int deviceId,
    required String mode,
  }) async {
    const allowedModes = ['cool', 'fan', 'dry', 'auto'];

    if (!allowedModes.contains(mode)) {
      throw Exception('Invalid air conditioner mode: $mode');
    }

    final response = await _client.patch(
      Uri.parse('$baseUrl/devices/$deviceId/ac-mode'),
      headers: _headers,
      body: jsonEncode({'ac_mode': mode}),
    );

    _checkResponse(response);

    return _parseDeviceResponse(
      response,
      endpoint: 'PATCH /devices/$deviceId/ac-mode',
    );
  }

  // ============================================================
  // GET AUTOMATION PROFILE FOR DEVICE
  //
  // GET /api/devices/:id/automation
  // ============================================================
  Future<Automation?> getAutomation(int deviceId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/devices/$deviceId/automation'),
      headers: _headers,
    );

    _checkResponse(response);

    if (response.body.trim().isEmpty) {
      return null;
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded == null) {
      return null;
    }
    if (decoded is Map) {
      if (decoded['data'] is Map) {
        return Automation.fromJson(Map<String, dynamic>.from(decoded['data']));
      }

      // API trả trực tiếp automation object.
      return Automation.fromJson(Map<String, dynamic>.from(decoded));
    }

    throw Exception(
      'Invalid response format from GET /devices/$deviceId/automation',
    );
  }

  // ============================================================
  // SAVE AUTOMATION PROFILE
  //
  // PUT /api/devices/:id/automation
  //
  // Dùng cho:
  // - Relay: cấu hình từng kênh đèn
  // - Fan: mức quạt, lịch hoạt động, chế độ tự động
  // - Điều hòa: nhiệt độ mục tiêu
  // ============================================================
  Future<Automation> saveAutomation({
    required int deviceId,
    required bool enabled,

    // Lịch hoạt động chung
    required String timeOn,
    String? timeOff,
    required List<int> daysOnWeek,

    // Điều khiển theo nhiệt độ
    double? temperatureOn,
    double? temperatureOff,

    // Fan profile
    int? defaultLevel,
    bool? autoEnabled,
    String? autoMode,
    int? fanLevel,

    // Relay profile
    List<RelayAutomationChannel> relayChannels = const [],

    // Phiên bản profile
    int? profileVersion,
  }) async {
    final payload = <String, dynamic>{
      'device_id': deviceId,
      'enabled': enabled,
      'time_on': timeOn,
      'time_off': timeOff,
      'day_on_week': daysOnWeek,
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

    // Bỏ các trường null để không ghi đè cấu hình hiện có
    // bằng null nếu client không gửi trường đó.
    //payload.removeWhere((key, value) => value == null);

    final response = await _client.put(
      Uri.parse('$baseUrl/devices/$deviceId/automation'),
      headers: _headers,
      body: jsonEncode(payload),
    );

    _checkResponse(response);

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map) {
      // Hỗ trợ:
      // { "data": { ...automation... } }
      final dynamic data = decoded['data'];

      if (data is Map) {
        return Automation.fromJson(Map<String, dynamic>.from(data));
      }

      // API trả trực tiếp automation object.
      return Automation.fromJson(Map<String, dynamic>.from(decoded));
    }

    throw Exception(
      'Invalid response format from PUT /devices/$deviceId/automation',
    );
  }

  // ============================================================
  // DELETE AUTOMATION FOR DEVICE
  // ============================================================
  Future<void> deleteAutomation(int deviceId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/devices/$deviceId/automation'),
      headers: _headers,
    );

    _checkResponse(response);
  }

  // ===========================================================
  // MQTT
  // ===========================================================
  Future<Map<String, dynamic>> getMqttStatus() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/mqtt/status'),
      headers: _headers,
    );

    _checkResponse(response);

    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  // Relay 1 channel control
  Future<void> relayChannel({
    required String deviceUid,
    required int channel,
    required bool state,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/mqtt/relay/channel'),
      headers: _headers,
      body: jsonEncode({
        'device_uid': deviceUid,
        'channel': channel,
        'state': state,
      }),
    );

    _checkResponse(response);
  }

  // Relay all channels control
  Future<void> relayAll({
    required String deviceUid,
    required bool state,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/mqtt/relay/all'),
      headers: _headers,
      body: jsonEncode({'device_uid': deviceUid, 'state': state}),
    );

    _checkResponse(response);
  }

  // Fan level control
  Future<void> fanLevel({required String deviceUid, required int level}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/mqtt/fan/level'),
      headers: _headers,
      body: jsonEncode({'device_uid': deviceUid, 'level': level}),
    );

    _checkResponse(response);
  }

  // Camera security control
  Future<void> cameraSecurity({
    required String deviceUid,
    required String state,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/mqtt/camera/security'),
      headers: _headers,
      body: jsonEncode({'device_uid': deviceUid, 'state': state}),
    );

    _checkResponse(response);
  }

  // Quarantine device
  Future<void> quarantineDevice({
    required String deviceUid,
    String reason = 'Manual test',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/mqtt/security/$deviceUid/quarantine'),
      headers: _headers,
      body: jsonEncode({'reason': reason}),
    );

    _checkResponse(response);
  }

  //Automation

  // Release device from quarantine
  Future<void> releaseDevice({
    required String deviceUid,
    String reason = 'Manual test',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/mqtt/security/$deviceUid/release'),
      headers: _headers,
      body: jsonEncode({'reason': reason}),
    );

    _checkResponse(response);
  }

  // ============================================================
  // GET MOTION CONFIG
  //
  // GET /api/devices/:id/motion
  // ============================================================

  Future<Motion?> getMotionConfig(int deviceId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/devices/$deviceId/motion'),
      headers: _headers,
    );

    _checkResponse(response);

    if (response.body.trim().isEmpty) {
      return null;
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded == null) {
      return null;
    }

    if (decoded is Map) {
      if (decoded['data'] is Map) {
        return Motion.fromJson(Map<String, dynamic>.from(decoded['data']));
      }

      // API trả trực tiếp Motion object.
      return Motion.fromJson(Map<String, dynamic>.from(decoded));
    }

    throw Exception(
      'Invalid response format from GET /devices/$deviceId/motion',
    );
  }

  // ============================================================
  // SAVE MOTION CONFIG
  //
  // PUT /api/devices/:id/motion
  // ============================================================
  Future<Map<String, dynamic>> saveMotion({
    required int deviceId,
    required bool enabled,
    required int holdTime,
    required int cooldownTime,
  }) async {
    final payload = {
      'device_id': deviceId,
      'enabled': enabled,
      'hold_seconds': holdTime,
      'cooldown_seconds': cooldownTime,
    };

    final response = await _client.put(
      Uri.parse('$baseUrl/devices/$deviceId/motion'),
      headers: _headers,
      body: jsonEncode(payload),
    );

    _checkResponse(response);

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw Exception(
      'Invalid response format from PUT /devices/$deviceId/motion',
    );
  }

  // ============================================================
  // MQTT MOTION
  // ============================================================
  // POST /api/mqtt/motion/:id
  Future<Map<String, dynamic>> motionFan({
    required int deviceId,
    required String deviceName,
    required Map<String, dynamic> settings,
  }) async {
    final payload = {'name': deviceName, 'settings': settings};

    final response = await _client.post(
      Uri.parse('$baseUrl/mqtt/motion/$deviceId'),
      headers: _headers,
      body: jsonEncode(payload),
    );

    _checkResponse(response);

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw Exception('Invalid response format from POST /mqtt/motion/$deviceId');
  }

  Future<Map<String, dynamic>> motionRelay({
    required int deviceId,
    required String deviceName,
    required Map<String, dynamic> settings,
  }) async {
    final payload = {'name': deviceName, 'settings': settings};

    final response = await _client.post(
      Uri.parse('$baseUrl/mqtt/motion/$deviceId'),
      headers: _headers,
      body: jsonEncode(payload),
    );

    _checkResponse(response);
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    throw Exception('Invalid response format from POST /mqtt/motion/$deviceId');
  }

  // ============================================================
  // PARSE DEVICE RESPONSE
  // ============================================================

  Device _parseDeviceResponse(
    http.Response response, {
    required String endpoint,
  }) {
    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      // {
      //   "data": {...}
      // }
      if (decoded['data'] is Map) {
        return Device.fromJson(Map<String, dynamic>.from(decoded['data']));
      }

      // API trả trực tiếp Device object.
      return Device.fromJson(decoded);
    }

    throw Exception('Invalid response format from $endpoint');
  }

  // ============================================================
  // DEVICE TYPE -> API STRING
  // ============================================================

  String _deviceTypeToApiValue(DeviceType type) {
    switch (type) {
      case DeviceType.relay:
        return 'relay';

      case DeviceType.fan:
        return 'fan';

      case DeviceType.camera:
        return 'camera';
    }
  }

  // ============================================================
  // HTTP RESPONSE CHECK
  // ============================================================

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String message = 'Request failed';

    try {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is Map) {
        if (decoded['message'] != null) {
          message = decoded['message'].toString();
        } else if (decoded['error'] != null) {
          message = decoded['error'].toString();
        }
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
        message = response.body;
      }
    }

    throw Exception('$message (HTTP ${response.statusCode})');
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _client.close();
  }
}
