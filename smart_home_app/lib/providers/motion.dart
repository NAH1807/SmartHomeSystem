import 'package:flutter/foundation.dart';

import '../models/motion.dart';
import '../repositories/motion.dart';

class MotionProvider extends ChangeNotifier {
  final MotionRepository repository;

  MotionProvider({required this.repository});

  // ============================================================
  // STATE
  // ============================================================

  bool _loading = false;
  bool _saving = false;

  String? _error;

  // Lưu cấu hình Motion theo ID thiết bị
  final Map<int, Motion> _motionConfigs = {};

  // ============================================================
  // GETTERS
  // ============================================================

  bool get loading => _loading;

  bool get saving => _saving;

  String? get error => _error;

  /// Lấy cấu hình Motion từ cache.
  Motion? getMotionConfig(int deviceId) {
    return _motionConfigs[deviceId];
  }

  // ============================================================
  // LOAD MOTION CONFIG
  // ============================================================

  Future<Motion?> loadMotionConfig(int deviceId) async {
    _loading = true;
    _error = null;

    notifyListeners();

    try {
      final motion = await repository.getMotionConfig(deviceId);

      if (motion != null) {
        _motionConfigs[deviceId] = motion;
      } else {
        _motionConfigs.remove(deviceId);
      }

      return motion;
    } catch (e) {
      _error = _cleanError(e);

      rethrow;
    } finally {
      _loading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // SAVE MOTION CONFIG
  // ============================================================
  Future<Map<String, dynamic>> saveMotion({
    required int deviceId,
    required bool enabled,
    required int holdTime,
    required int cooldownTime,
  }) async {
    _saving = true;
    _error = null;

    notifyListeners();

    try {
      final response = await repository.saveMotion(
        deviceId: deviceId,
        enabled: enabled,
        holdTime: holdTime,
        cooldownTime: cooldownTime,
      );

      // Backend xác nhận lưu thành công.
      return response;
    } catch (e) {
      _error = _cleanError(e);
      rethrow;
    } finally {
      _saving = false;
      notifyListeners();
    }
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
    _saving = true;
    _error = null;

    notifyListeners();

    try {
      final response = await repository.motionFan(
        deviceId: deviceId,
        deviceName: deviceName,
        enabled: enabled,
        holdTime: holdTime,
        cooldownTime: cooldownTime,
      );

      // Backend xác nhận lưu thành công.
      return response;
    } catch (e) {
      _error = _cleanError(e);
      rethrow;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> motionRelay({
    required int deviceId,
    required String deviceName,
    required Map<int,String> sensorId,
    required String motionMode,
    required int holdTime,
    required int cooldownTime,
  }) async {
    _saving = true;
    _error = null;

    notifyListeners();

    try {
      final response = await repository.motionRelay(
        deviceId: deviceId,
        deviceName: deviceName,
        sensorId: sensorId,
        motionMode: motionMode,
        holdTime: holdTime,
        cooldownTime: cooldownTime,
      );

      // Backend xác nhận lưu thành công.
      return response;
    } catch (e) {
      _error = _cleanError(e);
      rethrow;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  // ============================================================
  // REMOVE LOCAL CONFIG
  // ============================================================

  void removeMotionConfig(int deviceId) {
    _motionConfigs.remove(deviceId);

    notifyListeners();
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    if (_error == null) return;

    _error = null;

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
