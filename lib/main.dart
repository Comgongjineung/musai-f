import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'main_camera_page.dart';

void main() {
  runApp(const MusaiApp());
}

class MusaiApp extends StatelessWidget {
  const MusaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: const Color(0xFF5F5F5F),
      ),
      home: const HomeScreen(),
    );
  }
}