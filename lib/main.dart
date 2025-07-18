import 'package:flutter/material.dart';
import 'home_screen.dart';

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
        scaffoldBackgroundColor: const Color(0xFFFFFDFC),
      ),
      home: const HomeScreen(),
    );
  }
}