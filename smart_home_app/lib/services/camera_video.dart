import 'package:video_player/video_player.dart';

/// Quản lý vòng đời và các thao tác của video_player.
class CameraVideoService {
  VideoPlayerController? _controller;

  VideoPlayerController? get controller => _controller;

  /// Mở và phát video.
  Future<VideoPlayerController> open(String url) async {
    await dispose();

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
    );

    _controller = controller;

    try {
      await controller.initialize();
      await controller.play();

      return controller;
    } catch (_) {
      if (identical(_controller, controller)) {
        _controller = null;
      }

      await controller.dispose();
      rethrow;
    }
  }

  /// Phát hoặc tạm dừng video.
  Future<void> togglePlayPause() async {
    final current = _controller;

    if (current == null || !current.value.isInitialized) {
      return;
    }

    if (current.value.isPlaying) {
      await current.pause();
    } else {
      await current.play();
    }
  }

  /// Tua video theo số giây.
  /// Số âm: tua lùi.
  /// Số dương: tua tiến.
  Future<void> seekSeconds(int seconds) async {
    final current = _controller;

    if (current == null || !current.value.isInitialized) {
      return;
    }

    final position = current.value.position;
    final duration = current.value.duration;

    final requested = position + Duration(seconds: seconds);

    final target = requested < Duration.zero
        ? Duration.zero
        : requested > duration
            ? duration
            : requested;

    await current.seekTo(target);
  }

  /// Giải phóng VideoPlayerController.
  Future<void> dispose() async {
    final oldController = _controller;

    _controller = null;

    await oldController?.dispose();
  }
}