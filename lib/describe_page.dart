import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'success_dialog.dart';
import 'fail_dialog.dart';
import 'describe_box.dart';
import 'utils/auth_storage.dart';

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

  @override
  void initState() {
    super.initState();
    _startRecognition();
  }

  Future<void> _startRecognition() async {
    final uri = Uri.parse("http://43.203.23.173:8080/recog/analyzeAndRegister");
    final token = await getJwtToken();
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

      if (!mounted) return;

      if (statusCode == 200) {
        final data = json.decode(responseBody);
        setState(() {
          _artData = {
            "title": data['gemini_result']['title'] ?? '정보 없음',
            "artist": data['gemini_result']['artist'] ?? '정보 없음',
            "year": data['gemini_result']['year'] ?? '',
            "description": data['gemini_result']['description'] ?? '',
            "imageUrl": data['original_image_url'] ?? '',
          };
        });
      } else {
        print('❌ 응답 실패 - 상태코드: $statusCode');
        _showFailure();
      }
    } catch (e) {
      print('❌ 예외 발생: $e');
      _showFailure();
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
    if (_artData != null) {
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
            scrollController: ScrollController(),
          ),
        ),
      );
    } else {
      // 아직 응답이 안 왔다면 대기
      Future.delayed(const Duration(seconds: 1), _onSuccessDialogCompleted);
    }
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
