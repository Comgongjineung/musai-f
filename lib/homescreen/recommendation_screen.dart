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

  // 아이템 + 비율
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
        final items = (body['recommendations'] as List? ?? [])
            .map((e) => RecommendItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList();

        // ① 즉시 렌더용: 모두 정사각(1.0)으로 먼저 뿌림 → 첫 화면 빠르게 표시
        final initial = items.map((it) => MasonryEntry(item: it, aspectRatio: 1.0)).toList();
        if (!mounted) return;
        setState(() {
          _entries = initial;
          _loading = false;
          _error = null;
        });

        // ② 비율 비동기 보강: 각 항목별로 원본 사이즈 얻어와서 개별 업데이트 (점진적)
        for (int i = 0; i < items.length; i++) {
          _hydrateAspectRatio(i, items[i].primaryImageSmall);
        }
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

  /// 단일 항목의 aspectRatio를 비동기로 보강해서 즉시 반영
  Future<void> _hydrateAspectRatio(int index, String url) async {
    final size = await _getNetworkImageSize(url);
    if (!mounted) return;
    if (size == null || size.width <= 0 || size.height <= 0) return;

    final ratio = size.width / size.height;

    // 동일 비율이면 리빌드 불필요
    if (index < 0 || index >= _entries.length) return;
    if ((_entries[index].aspectRatio - ratio).abs() < 0.001) return;

    setState(() {
      final updated = [..._entries];
      updated[index] = MasonryEntry(item: updated[index].item, aspectRatio: ratio);
      _entries = updated;
    });
  }

  /// 네트워크 이미지의 원본 width/height를 얻음
  Future<Size?> _getNetworkImageSize(String url) async {
    final completer = Completer<Size?>();
    final img = Image.network(url);
    final ImageStream stream = img.image.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      ));
      stream.removeListener(listener);
    }, onError: (dynamic _, __) {
      completer.complete(null);
      stream.removeListener(listener);
    });

    stream.addListener(listener);
    return completer.future.timeout(const Duration(seconds: 3), onTimeout: () => null);
  }

  @override
  Widget build(BuildContext context) {
    // ----- 스케일 팩터 -----
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dpr = MediaQuery.of(context).devicePixelRatio;
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

                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final totalWidth = constraints.maxWidth;
                                  final columnWidth = (totalWidth - hGap) / 2;

                                  final left = <Widget>[];
                                  final right = <Widget>[];
                                  double leftHeight = 0;
                                  double rightHeight = 0;

                                  // 디바이스 해상도에 맞춘 다운샘플 폭(px)
                                  final targetCacheWidth = (columnWidth * dpr).round();

                                  for (final entry in _entries) {
                                    final tileHeight = columnWidth / (entry.aspectRatio <= 0 ? 1.0 : entry.aspectRatio);

                                    final tile = SizedBox(
                                      width: columnWidth,
                                      child: _PosterTile(
                                        entry: entry,
                                        borderRadius: sr(8),
                                        cacheWidthPx: targetCacheWidth, // ⬅ 다운샘플링 핵심
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
                                        Expanded(child: Column(children: left)),
                                        const SizedBox(width: hGap),
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
  final MasonryEntry entry;
  final VoidCallback onTap;
  final double borderRadius;
  final int cacheWidthPx; // 디바이스 해상도에 맞춘 디코드 폭

  const _PosterTile({
    required this.entry,
    required this.onTap,
    required this.borderRadius,
    required this.cacheWidthPx,
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
            AspectRatio(
              aspectRatio: entry.aspectRatio <= 0 ? 1.0 : entry.aspectRatio,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                // ↓ Flutter 3.10+ 에서 지원. 엔진이 다운샘플링 디코드해서 빨라짐.
                cacheWidth: cacheWidthPx,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const _PosterSkeleton();
                },
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFFE9E9E9),
                  child: _BrokenImageIcon(),
                ),
                filterQuality: FilterQuality.low, // 디코드/스케일 비용 절감
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

class MasonryEntry {
  final RecommendItem item;
  final double aspectRatio; // width / height
  const MasonryEntry({required this.item, required this.aspectRatio});
}
