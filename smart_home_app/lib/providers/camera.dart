import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../repositories/camera.dart';
import '../services/camera_video.dart';

/// Quản lý trạng thái và luồng xử lý của màn hình camera.
class CameraProvider extends ChangeNotifier {
  CameraProvider({
    required this._repository,
    required this._cameraId,
    CameraVideoService? videoService,
  })  : _videoService = videoService ?? CameraVideoService();

  final CameraRepository _repository;
  final String _cameraId;
  final CameraVideoService _videoService;

  // -------------------- MODE --------------------

  int _selectedMode = 0; // 0: Live, 1: History

  int get selectedMode => _selectedMode;

  // -------------------- LIVE SESSION --------------------

  String? _liveSessionId;
  String? _liveStreamUrl;

  bool _liveLoading = false;
  bool _liveError = false;

  String? get liveSessionId => _liveSessionId;
  String? get liveStreamUrl => _liveStreamUrl;

  bool get liveLoading => _liveLoading;
  bool get liveError => _liveError;

  // -------------------- DATE / TIME --------------------

  DateTime _startDateTime =
      DateTime.now().subtract(const Duration(hours: 1));

  DateTime _endDateTime = DateTime.now();

  DateTime get startDateTime => _startDateTime;
  DateTime get endDateTime => _endDateTime;

  // -------------------- HISTORY --------------------

  bool _historyLoading = false;
  String? _historyError;

  List<Map<String, dynamic>> _segments = [];

  bool get historyLoading => _historyLoading;
  String? get historyError => _historyError;

  List<Map<String, dynamic>> get segments =>
      List.unmodifiable(_segments);

  // -------------------- VIDEO PLAYER --------------------

  VideoPlayerController? get videoController =>
      _videoService.controller;

  bool _videoLoading = false;
  String? _videoError;

  bool get videoLoading => _videoLoading;
  String? get videoError => _videoError;

  /// Khởi tạo màn hình camera.
  Future<void> initialize() => createLiveSession();

  // ==================================================
  // LIVE SESSION
  // ==================================================

  /// Tạo phiên xem camera Live.
  Future<void> createLiveSession() async {
    if (_liveLoading || _liveSessionId != null) return;

    _liveLoading = true;
    _liveError = false;

    notifyListeners();

    try {
      final response = await _repository.createLiveSession(
        _cameraId,
      );

      _liveSessionId = response['session_id'] as String;
      _liveStreamUrl = response['stream_url'] as String;
    } catch (_) {
      _liveError = true;
    } finally {
      _liveLoading = false;
      notifyListeners();
    }
  }

  /// Đóng phiên xem camera Live.
  Future<void> closeLiveSession() async {
    final sessionId = _liveSessionId;

    if (sessionId == null) return;

    // Xóa trạng thái trước để UI không tiếp tục dùng phiên cũ.
    _liveSessionId = null;
    _liveStreamUrl = null;

    notifyListeners();

    try {
      await _repository.closeLiveSession(sessionId);
    } catch (_) {
      // Đóng live session không làm dừng recorder.
    }
  }

  // ==================================================
  // MODE
  // ==================================================

  /// Chuyển đổi giữa Live và History.
  Future<void> changeMode(int mode) async {
    if (_selectedMode == mode) return;

    if (mode == 1) {
      // Chuyển sang xem lịch sử.
      await closeLiveSession();

      _selectedMode = 1;
      notifyListeners();

      await loadHistory();
    } else {
      // Chuyển sang xem trực tiếp.
      await disposeVideo();

      _selectedMode = 0;
      notifyListeners();

      await createLiveSession();
    }
  }

  // ==================================================
  // DATE / TIME
  // ==================================================

  void setStartDateTime(DateTime value) {
    _startDateTime = value;
    notifyListeners();
  }

  void setEndDateTime(DateTime value) {
    _endDateTime = value;
    notifyListeners();
  }

  // ==================================================
  // HISTORY
  // ==================================================

  /// Lấy danh sách video theo khoảng thời gian.
  Future<void> loadHistory() async {
    if (!_endDateTime.isAfter(_startDateTime)) {
      _historyError =
          'Thời gian kết thúc phải lớn hơn thời gian bắt đầu';

      notifyListeners();
      return;
    }

    _historyLoading = true;
    _historyError = null;
    _segments = [];

    notifyListeners();

    try {
      _segments = await _repository.getPlaybackSegments(
        cameraId: _cameraId,
        startDateTime: _startDateTime,
        endDateTime: _endDateTime,
      );

      if (_segments.isEmpty) {
        _historyError =
            'Không tìm thấy video trong khoảng thời gian này';
      }
    } catch (e) {
      _historyError = 'Không thể tải lịch sử video: $e';
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }

  // ==================================================
  // VIDEO PLAYER
  // ==================================================

  /// Phát video được chọn trong danh sách lịch sử.
  Future<void> playVideo(
    Map<String, dynamic> segment,
  ) async {
    await disposeVideo();

    _videoLoading = true;
    _videoError = null;

    notifyListeners();

    try {
      final playbackPath =
          segment['playback_url'].toString();

      final videoUrl =
          _repository.resolvePlaybackUrl(playbackPath);

      await _videoService.open(videoUrl);
    } catch (e) {
      _videoError = 'Không thể phát video: $e';
    } finally {
      _videoLoading = false;
      notifyListeners();
    }
  }

  /// Giải phóng video hiện tại.
  Future<void> disposeVideo() async {
    await _videoService.dispose();
    notifyListeners();
  }

  /// Tua video theo số giây.
  Future<void> seekVideo(int seconds) async {
    await _videoService.seekSeconds(seconds);
    notifyListeners();
  }

  /// Phát hoặc tạm dừng video.
  Future<void> toggleVideo() async {
    await _videoService.togglePlayPause();
    notifyListeners();
  }

  // ==================================================
  // DISPOSE
  // ==================================================

  @override
  void dispose() {
    // ChangeNotifier.dispose() không hỗ trợ async.
    // Đóng session trước, sau đó mới đóng HTTP client
    // để tránh request bị hủy giữa chừng.

    final sessionId = _liveSessionId;

    _liveSessionId = null;
    _liveStreamUrl = null;

    if (sessionId != null) {
      _repository.closeLiveSession(sessionId).whenComplete(() {
        _repository.dispose();
      }).catchError((_) {
        _repository.dispose();
      });
    } else {
      _repository.dispose();
    }

    _videoService.dispose();

    super.dispose();
  }
}