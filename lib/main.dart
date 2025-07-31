import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'utils/auth_storage.dart';

// flutter_local_notifications 전역 변수
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Android 채널 전역 변수
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'default_channel', // 채널 ID
  '기본 채널', // 채널 이름
  description: '앱 기본 알림 채널',
  importance: Importance.high,
);

// 백그라운드/종료 상태에서 메시지 수신 시 호출
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("백그라운드 메시지 수신: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp();

  // 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Android 채널 생성
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // flutter_local_notifications 초기화
  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: initSettingsAndroid);

//navigator는 백그라운드(onMessageOpenedApp)와 완전 종료(getInitialMessage())일 때만
//포그라운드 알림 클릭 시 처리(payload 저장만)
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      print("🔗 알림 클릭됨: ${response.payload}");
    },
  );

  // FCM 인스턴스
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // iOS 포그라운드 알림 허용
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // iOS 알림 권한 요청
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print("알림 권한 상태: ${settings.authorizationStatus}");

  // FCM 토큰 가져오기
  String? fcmToken = await messaging.getToken();
  print("FCM Token: $fcmToken");

  // FCM 토큰 서버 저장 함수
Future<void> sendFcmTokenToServer(String fcmToken) async {
  final jwtToken = await getJwtToken(); // JWT 토큰
  final userId = await getUserId();     // 로그인한 사용자 ID

  if (jwtToken == null || userId == null) {
    print("❌ 로그인 정보 없음. 서버 전송 불가");
    return;

    
  }

  try {
    final uri = Uri.parse('http://43.203.23.173:8080/alarm/token').replace(
      queryParameters: {
        'userId': userId.toString(),
        'token': fcmToken,
      },
    );

    final response = await http.post(
      uri,
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode == 200) {
      print("✅ FCM 토큰 서버 저장 성공");
    } else {
      print("⚠️ 서버 응답 오류: ${response.statusCode} ${response.body}");
    }
  } catch (e) {
    print("❌ 서버 전송 에러: $e");
  }
}

 if (fcmToken != null) {
  // 1. 로컬에 저장
  await saveFcmToken(fcmToken);
  // 2. 서버로 전송
  await sendFcmTokenToServer(fcmToken);
}

  // 앱 종료 상태에서 알림 클릭 처리
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print("🚀 앱 종료 상태에서 푸시 클릭: ${initialMessage.data}");
    // TODO: 클릭 시 이동할 화면 처리
  }

  // 포그라운드 메시지 수신
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 포그라운드 알림: ${message.notification?.title}");

    flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? "제목 없음",
      message.notification?.body ?? "내용 없음",
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: message.data['payload'] ?? '',
    );
  });

  // 백그라운드 상태 - 알림 클릭 후 앱이 열릴 때 처리
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("📌 알림 클릭으로 앱 열림: ${message.data}");
    // TODO: 클릭 시 이동할 화면 처리
  });

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