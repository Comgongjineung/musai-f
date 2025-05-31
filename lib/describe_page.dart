import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'describe_box.dart';
import 'success_dialog.dart';

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

  bool isLoading = true;
  bool successDialogCompleted = false;

  String fetchedTitle = '';
  String fetchedArtist = '';
  String fetchedYear = '';
  String fetchedDescription = '';
  String fetchedImageUrl = '';

  @override
  void initState() {
    super.initState();
    // 위젯이 처음 생성될 때 이미지 분석 시작
    analyzeImage();
  }

  Future<void> analyzeImage() async {
    final savedPhoto = File(widget.imagePath);

    if (!savedPhoto.existsSync()) {
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장된 사진이 존재하지 않습니다.')),
        );
        // 파일이 없으면 이전 화면으로 돌아가기
        Navigator.pop(context);
      }
      return;
    }

    // 이미지 분석 API 호출
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://3.36.99.189:8080/recog/analyze'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', widget.imagePath));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('🎯 요청한 URL: ${request.url}');
      print('📦 응답 내용: $responseBody');

      if (response.statusCode == 200) {
        print('✅ 작품 인식 성공');
        final data = json.decode(responseBody);
        if (!mounted) return;

        // API 응답에서 직접 데이터 추출
        fetchedTitle = data['gemini_result']['title'] ?? '';
        fetchedArtist = data['gemini_result']['artist'] ?? '';
        fetchedYear = data['gemini_result']['year'] ?? '';
        fetchedDescription = data['gemini_result']['description'] ?? '';
        fetchedImageUrl = data['gemini_result']['image_url'] ?? '';

        // 데이터 로딩 완료 후 DescriptionScreen으로 이동
        // DescribePage는 데이터를 준비한 뒤 바로 DescriptionScreen으로 전환합니다.
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        _tryNavigateToDescriptionScreen();

      } else {
        print('❌ 작품 인식 실패');
        print('⛔ 응답 코드: ${response.statusCode}');
        print('📦 응답 내용: $responseBody');
        // 실패 시 Snackbar 표시 후 이전 화면으로 돌아가기
        if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('작품 인식에 실패했습니다.')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('❌ 에러 발생: $e');
      // 에러 발생 시 Snackbar 표시 후 이전 화면으로 돌아가기
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('에러 발생: ${e.toString()}')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _tryNavigateToDescriptionScreen() {
    if (!isLoading && successDialogCompleted && mounted) {
      _goToDescriptionScreen();
    }
  }

  void _goToDescriptionScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DescriptionScreen(
          title: fetchedTitle,
          artist: fetchedArtist,
          year: fetchedYear,
          description: fetchedDescription,
          imagePath: widget.imagePath,
          imageUrl: fetchedImageUrl,
          scrollController: ScrollController(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (isLoading)
            SuccessDialog(
              onCompleted: () {
                setState(() {
                  successDialogCompleted = true;
                });
                _tryNavigateToDescriptionScreen();
              },
            ),
        ],
      ),
    );
  }
}