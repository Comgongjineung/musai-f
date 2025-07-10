import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'bottom_nav_bar.dart';
import 'secrets.dart'; // secrets.dart 파일에서 kakaoMapKey를 가져옵니다.
import 'dart:io';
import 'search_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
          title: const Text(
            '위치 권한 필요',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            '이 앱은 현재 위치를 표시하기 위해 위치 권한이 필요합니다. 설정에서 위치 권한을 허용해주세요.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('나중에', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                '설정으로 이동',
                style: TextStyle(color: Colors.blueAccent),
              ),
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
          title: const Text(
            '위치 서비스 비활성화됨',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('현재 위치를 가져오기 위해 기기의 위치 서비스를 활성화해야 합니다.'),
          actions: <Widget>[
            TextButton(
              child: const Text('확인', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                '설정 열기',
                style: TextStyle(color: Colors.blueAccent),
              ),
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
    backgroundColor: const Color(0xFFFFFDFC),
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 로고
          Padding(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.04,
              16,
              screenWidth * 0.04,
              0,
            ),
            child: Center(
              child: Text(
                'musai',
                style: TextStyle(
                  color: const Color(0xFF343231),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          // 검색창
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenWidth * 0.04,
            ),
            child: _searchBar(screenWidth),
          ),

          // 섹션 제목 + 지도
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Nearby Exhibition', screenWidth),
                SizedBox(height: screenWidth * 0.018),
                _buildMapWrapper(screenWidth),
                SizedBox(height: screenWidth * 0.035),
                _actionRow(BoxConstraints(maxWidth: screenWidth)),
                SizedBox(height: screenWidth * 0.05),
                _sectionTitle('Recommendation', screenWidth),
              ],
            ),
          ),

          // 추천 카드만 스크롤 가능
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: screenWidth * 0.04,
                top: screenWidth * 0.018,
              ),
              child: _recommendationList(
                BoxConstraints(maxWidth: screenWidth),
                screenWidth,
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: const BottomNavBarWidget(currentIndex: 0),
  );
}

Widget _buildMapWrapper(double screenWidth) {
  return SizedBox(
    height: 195,
    child: _mapContainer(BoxConstraints(maxWidth: screenWidth)),
  );
}

  // 검색 바 위젯
  Widget _searchBar(double screenWidth) => GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SearchScreen()),
      );
    },
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0ED),
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '전시회를 검색하세요',
              style: TextStyle(
                color: const Color(0xFFB1B1B1),
                fontSize: 15,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          Icon(Icons.search, color: const Color(0xFFB1B1B1), size: 22),
        ],
      ),
    ),
  );

  // 섹션 제목 위젯
  Widget _sectionTitle(String text, double screenWidth) => Padding(
    padding: const EdgeInsets.only(left: 2.0),
    child: Text(
      text,
      style: TextStyle(
        color: const Color(0xFF837670),
        fontSize: 17,
        fontWeight: FontWeight.bold,
        fontFamily: 'Pretendard',
      ),
    ),
  );

  // 지도 컨테이너 위젯 (InAppWebView 포함)
  Widget _mapContainer(BoxConstraints constraints) => SizedBox(
    height: 195,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          InAppWebView(
            initialUrlRequest:
                Platform.isAndroid
                    ? URLRequest(
                      url: WebUri(
                        "file:///android_asset/flutter_assets/assets/kakaomap.html",
                      ),
                    )
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

              controller.addJavaScriptHandler(
                handlerName: 'openLink',
                callback: (args) async {
                  final url = args.first;
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(
                      Uri.parse(url),
                      mode:
                          LaunchMode
                              .externalApplication, // Chrome, Naver 등 외부 앱 선택
                    );
                  } else {
                    print('Could not launch $url');
                  }
                },
              );
            },

            onConsoleMessage: (controller, consoleMessage) {
              print('[WebView Console] ${consoleMessage.message}');
            },
            onLoadStop: (controller, url) async {
              print('[WebView] Page loaded: $url');
              if (url.toString().contains('kakaomap.html')) {
                await controller.evaluateJavascript(
                  source: 'injectKakaoMapKeyAndLoadMap("$kakaoMapKey");',
                );
                print(
                  '[WebView] Injected Kakao Map Key and called load function.',
                );
              }
            },
            onLoadError: (controller, url, code, message) {
              print(
                '[WebView] Load Error: $url, Code: $code, Message: $message',
              );
            },
            onReceivedHttpError: (controller, request, response) {
              print(
                '[WebView] HTTP Error: ${response.statusCode}, URL: ${request.url}',
              );
            },
          ),
        ],
      ),
    ),
  );

  // 액션 버튼 행 위젯
  Widget _actionRow(BoxConstraints constraints) {
    final icons = [
      Icons.grid_view,
      Icons.palette_outlined,
      Icons.image_outlined,
      Icons.add,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(icons.length * 2 - 1, (i) {
        if (i.isOdd) {
          // 간격 삽입
          return const SizedBox(width: 8);
        } else {
          final index = i ~/ 2;
          final isPlus = index == 3;
          return Container(
            width: 69,
            height: 43,
            decoration: BoxDecoration(
              color: isPlus ? const Color(0xB2A28F7D) : const Color(0xFFA28F7D),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icons[index], color: const Color(0xFFFEFDFC), size: 28),
          );
        }
      }),
    );
  }

  // 추천 목록 위젯
  Widget _recommendationList(BoxConstraints constraints, double screenWidth) {
    return SizedBox(
      height: 237, // 카드 높이에 맞춤
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildRecommendationCard(
            title: "What's inside the pencil",
            description: '전시 장소\n전시 기간',
            backgroundColor: Colors.white,
            width: 240, // 카드 가로
            height: 237, // 카드 세로
            marginRight: 12,
            image: null,
          ),
          _buildRecommendationCard(
            title: 'The 2nd Chonnam Graduation Exhibition',
            description:
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
            backgroundColor: Colors.white,
            width: 240,
            height: 237,
            marginRight: 12,
            image: null,
          ),
        ],
      ),
    );
  }

  // 추천 카드 위젯
  Widget _buildRecommendationCard({
    required String title,
    required String description,
    required Color backgroundColor,
    required double width,
    required double height,
    required double marginRight,
    Widget? image,
  }) => Container(
    width: width,
    height: height,
    margin: EdgeInsets.only(right: marginRight),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 100,
          child:
              image ??
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F0ED),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 48, color: Color(0xFFB1B1B1)),
                ),
              ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black,
                  fontFamily: 'Pretendard',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF837670),
                  fontFamily: 'Pretendard',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
