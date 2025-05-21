import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'describe_box.dart';


class ArtCameraController {
  final imagePicker = ImagePicker();

  Future<void> takePictureAndAnalyze(BuildContext context) async {
    // 1. 저장된 파일 경로에서 이미지 불러오기
    final dir = await getTemporaryDirectory();
    final String savedImagePath = '${dir.path}/captured.jpg';
    final File savedPhoto = File(savedImagePath);

    if (!savedPhoto.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장된 사진이 존재하지 않습니다.')),
      );
      return;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://43.203.236.130:8080/recog/analyze'),
    );
    request.files.add(await http.MultipartFile.fromPath('image', savedImagePath));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    String title = '';
    String artist = '';
    String year = '';
    String description = '';

    // 결과 파싱
    if (response.statusCode == 200) {
      print('✅ 작품 인식 성공');
      final data = json.decode(responseBody);
      title = data['title'] ?? '';
      artist = data['artist'] ?? '';
      year = data['year'] ?? '';
      description = data['description'] ?? '';

      final imageResponse = await http.get(Uri.parse('http://43.203.236.130:8080/recog/ping'));
      if (imageResponse.statusCode == 200) {
        await savedPhoto.writeAsBytes(imageResponse.bodyBytes);
      }
    } else {
      print('❌ 작품 인식 실패');
      print('⛔ 응답 코드: ${response.statusCode}');
      print('📦 응답 내용: $responseBody');
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xff3E362F),
          appBar: AppBar(
            title: const Text('musai'),
            backgroundColor: const Color(0xff3E362F),
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          body: Stack(
            children: [
              Image.file(
                savedPhoto,
                width: double.infinity,
                height: MediaQuery.of(context).size.height,
                fit: BoxFit.cover,
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.3,
                minChildSize: 0.2,
                maxChildSize: 0.85,
                builder: (context, scrollController) {
                  return DescriptionScreen(
                    title: title,
                    artist: artist,
                    year: year,
                    description: description,
                    imagePath: savedImagePath,
                    scrollController: scrollController,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}