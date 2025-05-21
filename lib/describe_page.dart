import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'describe_box.dart';

class ArtCameraController {
  final ImagePicker_picker = ImagePicker();

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

    // 2. 상세 화면으로 바로 이동 (GPT API 없이)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DescriptionScreen(
          title: '임시 제목',
          artist: '작가명 미상',
          year: '연도 미상',
          description: '이 작품은 사용자에 의해 촬영되었으며, AI 분석 없이 바로 보여집니다.',
          imagePath: savedImagePath,
        ),
      ),
    );
  }
}