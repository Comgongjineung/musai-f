import 'dart:async';
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

  // 기존: List<RecommendItem> _items
  // 변경: MasonryEntry(아이템, aspectRatio)까지 준비
  List<MasonryEntry> _entries = const [];

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
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final body = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final list = (body['recommendations'] as List? ?? [])
            .map((e) => RecommendItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList();

        // 1) 이미지 사이즈를 미리 구해 aspectRatio 세팅
        final prepared = await _prepareEntries(list);

        if (!mounted) return;
        setState(() {
          _entries = prepared;
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

  /// ImageProvider를 resolve해서 네트워크 이미지의 원본 width/height를 가져옴
  Future<Size?> _getNetworkImageSize(String url) async {
    final completer = Completer<Size?>();
    final img = Image.network(url);
    final ImageStream stream = img.image.resolve(const ImageConfiguration());
    void listener(ImageInfo info, bool syncCall) {
      final w = info.image.width.toDouble();
      final h = info.image.height.toDouble();
      completer.complete(Size(w, h));
      stream.removeListener(ImageStreamListener(listener));
    }

    stream.addListener(ImageStreamListener(
      listener,
      onError: (dynamic _, __) {
        completer.complete(null); // 실패 시 null
        stream.removeListener(ImageStreamListener(listener));
      },
    ));

    // 혹시나 5초 타임아웃
    return completer.future.timeout(const Duration(seconds: 5), onTimeout: () => null);
  }

  /// RecommendItem 리스트 → MasonryEntry 리스트(aspectRatio 포함)로 변환
  Future<List<MasonryEntry>> _prepareEntries(List<RecommendItem> items) async {
    final futures = items.map((it) async {
      final url = it.primaryImageSmall;
      final size = await _getNetworkImageSize(url);
      // aspectRatio = width / height, 실패 시 안전한 기본값(정사각) 1.0
      final ratio = (size != null && size.width > 0 && size.height > 0)
          ? (size.width / size.height)
          : 1.0;
      return MasonryEntry(item: it, aspectRatio: ratio);
    }).toList();

    return Future.wait(futures);
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
          backgroundColor: Color(0xFFFFFDFC),
          surfaceTintColor: Color(0xFFFAFAFA),
          elevation: 0,
          shadowColor: Colors.transparent,
          scrolledUnderElevation: 2,
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

                            // ===== 균형 분배 Masonry 레이아웃 (패키지 없이) =====
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final totalWidth = constraints.maxWidth;
                                  final columnWidth = (totalWidth - hGap) / 2;

                                  final left = <Widget>[];
                                  final right = <Widget>[];
                                  double leftHeight = 0;
                                  double rightHeight = 0;

                                  for (final entry in _entries) {
                                    // 예상 높이 = columnWidth / (width/height)
                                    final tileHeight = columnWidth / (entry.aspectRatio <= 0 ? 1.0 : entry.aspectRatio);
                                    final tile = SizedBox(
                                      width: columnWidth,
                                      child: _PosterTile(
                                        entry: entry,
                                        borderRadius: sr(8),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => DetailRecommendPage(item: entry.item),
                                            ),
                                          );
                                        },
                                      ),
                                    );

                                    final padded = Padding(
                                      padding: const EdgeInsets.only(bottom: vGap),
                                      child: tile,
                                    );

                                    // 항상 더 낮은 쪽으로 배치
                                    if (leftHeight <= rightHeight) {
                                      left.add(padded);
                                      leftHeight += tileHeight + vGap;
                                    } else {
                                      right.add(padded);
                                      rightHeight += tileHeight + vGap;
                                    }
                                  }

                                  return SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 왼쪽 열
                                        Expanded(child: Column(children: left)),
                                        const SizedBox(width: hGap),
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

/// 이미지 비율을 알고 있을 때 자리 흔들림을 막는 타일
class _PosterTile extends StatelessWidget {
  final MasonryEntry entry;
  final VoidCallback onTap;
  final double borderRadius;

  const _PosterTile({
    required this.entry,
    required this.onTap,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = entry.item.primaryImageSmall;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 자리를 먼저 확보해 스크롤 중 레이아웃 점프 방지
            AspectRatio(
              aspectRatio: entry.aspectRatio <= 0 ? 1.0 : entry.aspectRatio, // width/height
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const _PosterSkeleton(); // 동일 비율 박스 안에서 로딩
                },
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFFE9E9E9),
                  child: _BrokenImageIcon(),
                ),
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
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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

/// Masonry용 엔트리 (아이템 + 비율)
class MasonryEntry {
  final RecommendItem item;
  final double aspectRatio; // width / height
  const MasonryEntry({required this.item, required this.aspectRatio});
}
