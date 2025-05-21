import 'package:flutter/material.dart';
import 'dart:io';

class DescriptionScreen extends StatelessWidget {
  final String title;
  final String artist;
  final String year;
  final String description;
  final String imagePath;

  const DescriptionScreen({
    super.key,
    required this.title,
    required this.artist,
    required this.year,
    required this.description,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff3E362F),
      appBar: AppBar(
        title: const Text('musai'),
        backgroundColor: const Color(0xff3E362F),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            height: 280,
            width: double.infinity,
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$artist, $year', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xff2E2B28),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(
                  description,
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}