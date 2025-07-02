import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'bottom_nav_bar.dart';
import 'secrets.dart'; // secrets.dart 파일에서 kakaoMapKey를 가져옵니다.
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission(); // 앱 시작 시 위치 권한 요청 및 GPS 활성화 확인
  }

  // 위치 권한 요청 및 GPS 활성화 확인 함수 (Geolocator만 사용)
  Future<void> _requestLocationPermission() async {
    
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      //print('[Geolocator] Requested permission: $permission');
    }

    if (permission == LocationPermission.deniedForever) {
      //print('[Geolocator] Permanently denied');
      if (mounted) _showPermissionDeniedDialog();
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('[Geolocator] Location service enabled: $serviceEnabled');
    if (!serviceEnabled) {
      if (mounted) _showLocationServiceDisabledDialog();
      return;
    }

    //print('[Geolocator] Location permission granted and service enabled.');
  }

  // 위치 권한 영구 거부 시 다이얼로그 표시
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('위치 권한 필요', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('이 앱은 현재 위치를 표시하기 위해 위치 권한이 필요합니다. 설정에서 위치 권한을 허용해주세요.'),
          actions: <Widget>[
            TextButton(
              child: const Text('나중에', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('설정으로 이동', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () {
                openAppSettings(); // 앱 설정으로 이동
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 위치 서비스 비활성화 시 다이얼로그 표시 및 설정 이동 옵션 제공
  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('위치 서비스 비활성화됨', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('현재 위치를 가져오기 위해 기기의 위치 서비스를 활성화해야 합니다.'),
          actions: <Widget>[
            TextButton(
              child: const Text('확인', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('설정 열기', style: TextStyle(color: Colors.blueAccent)),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings(); // 기기의 위치 설정 화면 열기
                // 사용자가 설정을 변경한 후 앱으로 돌아올 경우를 대비하여
                // 다시 위치 권한 및 서비스 상태를 확인하는 로직을 추가할 수 있습니다.
                // 예: Future.delayed(Duration(seconds: 1), () => _requestLocationPermission());
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFF2E2A26),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'musai',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.05), 
                  _searchBar(screenWidth),
                  SizedBox(height: screenWidth * 0.06), 
                  _sectionTitle('Nearby Exhibition', screenWidth),
                  SizedBox(height: screenWidth * 0.02), 
                  _mapContainer(constraints),
                  SizedBox(height: screenWidth * 0.03),
                  _actionRow(constraints),
                  SizedBox(height: screenWidth * 0.06),
                  _sectionTitle('Recommendation', screenWidth),
                  SizedBox(height: screenWidth * 0.02),
                  _recommendationList(constraints, screenWidth),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(currentIndex: 0),
    );
  }

  /* ────────── Widget Helpers ────────── */

  // 검색 바 위젯
  Widget _searchBar(double screenWidth) => Container(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
        ),
        child: TextField(
          style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
          decoration: InputDecoration(
            icon: Icon(Icons.search, color: Colors.white, size: screenWidth * 0.06),
            hintText: '전시회를 검색하세요',
            hintStyle: TextStyle(color: Colors.white70, fontSize: screenWidth * 0.04),
            border: InputBorder.none,
          ),
        ),
      );

  // 섹션 제목 위젯
  Widget _sectionTitle(String text, double screenWidth) => Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: screenWidth * 0.05,
          fontWeight: FontWeight.bold,
        ),
      );

  // 지도 컨테이너 위젯 (InAppWebView 포함)
  Widget _mapContainer(BoxConstraints constraints) => SizedBox(
        height: constraints.maxWidth * 0.45,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(constraints.maxWidth * 0.05),
          child: InAppWebView(
            initialUrlRequest: Platform.isAndroid
                ? URLRequest(url: WebUri("file:///android_asset/flutter_assets/assets/kakaomap.html"))
                : null,
            initialFile: Platform.isIOS ? "assets/kakaomap.html" : null,
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              transparentBackground: true,
              allowsInlineMediaPlayback: true, // iOS용 옵션
              allowsAirPlayForMediaPlayback: true, // iOS용 옵션
              allowsBackForwardNavigationGestures: true, // iOS용 옵션
              allowsLinkPreview: false, // iOS용 옵션
              sharedCookiesEnabled: true, // iOS용 옵션
              geolocationEnabled: true, // Android용 옵션
              useHybridComposition: true, // Android용 옵션
            ),
            onGeolocationPermissionsShowPrompt: (controller, origin) async {
              return GeolocationPermissionShowPromptResponse(
                origin: origin,
                allow: true,
                retain: true,
              );
            },
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onConsoleMessage: (controller, consoleMessage) {
              print('[WebView Console] [33m${consoleMessage.message}[0m');
            },
            onLoadStop: (controller, url) async {
              print('[WebView] Page loaded: $url');
              if (url.toString().contains('kakaomap.html')) {
                await controller.evaluateJavascript(source: 'injectKakaoMapKeyAndLoadMap("$kakaoMapKey");');
                print('[WebView] Injected Kakao Map Key and called load function.');
              }
            },
            onLoadError: (controller, url, code, message) {
              print('[WebView] Load Error: $url, Code: $code, Message: $message');
            },
            onReceivedHttpError: (controller, request, response) {
              print('[WebView] HTTP Error: ${response.statusCode}, URL: ${request.url}');
            },
          ),
        ),
      );

  // 액션 버튼 행 위젯
  Widget _actionRow(BoxConstraints constraints) {
    final iconSize = constraints.maxWidth * 0.1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildCircleIcon(Icons.grid_view, iconSize),
        _buildCircleIcon(Icons.palette_outlined, iconSize),
        _buildCircleIcon(Icons.image_outlined, iconSize),
        _buildCircleIcon(Icons.add_circle_outline, iconSize),
      ],
    );
  }

  // 추천 목록 위젯
  Widget _recommendationList(BoxConstraints constraints, double screenWidth) {
    final cardWidth = constraints.maxWidth * 0.4;
    final cardMargin = constraints.maxWidth * 0.02;
    return Expanded(
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildRecommendationCard(
            title: "What's inside the pencil",
            description: 'Lorem ipsum dolor sit amet, consectetur...',
            backgroundColor: const Color.fromARGB(255, 255, 230, 238),
            width: cardWidth,
            marginRight: cardMargin,
            screenWidth: screenWidth,
          ),
          SizedBox(width: cardMargin),
          _buildRecommendationCard(
            title: 'The 2nd Chonnam Graduation Exhibition',
            description: 'Lorem ipsum dolor sit amet, consectetur...',
            backgroundColor: Colors.orange[100]!,
            width: cardWidth,
            marginRight: cardMargin,
            screenWidth: screenWidth,
          ),
        ],
      ),
    );
  }

  // 원형 아이콘 위젯
  Widget _buildCircleIcon(IconData icon, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.6),
      );

  // 추천 카드 위젯
  Widget _buildRecommendationCard({
    required String title,
    required String description,
    required Color backgroundColor,
    required double width,
    required double marginRight,
    required double screenWidth,
  }) =>
      AspectRatio(
        aspectRatio: 1, // 정사각형 유지
        child: Container(
          width: width,
          margin: EdgeInsets.only(right: marginRight),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(screenWidth * 0.05),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.40),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(screenWidth * 0.05),
                      bottomRight: Radius.circular(screenWidth * 0.05),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.04,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenWidth * 0.01),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
