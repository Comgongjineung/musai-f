import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'bottom_nav_bar.dart';
import 'app_bar_widget.dart';
import 'secrets.dart'; // secrets.dart 파일에서 kakaoMapKey를 가져옵니다.
import 'dart:io';
import 'search_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'exhibition_detail_page.dart';
import 'login_UI.dart';

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
    appBar: const AppBarWidget(),
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 검색창
          Padding(
            padding: EdgeInsets.only(
              left: screenWidth * 0.06,
              right: screenWidth * 0.06,
              top: screenWidth * 0.05,
              bottom: screenWidth * 0.05, 
            ),
            child: _searchBar(screenWidth),
          ),

          // 섹션 제목 + 지도
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Nearby Exhibition', screenWidth),
                SizedBox(height: screenWidth * 0.02),
                _buildMapWrapper(screenWidth),
                SizedBox(height: screenWidth * 0.04),
                _actionRow(BoxConstraints(maxWidth: screenWidth)),
                SizedBox(height: screenWidth * 0.06),
                _sectionTitle('Recommendation', screenWidth),
              ],
            ),
          ),

          // 추천 카드만 스크롤 가능
          Expanded(
                          child: Padding(
                padding: EdgeInsets.only(
                  left: screenWidth * 0.06,
                  top: screenWidth * 0.02,
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
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        print('✅ 로그인 테스트 버튼 클릭됨');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SignupPage()),
        );
      },
      child: Icon(Icons.login),
      backgroundColor: Colors.blue,
      heroTag: 'loginTestBtn',
    ),
  );
}

Widget _buildMapWrapper(double screenWidth) {
  return SizedBox(
    height: screenWidth * 0.52, // 195px → 반응형
    child: _mapContainer(BoxConstraints(maxWidth: screenWidth), screenWidth),
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
              height: screenWidth * 0.12, // 44px → 반응형
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0ED),
        borderRadius: BorderRadius.circular(screenWidth * 0.05), // 20px → 반응형
      ),
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04), // 16px → 반응형
      child: Row(
        children: [
          Expanded(
            child: Text(
              '전시회를 검색하세요',
              style: TextStyle(
                color: const Color(0xFFB1B1B1),
                fontSize: screenWidth * 0.04, // 16px → 반응형
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          Icon(Icons.search, color: const Color(0xFFB1B1B1), size: screenWidth * 0.055), // 22px → 반응형
        ],
      ),
    ),
  );

  // 섹션 제목 위젯
  Widget _sectionTitle(String text, double screenWidth) => Text(
    text,
    style: TextStyle(
      color: const Color(0xFF706B66),
      fontSize: screenWidth * 0.05, // 20px → 반응형
      fontWeight: FontWeight.bold,
      fontFamily: 'Pretendard',
    ),
  );

  // 지도 컨테이너 위젯 (InAppWebView 포함)
  Widget _mapContainer(BoxConstraints constraints, double screenWidth) => SizedBox(
    height: constraints.maxWidth * 0.52, // 195px → 반응형
    child: ClipRRect(
      borderRadius: BorderRadius.circular(screenWidth * 0.05), // 20px → 반응형
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
          return SizedBox(width: constraints.maxWidth * 0.02); // 8px → 반응형
        } else {
          final index = i ~/ 2;
          final isPlus = index == 3;
          return Container(
            width: constraints.maxWidth * 0.18, // 69px → 반응형
            height: constraints.maxWidth * 0.11, // 43px → 반응형
            decoration: BoxDecoration(
              color: isPlus ? const Color(0xB2A28F7D) : const Color(0xFFA28F7D),
              borderRadius: BorderRadius.circular(constraints.maxWidth * 0.08), // 30px → 반응형
            ),
            child: Icon(icons[index], color: const Color(0xFFFEFDFC), size: constraints.maxWidth * 0.07), // 28px → 반응형
          );
        }
      }),
    );
  }

  // 추천 목록 위젯
  Widget _recommendationList(BoxConstraints constraints, double screenWidth) {
    return SizedBox(
      height: constraints.maxWidth * 0.61, // 237px → 반응형
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          RecommendationCard(
            title: "What's inside the pencil",
            description: '전시 장소\n전시 기간',
            backgroundColor: Colors.white,
            width: constraints.maxWidth * 0.62, // 240px → 반응형
            height: constraints.maxWidth * 0.61, // 237px → 반응형
            marginRight: constraints.maxWidth * 0.03, // 12px → 반응형
            image: null,
            screenWidth: constraints.maxWidth,
          ),
          RecommendationCard(
            title: 'The 2nd Chonnam Graduation Exhibition',
            description:
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
            backgroundColor: Colors.white,
            width: constraints.maxWidth * 0.62, // 240px → 반응형
            height: constraints.maxWidth * 0.61, // 237px → 반응형
            marginRight: constraints.maxWidth * 0.03, // 12px → 반응형
            image: null,
            screenWidth: constraints.maxWidth,
          ),
        ],
      ),
    );
  }

}

// RecommendationCard 위젯
class RecommendationCard extends StatelessWidget {
  final String title;
  final String description;
  final Color backgroundColor;
  final double width;
  final double height;
  final double marginRight;
  final Widget? image;
  final double screenWidth;

  const RecommendationCard({
    super.key,
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.width,
    required this.height,
    required this.marginRight,
    this.image,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final dummy = Exhibition(
  exhiId: 1,
  title: '이탈리아 국립 카포디몬테 컬렉션',
  startDate: '2025.07.08',
  endDate: '2025.08.08',
  place: '소마미술관',
  realmName: '', // realmName은 의미 없으므로 빈 값
  thumbnail: '', // 또는 썸네일 URL 입력
  seqnum: 1,
);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExhibitionDetailPage(exhibition: dummy),
          ),
        );
      },
      child: Container(
        width: width,
        height: height,
        margin: EdgeInsets.only(right: marginRight),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // 이미지 (없으면 기본 배경)
            Positioned.fill(
              child: image ??
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F0ED),
                    ),
                    child: Center(
                      child: Text(
                        '전시회 이미지',
                        style: TextStyle(
                          color: const Color(0xFFB1B1B1),
                          fontSize: screenWidth * 0.035, // 14px → 반응형
                        ),
                      ),
                    ),
                  ),
            ),
            // 하단 반투명 설명 박스 (카드 내부에 8px 여백)
            Positioned(
              left: screenWidth * 0.02, // 8px → 반응형
              right: screenWidth * 0.02, // 8px → 반응형
              bottom: screenWidth * 0.02, // 8px → 반응형
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04, // 16px → 반응형
                  vertical: screenWidth * 0.035, // 14px → 반응형
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF999999).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: const Color(0xFFFEFDFC),
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Pretendard',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      description,
                      style: TextStyle(
                        color: const Color(0xFF706B66),
                        fontSize: screenWidth * 0.03,
                        fontFamily: 'Pretendard',
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
}
