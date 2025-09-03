import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../bottom_nav_bar.dart';
import '../app_bar_widget.dart';
import '../secrets.dart'; // secrets.dart 파일에서 kakaoMapKey를 가져옵니다.
import 'dart:io';
import 'search_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'exhibition_detail_page.dart';
import '../alarm_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/auth_storage.dart';
import 'recommendation_screen.dart';
import 'recommendation_detail_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  InAppWebViewController? webViewController;
  List<Exhibition> _nearest = [];
  bool _loadingNearest = true;
  String? _nearestError;
  List<dynamic> _reco = [];
  bool _loadingReco = true;
  String? _recoError;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission(); // 앱 시작 시 위치 권한 요청 및 GPS 활성화 확인
    _initLocationAndFetch();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _loadingReco = true;
      _recoError = null;
    });

    try {
      final userId = await getUserId();        // auth_storage.dart
      final token  = await getJwtToken();      // auth_storage.dart

      if (userId == null || token == null || token.isEmpty) {
        setState(() {
          _recoError = '로그인이 필요합니다.';
          _loadingReco = false;
        });
        return;
      }

      final uri = Uri.parse(
        'http://43.203.23.173:8080/recommend/dummyData/$userId?count=5',
      );

      final res = await http.get(
        uri,
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final decoded = utf8.decode(res.bodyBytes);
        final data = jsonDecode(decoded) as Map<String, dynamic>;
        final list = (data['recommendations'] as List?) ?? [];

        setState(() {
          _reco = list;
          _loadingReco = false;
        });
      } else {
        setState(() {
          _recoError = '서버 오류: ${res.statusCode}';
          _loadingReco = false;
        });
      }
    } catch (e) {
      setState(() {
        _recoError = '네트워크 오류: $e';
        _loadingReco = false;
      });
    }
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

  Future<void> _initLocationAndFetch() async {
  // 권한/서비스 체크는 기존 다이얼로그 로직 그대로 사용
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    if (mounted) {
      setState(() {
        _nearestError = '설정에서 위치 권한을 허용해주세요.';
        _loadingNearest = false; // 무한로딩 방지
      });
    }
    _showPermissionDeniedDialog();
    return;
  }
  
   // 위치 서비스 꺼짐
  if (await Geolocator.isLocationServiceEnabled() == false) {
    if (mounted) {
      setState(() {
        _nearestError = '기기의 위치 서비스가 꺼져 있어요.';
        _loadingNearest = false; // 무한로딩 방지
      });
    }
    _showLocationServiceDisabledDialog();
    return;
  }

  try {
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    await _fetchNearest(pos.latitude, pos.longitude);
  } catch (e) {
    setState(() {
      _nearestError = '위치 조회 실패: $e';
      _loadingNearest = false;
    });
  }
}

Future<void> _fetchNearest(double lat, double lng) async {
  setState(() {
    _loadingNearest = true;
    _nearestError = null;
  });
  final token = await getJwtToken();
  if (token == null || token.isEmpty) {
    if (mounted) {
      setState(() {
        _nearestError = '로그인이 필요합니다.';
        _loadingNearest = false; // 무한로딩 방지
      });
    }
    return;
  }

  final uri = Uri.parse(
    'http://43.203.23.173:8080/exhibition/nearest?latitude=$lat&longitude=$lng',
  );

  try {
    final res = await http
        .get(
          uri,
          headers: {
            'accept': '*/*',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15)); // 타임아웃
    if (res.statusCode == 200) {
      final decoded = utf8.decode(res.bodyBytes);
      final List data = jsonDecode(decoded);

      final list = data.map((e) => Exhibition.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _nearest = list.take(3).toList(); // 3개만
        _loadingNearest = false;
      });
    } else {
      setState(() {
        _nearestError = '서버 오류: ${res.statusCode}';
        _loadingNearest = false;
      });
    }
  } catch (e) {
    setState(() {
      _nearestError = '네트워크 오류: $e';
      _loadingNearest = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFC),
      appBar: const AppBarWidget(
        showNotificationIcon: true,
        showBackButton: false,
      ),
      body: SafeArea(
        child: _buildBody(screenWidth, screenHeight),
      ),
      bottomNavigationBar: const BottomNavBarWidget(currentIndex: 0),
    );
  }

  /// 메인 바디 구성 (함수형 분리)
  Widget _buildBody(double screenWidth, double screenHeight) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _searchSection(screenWidth),
          _nearbyMapSection(screenWidth),
          _scrollableSections(screenWidth, screenHeight),
        ],
      ),
    );
  }

  /// 검색창 섹션
  Widget _searchSection(double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(
        left: screenWidth * 0.06,
        right: screenWidth * 0.06,
        top: screenWidth * 0.05,
        bottom: screenWidth * 0.05,
      ),
      child: _searchBar(screenWidth),
    );
  }

  /// 근처 전시 지도 섹션 (타이틀 + 지도)
  Widget _nearbyMapSection(double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Nearby Exhibition', screenWidth),
          SizedBox(height: screenWidth * 0.02),
          _buildMapWrapper(screenWidth),
          SizedBox(height: screenWidth * 0.04),
        ],
      ),
    );
  }

  /// 스크롤 가능한 섹션 묶음 (주변 전시 리스트 + 추천)
  Widget _scrollableSections(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06)
          .copyWith(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _nearestListArea(screenWidth, screenHeight),
          SizedBox(height: screenWidth * 0.06),
          _sectionTitle('Recommendation', screenWidth),
          SizedBox(height: screenWidth * 0.02),
          _recommendationList(BoxConstraints(maxWidth: screenWidth), screenWidth),
        ],
      ),
    );
  }

  /// 주변 전시 3개 리스트 표시 영역
  Widget _nearestListArea(double screenWidth, double screenHeight) {
    if (_loadingNearest) {
      return Padding(
        padding: EdgeInsets.only(top: screenWidth * 0.02),
        child: const Center(child: CircularProgressIndicator()),
      );
    } else if (_nearestError != null) {
      return Padding(
        padding: EdgeInsets.only(top: screenWidth * 0.02),
        child: Text(_nearestError!, style: const TextStyle(color: Colors.redAccent)),
      );
    } else {
      return _NearestListCard(
        items: _nearest.take(3).toList(),
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        onTap: (e) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ExhibitionDetailPage(exhibition: e)),
          );
        },
      );
    }
  }

Widget _buildMapWrapper(double screenWidth) {
  return SizedBox(
    height: screenWidth * 0.5,
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
              height: screenWidth * 0.12, 
      decoration: BoxDecoration(
        color: const Color(0xFFFEF6F2),
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
      ),
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04), 
      child: Row(
        children: [
          Expanded(
            child: Text(
              '전시회를 검색하세요',
              style: TextStyle(
                color: const Color(0xFFB1B1B1),
                fontSize: screenWidth * 0.04, 
              ),
            ),
          ),
          Icon(Icons.search, color: const Color(0xFFB1B1B1), size: screenWidth * 0.055), 
        ],
      ),
    ),
  );

  // 섹션 제목 위젯
  Widget _sectionTitle(String text, double screenWidth) => Text(
    text,
    style: TextStyle(
      color: const Color(0xFF706B66),
      fontSize: screenWidth * 0.05, 
      fontWeight: FontWeight.bold,

    ),
  );

  // 지도 컨테이너 위젯 (InAppWebView 포함)
  Widget _mapContainer(BoxConstraints constraints, double screenWidth) => SizedBox(
    height: screenWidth * 0.6,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(screenWidth * 0.05), 
      child: Stack(
        children: [
          GestureDetector(
            onVerticalDragUpdate: (details) {
              // 지도 영역에서 세로 스크롤 차단
            },
                        onHorizontalDragUpdate: (details) {
              // 지도 영역에서 가로 스크롤 차단
            },
            child: InAppWebView(
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
          ),
        ],
      ),
    ),
  );

    // 추천 목록 위젯 (API 연동 버전)
  Widget _recommendationList(BoxConstraints constraints, double screenWidth) {
    final cardWidth     = constraints.maxWidth * 0.62;   // 기존 설계 유지
    final cardHeight    = constraints.maxWidth * 0.61;   // 기존 설계 유지
    final cardSpacing   = constraints.maxWidth * 0.03;   // 기존 설계 유지

    if (_loadingReco) {
      return SizedBox(
        height: cardHeight,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_recoError != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(_recoError!, style: const TextStyle(color: Colors.redAccent)),
      );
    }
    if (_reco.isEmpty) {
      return SizedBox(
        height: cardHeight,
        child: const Center(child: Text('추천 결과가 없습니다.')),
      );
    }

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _reco.length + 1, // +1 for the add button
        separatorBuilder: (_, __) => SizedBox(width: cardSpacing),
        itemBuilder: (context, index) {
          // 마지막 아이템은 + 버튼
          if (index == _reco.length) {
            return _AddRecommendationButton(
              width: cardWidth,
              height: cardHeight,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecommendationScreen(),
                  ),
                );
              },
            );
          }

          final item = _reco[index] as Map<String, dynamic>;

          final title          = (item['title'] as String?) ?? 'Untitled';
          final name           = (item['name'] as String?) ?? '';
          final style          = (item['style'] as String?) ?? '';
          final objectEndDate  = item['objectEndDate']; // int? (음수 가능)
          final thumbUrl       = (item['primaryImageSmall'] as String?) ?? '';

          return RecommendationCard(
            title: title,
            name: name,
            objectEndDate: (objectEndDate is int) ? objectEndDate : null,
            style: style,
            width: cardWidth,
            height: cardHeight,
            marginRight: 0,                 // ListView.separated로 간격 처리
            screenWidth: constraints.maxWidth,
            image: thumbUrl.isEmpty
                ? null
                : Image.network(
                    thumbUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Color(0xFFF4F0ED)),
                  ),
            onTap: () {
              // 작품 상세페이지로 이동
              final recommendItem = RecommendItem(
                primaryImageSmall: thumbUrl,
                name: name,
                department: '',
                title: title,
                culture: '',
                period: '',
                objectDate: '',
                objectBeginDate: null,
                objectEndDate: objectEndDate is int ? objectEndDate : null,
                objectID: null,
                classification: '',
                style: style,
                objectName: '',
              );
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailRecommendPage(item: recommendItem),
                ),
              );
            },
          );
        },
      ),
    );
  }


}

// RecommendationCard 위젯
class RecommendationCard extends StatelessWidget {
  // ====== 데이터 필드 ======
  final String title;         // 작품 제목
  final String name;          // 작가 이름
  final int? objectEndDate;   // 제작시기
  final String? style;        // 예술사조
  final Widget? image;        // 썸네일

  // ====== 레이아웃/표현 필드 ======
  final double width;
  final double height;
  final double marginRight;
  final double screenWidth;
  final VoidCallback? onTap;  // 탭 콜백 추가

  const RecommendationCard({
    super.key,
    required this.title,
    required this.name,
    required this.objectEndDate,
    required this.style,
    required this.width,
    required this.height,
    required this.marginRight,
    this.image,
    required this.screenWidth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RecommendationScreen(), // 추천 페이지로 이동
          ),
        );
      },
      child: Container(
        width: width,
        height: height,
        margin: EdgeInsets.only(right: marginRight),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFDFC),
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
            // 썸네일 이미지
            Positioned.fill(
              child: image ??
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F0ED),
                    ),
                  ),
            ),
            // 전체를 덮는 Linear Gradient 오버레이
            Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFB1B1B1), 
                        Color(0xFF444444), 
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // 좌측 하단 제목
            Positioned(
              left: 20,
              bottom: 20,
              right: 20,
              child: Text(
                decodeHtml(title),
                style: const TextStyle(
                  color: Color(0xFFFEFDFC),
                  fontSize: 16, 
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddRecommendationButton extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback onTap;

  const _AddRecommendationButton({
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFB1B1B1), // 회색 박스
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            color: Color(0xFFFEFDFC), // + 색상
            size: 56,
          ),
        ),
      ),
    );
  }
}

class _NearestListCard extends StatelessWidget {
  final List<Exhibition> items;
  final double screenWidth;
  final double screenHeight;
  final void Function(Exhibition e) onTap;

  const _NearestListCard({
    required this.items,
    required this.screenWidth,
    required this.screenHeight,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sw = screenWidth;

    return Container(
      // 높이 고정 제거 (내용만큼 자동)
      decoration: BoxDecoration(
        color: Color(0xFFFEFDFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Column(
  children: List.generate(items.length, (idx) {
    final e = items[idx];
    return InkWell(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(idx == 0 ? sw * 0.04 : 0),
        topRight: Radius.circular(idx == 0 ? sw * 0.04 : 0),
        bottomLeft: Radius.circular(idx == items.length - 1 ? sw * 0.04 : 0),
        bottomRight: Radius.circular(idx == items.length - 1 ? sw * 0.04 : 0),
      ),
      onTap: () => onTap(e),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: idx == 0 ? screenHeight * (16 / 844) : 10,
          bottom: idx == items.length - 1 ? screenHeight * (16 / 844) : 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: sw * 0.06,
              child: Text(
                '${idx + 1}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: sw * 0.04,
                  color: const Color(0xFF706B66),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    decodeHtml(e.title).replaceAll('<to be continued>', ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: sw * 0.04,
                      color: const Color(0xFF343231),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: Color(0xFFB1B1B1)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          decodeHtml(e.place),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: sw * 0.03,
                            color: const Color(0xFFB1B1B1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: sw * 0.07, color: const Color(0xFFB1B1B1)),
          ],
        ),
      ),
    );
  }),
),
    );
  }
}

String decodeHtml(String s) {
  var out = s
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ');

  // 숫자 엔티티 처리: &#NNNN; 형태
  out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final code = int.tryParse(m.group(1) ?? '');
    if (code == null) return m.group(0)!;
    return String.fromCharCode(code);
  });

  // 16진수 엔티티 &#xHHHH;
  out = out.replaceAllMapped(RegExp(r'&#x([0-9A-Fa-f]+);'), (m) {
    final code = int.tryParse(m.group(1)!, radix: 16);
    if (code == null) return m.group(0)!;
    return String.fromCharCode(code);
  });

    // 특정 꼬리 문자열 제거
  out = out.replaceAll('<to be continued>', '');

  return out;
}
