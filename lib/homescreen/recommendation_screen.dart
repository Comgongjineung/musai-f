import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:musai_f/utils/auth_storage.dart';
import '../app_bar_widget.dart';
import 'recommendation_detail_page.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  static const _baseUrl = 'http://43.203.23.173:8080';
  bool _loading = true;
  String? _error;
  List<RecommendItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final userId = await getUserId();
      final token = await getJwtToken();

      if (userId == null || token == null || token.isEmpty) {
        setState(() {
          _error = '로그인 정보가 없습니다.';
          _loading = false;
        });
        return;
      }

      final uri = Uri.parse('$_baseUrl/recommend/dummyData/$userId?count=20');
      final res =
          await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final body =
            json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final list = (body['recommendations'] as List? ?? [])
            .map((e) => RecommendItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList();

        setState(() {
          _items = list;
          _loading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = '서버 오류: ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '불러오기 실패: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ----- 스케일 팩터 -----
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final sx = screenWidth / 390.0; // 기준 가로 390
    final sy = screenHeight / 841.0; // 기준 세로 841
    double sr(double v) => v * ((sx + sy) / 2);

    const double hGap = 12; // 열 간격
    const double vGap = 20; // 카드 세로 간격

    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          scrolledUnderElevation: 0,
          foregroundColor: Colors.black,
        ),
      ),
      child: Scaffold(
        appBar: const AppBarWidget(showBackButton: true),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _loadRecommendations)
                  : RefreshIndicator(
                      onRefresh: _loadRecommendations,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20 * sx),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 15 * sy),

                            // ===== Masonry 레이아웃 (패키지 없이) =====
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // 총 가용 폭(패딩 제외)에서 열 간격(hGap) 1번 빼고 반으로 나눔
                                  final totalWidth = constraints.maxWidth;
                                  final columnWidth = (totalWidth - hGap) / 2;

                                  // 간단히 짝수/홀수로 분배 (시각적 워터폴 효과 충분)
                                  final left = <Widget>[];
                                  final right = <Widget>[];

                                  for (int i = 0; i < _items.length; i++) {
                                    final tile = SizedBox(
                                      width: columnWidth,
                                      child: _PosterTile(
                                        item: _items[i],
                                        borderRadius: sr(8),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => DetailRecommendPage(item: _items[i]),
                                            ),
                                          );
                                        },
                                      ),
                                    );

                                    final padded = Padding(
                                      padding: EdgeInsets.only(bottom: vGap),
                                      child: tile,
                                    );

                                    if (i.isEven) {
                                      left.add(padded);
                                    } else {
                                      right.add(padded);
                                    }
                                  }

                                  return SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 왼쪽 열
                                        Expanded(child: Column(children: left)),
                                        SizedBox(width: hGap),
                                        // 오른쪽 열
                                        Expanded(child: Column(children: right)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}

class _PosterTile extends StatelessWidget {
  final RecommendItem item;
  final VoidCallback onTap;
  final double borderRadius;

  const _PosterTile({
    required this.item,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.primaryImageSmall;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이미지: 가로 폭에 맞추고 세로는 원본 비율
            Image.network(
              imageUrl,
              fit: BoxFit.fitWidth,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const _PosterSkeleton();
              },
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFFE9E9E9),
                child: _BrokenImageIcon(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterSkeleton extends StatelessWidget {
  const _PosterSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF3F3F3),
      child: AspectRatio(
        aspectRatio: 1, // 로딩 동안만 임시 정사각
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}

class _BrokenImageIcon extends StatelessWidget {
  const _BrokenImageIcon();

  @override
  Widget build(BuildContext context) {
    return const AspectRatio(
      aspectRatio: 1,
      child: Center(
        child: Icon(Icons.broken_image_outlined, size: 28, color: Colors.black38),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final sx = w / 390.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(16 * sx),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: 12 * sx),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
