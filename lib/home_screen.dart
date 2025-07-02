import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'bottom_nav_bar.dart';
import 'secrets.dart'; // secrets.dart 파일에서 kakaoMapKey를 가져옵니다.

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

  // 위치 권한 요청 및 GPS 활성화 확인 함수
  Future<void> _requestLocationPermission() async {
    // 1. 앱 위치 권한 상태 확인 및 요청
    var status = await Permission.location.status;

    if (status.isDenied) {
      // 권한이 거부되었으면 요청
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      // 권한이 영구적으로 거부되었으면 설정 페이지로 이동 안내
      if (mounted) { // 위젯이 마운트된 상태에서만 showDialog 호출
        _showPermissionDeniedDialog();
      }
      return; // 권한이 없으므로 더 진행하지 않음
    }

    // 2. 기기의 위치 서비스(GPS) 활성화 상태 확인
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showLocationServiceDisabledDialog(); // 위치 서비스 비활성화 다이얼로그 표시
      }
      return; // 위치 서비스가 비활성화되어 있으므로 더 진행하지 않음
    }

    // 모든 권한 및 서비스가 활성화되었다면, 여기에서 웹뷰에 위치 정보를 요청하거나
    // kakaomap.html이 자동으로 위치 정보를 가져오도록 둡니다.
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
    return Scaffold(
      backgroundColor: const Color(0xFF3C342E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'musai',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard', // 폰트가 앱에 포함되어 있는지 확인 필요
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _searchBar(),
              const SizedBox(height: 20),
              _sectionTitle('Nearby Exhibition'),
              const SizedBox(height: 10),
              _mapContainer(),
              const SizedBox(height: 12),
              _actionRow(),
              const SizedBox(height: 20),
              _sectionTitle('Recommendation'),
              const SizedBox(height: 10),
              _recommendationList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(currentIndex: 0),
    );
  }

  /* ────────── Widget Helpers ────────── */

  // 검색 바 위젯
  Widget _searchBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const TextField(
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            icon: Icon(Icons.search, color: Colors.white),
            hintText: '전시회를 검색하세요',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
        ),
      );

  // 섹션 제목 위젯
  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );

  // 지도 컨테이너 위젯 (InAppWebView 포함)
  Widget _mapContainer() => SizedBox(
        height: 150,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri("file:///android_asset/flutter_assets/assets/kakaomap.html"),
            ),
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                transparentBackground: true, // 웹뷰 배경 투명하게 설정
              ),
              android: AndroidInAppWebViewOptions(
                geolocationEnabled: true, // 안드로이드 웹뷰에서 위치 정보 사용 허용
                useHybridComposition: true, // 웹뷰 렌더링 성능 향상
              ),
            ),
            androidOnGeolocationPermissionsShowPrompt: (controller, origin) async {
              // 위치 권한 요청 시 항상 허용하도록 설정 (Flutter 앱에서 이미 권한을 처리했으므로)
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
              print('[WebView Console] ${consoleMessage.message}');
            },
            onLoadStop: (controller, url) async {
              print('[WebView] Page loaded: $url');
              // 페이지 로드 완료 후 Kakao Map API 키 주입 및 지도 초기화
              if (url.toString().contains('kakaomap.html')) {
                // 'injectKakaoMapKeyAndLoadMap' 함수를 호출하여 키를 전달하고 지도 로딩 시작
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
  Widget _actionRow() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCircleIcon(Icons.grid_view),
          _buildCircleIcon(Icons.palette_outlined),
          _buildCircleIcon(Icons.image_outlined),
          _buildCircleIcon(Icons.add_circle_outline),
        ],
      );

  // 추천 목록 위젯
  Widget _recommendationList() => Expanded(
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildRecommendationCard(
              title: "What's inside the pencil",
              description: 'Lorem ipsum dolor sit amet, consectetur...',
              backgroundColor: Colors.white,
            ),
            const SizedBox(width: 12),
            _buildRecommendationCard(
              title: 'The 2nd Chonnam Graduation Exhibition',
              description: 'Lorem ipsum dolor sit amet, consectetur...',
              backgroundColor: Colors.orange[100]!,
            ),
          ],
        ),
      );

  // 원형 아이콘 위젯
  Widget _buildCircleIcon(IconData icon) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      );

  // 추천 카드 위젯
  Widget _buildRecommendationCard({
    required String title,
    required String description,
    required Color backgroundColor,
  }) =>
      Container(
        width: 160,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}
