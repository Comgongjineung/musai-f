import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class TTSService {
  static const String _baseUrl = 'http://52.78.107.134:8080/tts/synthesize';

  /// 텍스트를 받아 TTS 음성(mp3) 데이터를 반환합니다.
  static Future<Uint8List?> synthesize(String text) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'text/plain'},
        body: text,
      );

      if (response.statusCode == 200) {
        // 성공 시 바이너리 오디오 데이터 반환
        return response.bodyBytes;
      } else if (response.statusCode == 500) {
        // 서버 오류 시 JSON 파싱
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(data['error'] ?? 'TTS 변환 실패');
      } else {
        throw Exception('TTS 변환 실패: [${response.statusCode}]');
      }
    } catch (e) {
      rethrow;
    }
  }
} 