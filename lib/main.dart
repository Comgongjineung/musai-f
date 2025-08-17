import 'package:flutter/material.dart';
import 'homescreen/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;
import 'alarm.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp();

  print("🚀 runApp 호출 직전");
  runApp(const MusaiApp());

  if (Platform.isAndroid) {
    // Android 환경에서만 알림 초기화
    await initializeNotifications();
    await setupFirebaseMessaging();
  }
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