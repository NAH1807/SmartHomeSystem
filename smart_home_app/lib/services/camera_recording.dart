import 'dart:convert';
import 'package:http/http.dart' as http;

/// Chịu trách nhiệm giao tiếp HTTP với Camera Recording Service.
class CameraRecordingService {
  CameraRecordingService({
    this.baseUrl = 'http://192.168.1.130:8765',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// Tạo phiên xem camera Live.
  Future<Map<String, dynamic>> createLiveSession(String cameraId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/live-sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_id': cameraId}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Không thể tạo phiên xem camera (${response.statusCode})',
      );
    }

    final data = Map<String, dynamic>.from(
      jsonDecode(response.body),
    );

    final streamPath = data['stream_url']?.toString();

    if (data['session_id'] == null || streamPath == null) {
      throw Exception('Phản hồi tạo phiên camera không hợp lệ');
    }

    return {
      'session_id': data['session_id'].toString(),
      'stream_url': Uri.parse(baseUrl).resolve(streamPath).toString(),
    };
  }

  /// Đóng phiên xem Live.
  /// Việc này không làm dừng quá trình ghi hình.
  Future<void> closeLiveSession(String sessionId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/live-sessions/$sessionId'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Không thể đóng phiên xem camera (${response.statusCode})',
      );
    }
  }

  /// Lấy danh sách video lịch sử theo khoảng thời gian.
  Future<List<Map<String, dynamic>>> getPlaybackSegments({
    required String cameraId,
    required DateTime startDateTime,
    required DateTime endDateTime,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/playback/manifest',
    ).replace(
      queryParameters: {
        'device_id': cameraId,
        'start_time': startDateTime.toUtc().toIso8601String(),
        'end_time': endDateTime.toUtc().toIso8601String(),
      },
    );

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Không thể tải lịch sử video (${response.statusCode})',
      );
    }

    final data = Map<String, dynamic>.from(
      jsonDecode(response.body),
    );

    final rawSegments =
        (data['segments'] as List<dynamic>?) ?? [];

    return rawSegments
        .where(
          (item) =>
              item is Map &&
              item['status'] == 'complete' &&
              item['file_exists'] == true &&
              item['playback_url'] != null,
        )
        .map(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  /// Chuyển đường dẫn video thành URL đầy đủ.
  String resolvePlaybackUrl(String playbackPath) {
    return Uri.parse(baseUrl).resolve(playbackPath).toString();
  }

  void dispose() {
    _client.close();
  }
}