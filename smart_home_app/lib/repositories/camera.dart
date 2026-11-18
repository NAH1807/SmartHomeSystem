import '../services/camera_recording.dart';

/// Repository gom các thao tác dữ liệu camera.
/// Provider không cần biết chi tiết HTTP hoặc cấu trúc request.
class CameraRepository {
  CameraRepository(this.cameraRecordingService);
  final CameraRecordingService cameraRecordingService;

  Future<Map<String, dynamic>> createLiveSession(
    String cameraId,
  ) {
    return cameraRecordingService.createLiveSession(cameraId);
  }

  Future<void> closeLiveSession(String sessionId) {
    return cameraRecordingService.closeLiveSession(sessionId);
  }

  Future<List<Map<String, dynamic>>> getPlaybackSegments({
    required String cameraId,
    required DateTime startDateTime,
    required DateTime endDateTime,
  }) {
    return cameraRecordingService.getPlaybackSegments(
      cameraId: cameraId,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
    );
  }

  String resolvePlaybackUrl(String playbackPath) {
    return cameraRecordingService.resolvePlaybackUrl(playbackPath);
  }

  void dispose() {
    cameraRecordingService.dispose();
  }
}