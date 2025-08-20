import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../camera/success_dialog.dart';
import '../camera/fail_dialog.dart';
import 'describe_box.dart';
import '../utils/auth_storage.dart';
import 'package:flutter/services.dart';

class DescribePage extends StatefulWidget {
  final String imagePath;

  const DescribePage({
    super.key,
    required this.imagePath,
  });

  @override
  State<DescribePage> createState() => _DescribePageState();
}

class _DescribePageState extends State<DescribePage> {
  bool _showSuccessDialog = true;
  bool _hasFailed = false;
  Map<String, dynamic>? _artData;

  Timer? _retryTimer;
  bool _isDisposed = false;
  String? _jwtToken;

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    } else {
      //debugPrint('🔕 [DescribePage] skip setState because unmounted');
    }
  }

  @override
  void initState() {
    super.initState();
    _startRecognition();
  }

  Future<void> _startRecognition() async {
    final uri = Uri.parse("http://43.203.23.173:8080/recog/analyze");
    final token = await getJwtToken();
    _jwtToken = token; // 나중에 Describe 화면에서 AR 버튼을 누를 때 사용
    if (token == null) {
      _showFailure();
      return;
    }

    var request = http.MultipartRequest("POST", uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', widget.imagePath));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final statusCode = response.statusCode;

      //if (!mounted) return;

      if (statusCode == 200) {
        print('🔍 API 응답 전체 데이터: $responseBody');
        final data = json.decode(responseBody);
        print('📊 파싱된 JSON 데이터: $data');
        print('🎨 gemini_result: ${data['gemini_result']}');
        print('🎭 style 값: ${data['gemini_result']?['style']}');
        
        _safeSetState(() {
          _artData = {
            "title": data['gemini_result']['title'] ?? '정보 없음',
            "artist": data['gemini_result']['artist'] ?? '정보 없음',
            "year": data['gemini_result']['year'] ?? '',
            "description": data['gemini_result']['description'] ?? '',
            "imageUrl": data['original_image_url'] ?? '',
            "style": data['gemini_result']['style'] ?? '', // 예술사조 추가
          };
        });
        print('🎯 최종 _artData: $_artData');
        // 인식이 완료되면 뷰포리아에 이미지 등록
        await _registerToVuforia(_artData!["title"] ?? "", _artData!["imageUrl"] ?? "");
      } else {
        print('❌ 응답 실패 - 상태코드: $statusCode');
        _showFailure();
      }
    } catch (e) {
      print('❌ 예외 발생: $e');
      _showFailure();
    }
  }

  // 뷰포리아 등록 API 호출
  Future<void> _registerToVuforia(String title, String imageUrl, {int attempt = 0}) async {
    if (imageUrl.isEmpty) {
      print('❌ 뷰포리아 등록 실패: imageUrl 비어있음');
      return;
    }
    final imgRes = await http.get(Uri.parse(imageUrl));
    if (imgRes.statusCode != 200) {
      print('❌ 뷰포리아 등록 실패: 이미지 다운로드 실패 (${imgRes.statusCode})');
      return;
    }
    final imageBytes = imgRes.bodyBytes;

    try {
      final uri = Uri.parse(
          "http://43.203.23.173:8080/ar/vuforia/register?title=${Uri.encodeQueryComponent(title)}");
      final token = await getJwtToken();
      if (token == null) return; 

      final request = http.MultipartRequest("POST", uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'original.jpg', // 서버에 전달될 임의 파일명
        contentType: MediaType('image', 'jpeg'),
      ));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final statusCode = response.statusCode;

      //if (!mounted) return;

      if (statusCode == 200) {
        final data = json.decode(responseBody);
        if (data is Map && data['success'] == true) {
          final String targetId = (data['targetId'] ?? '').toString();
          _safeSetState(() {
            _artData = {
              ...?_artData,
              'vuforiaTargetId': targetId,
              'vuforiaMessage': data['message'] ?? '',
            };
          });
          print('✅ 뷰포리아 등록 성공');
          // 뷰포리아 등록 성공 후, AI 좌표/해설 메타데이터 업데이트 API 호출
          await _updateAIPoints(targetId, imageUrl);
        } else {
          print('⚠️ 뷰포리아 등록 응답 성공 아님: $responseBody');
        }
      } else {
        print('❌ 뷰포리아 등록 실패 - 상태코드: $statusCode, body: $responseBody');
      }
    } catch (e) {
      print('❌ 뷰포리아 등록 예외: $e');
    }
  }

  // AI 서버에 좌표, 해설 메타데이터 요청하여 DB 업데이트
  Future<void> _updateAIPoints(String targetId, String imageUrl) async {
    try {
      if (targetId.isEmpty) {
        print('좌표 업데이트 실패: targetId 비어있음');
        return;
      }
      if (imageUrl.isEmpty) {
        print('좌표 업데이트 실패: imageUrl 비어있음');
        return;
      }

      // 원본 이미지 다시 다운로드 (서버는 파일 바이너리를 요구)
      final imgRes = await http.get(Uri.parse(imageUrl));
      if (imgRes.statusCode != 200) {
        print('좌표 업데이트 실패: 이미지 다운로드 실패 (${imgRes.statusCode})');
        return;
      }
      final imageBytes = imgRes.bodyBytes;

      final token = await getJwtToken();
      if (token == null) return;

      final uri = Uri.parse('http://43.203.23.173:8080/ar/points/ai-update?target_id=${Uri.encodeQueryComponent(targetId)}');
      final req = http.MultipartRequest('POST', uri);
      req.headers['Authorization'] = 'Bearer $token';
      req.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'original.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));

      final res = await req.send();
      final body = await res.stream.bytesToString();
      final code = res.statusCode;

      print('📥 [AI-Update] 최종 응답 code=$code body=$body');

      if (code == 200) {
        final decoded = json.decode(body);
        if (decoded is List) {
          _safeSetState(() {
            _artData = {
              ...?_artData,
              'points': decoded,
            };
          });
          print('✅ 메타데이터 업데이트 성공: ${decoded.length}개 포인트');
        } else {
          print('업데이트 응답 형식이 리스트가 아님: $body');
        }
      } else {
        print('좌표 업데이트 실패 - 상태코드: $code, body: $body');
      }
    } catch (e) {
      print('좌표 업데이트 예외: $e');
    }
  }

  void _showFailure() {
    if (!mounted) return;
    setState(() {
      _showSuccessDialog = false;
      _hasFailed = true;
    });
  }

  void _onSuccessDialogCompleted() {
    if (_isDisposed) return;
    if (_artData != null) {
      print('🎭 DescriptionScreen 호출 시 style 값: ${_artData!['style']}');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DescriptionScreen(
            title: _artData!['title'],
            artist: _artData!['artist'],
            year: _artData!['year'],
            description: _artData!['description'],
            imagePath: widget.imagePath,
            imageUrl: _artData!['imageUrl'],
            style: _artData!['style'], // 예술사조 추가
            scrollController: ScrollController(),
            // ⚠️ Describe 화면에서 AR 버튼 탭 시 이 토큰으로 _unityChannel.invokeMethod('SetJwtToken', token) 하세요.
            jwtToken: _jwtToken,
          ),
        ),
      );
    } else {
      // 아직 응답이 안 왔다면 대기
      _retryTimer = Timer(const Duration(seconds: 1), () {
        if (_isDisposed) return;
        _onSuccessDialogCompleted();
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (_showSuccessDialog)
            SuccessDialog(onCompleted: _onSuccessDialogCompleted),
          if (_hasFailed)
            const Center(
              child: FailDialog(),
            ),
        ],
      ),
    );
  }
}
