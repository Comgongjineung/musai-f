import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'bottom_nav_bar.dart';

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
    _requestLocationPermission(); // 위치 권한 요청
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      openAppSettings(); // 사용자에게 권한 허용을 유도
      return;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }
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
                    fontFamily: 'Pretendard',
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

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );

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
              ),
              android: AndroidInAppWebViewOptions(
                geolocationEnabled: true,
              ),
            ),
            androidOnGeolocationPermissionsShowPrompt: (controller, origin) async {
              return GeolocationPermissionShowPromptResponse(
                origin: origin,
                allow: true,
                retain: true,
              );
            },
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
          ),
        ),
      );

  Widget _actionRow() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCircleIcon(Icons.grid_view),
          _buildCircleIcon(Icons.palette_outlined),
          _buildCircleIcon(Icons.image_outlined),
          _buildCircleIcon(Icons.add_circle_outline),
        ],
      );

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

  Widget _buildCircleIcon(IconData icon) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      );

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
