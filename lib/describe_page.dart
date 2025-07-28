import 'dart:io';
import 'package:flutter/material.dart';
import 'describe_box.dart';
import 'success_dialog.dart';

class DescribePage extends StatelessWidget {
  final String imagePath;
  final String? title;
  final String? artist;
  final String? year;
  final String? description;
  final String? imageUrl;

  const DescribePage({
    super.key,
    required this.imagePath,
    this.title,
    this.artist,
    this.year,
    this.description,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SuccessDialog(
        onCompleted: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DescriptionScreen(
                title: title ?? '정보 없음',
                artist: artist ?? '정보 없음',
                year: year ?? '',
                description: description ?? '',
                imagePath: imagePath,
                imageUrl: imageUrl ?? '',
                scrollController: ScrollController(),
              ),
            ),
          );
        },
      ),
    );
  }
}
