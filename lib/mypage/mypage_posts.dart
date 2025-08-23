import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:musai_f/utils/auth_storage.dart';
import 'package:musai_f/community/community_detail_screen.dart';

const String BASE_URL = 'http://43.203.23.173:8080';

// ------------------ 색상 토큰 (디자인 톤) ------------------
const _cTextPrimary = Color(0xFF343231); // 닉네임, musai
const _cTextSecondary = Color(0xFF646363); // 내용
const _cTextHint = Color(0xFF9E9E9E); // 날짜
const _cBorder = Color(0xFFEFEFEF); // 카드 테두리
const _cInfoIcon = Color(0xFF837670); // info 아이콘

// ------------------ 모델 ------------------
class MyPost {
  final int postId;
  final int userId;
  final String title;
  final String content;
  final String? image1;
  final String? image2;
  final String? image3;
  final String? image4;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? likeCount;
  final int? commentCount;

  MyPost({
    required this.postId,
    required this.userId,
    required this.title,
    required this.content,
    this.image1,
    this.image2,
    this.image3,
    this.image4,
    required this.createdAt,
    required this.updatedAt,
    this.likeCount,
    this.commentCount,
  });

  factory MyPost.fromJson(Map<String, dynamic> j) => MyPost(
        postId: j['postId'] ?? 0,
        userId: j['userId'] ?? 0,
        title: (j['title'] ?? '').toString(),
        content: (j['content'] ?? '').toString(),
        image1: (j['image1'] as String?)?.toString(),
        image2: (j['image2'] as String?)?.toString(),
        image3: (j['image3'] as String?)?.toString(),
        image4: (j['image4'] as String?)?.toString(),
        createdAt: DateTime.parse(j['createdAt']),
        updatedAt: DateTime.parse(j['updatedAt']),
        likeCount: j['likeCount'] as int?,
        commentCount: j['commentCount'] as int?,
      );
}

class UserProfile {
  final int userId;
  final String email;
  final String nickname;
  final String? profileImage;

  UserProfile({
    required this.userId,
    required this.email,
    required this.nickname,
    this.profileImage,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        userId: j['userId'],
        email: (j['email'] ?? '').toString(),
        nickname: (j['nickname'] ?? '').toString(),
        profileImage: (j['profileImage'] as String?)?.toString(),
      );
}

// ------------------ 서비스 ------------------
class MyPostService {
  // 한글 깨짐 방지: body 대신 bodyBytes를 UTF-8로 디코딩
  static List<dynamic> _decodeUtf8List(http.Response res) {
    final decoded = utf8.decode(res.bodyBytes);
    return jsonDecode(decoded) as List<dynamic>;
  }

  static Map<String, dynamic> _decodeUtf8Map(http.Response res) {
    final decoded = utf8.decode(res.bodyBytes);
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  // 내가 쓴 게시글 조회
  static Future<List<MyPost>> fetchMyPosts({
    required String token,
    required int userId,
  }) async {
    final uri = Uri.parse('$BASE_URL/user/post/$userId');
    final res = await http.get(uri, headers: {
      'accept': '*/*',
      'Authorization': 'Bearer $token',
    });

    if (res.statusCode != 200) {
      throw Exception('(${res.statusCode}) ${res.reasonPhrase}');
    }

    final List<dynamic> data = _decodeUtf8List(res);
    return data.map((e) => MyPost.fromJson(e)).toList();
  }

  // 닉네임 표기용 내 프로필 조회
  static Future<UserProfile> fetchUserProfile({
    required String token,
    required int userId,
  }) async {
    final uri = Uri.parse('$BASE_URL/user/read/$userId');
    final res = await http.get(uri, headers: {
      'accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (res.statusCode != 200) {
      throw Exception('(${res.statusCode}) 사용자 정보 조회 실패');
    }

    final Map<String, dynamic> data = _decodeUtf8Map(res);
    return UserProfile.fromJson(data);
  }
}

// ------------------ 마이페이지 진입 타일 ------------------
class MyPostsEntryTile extends StatelessWidget {
  const MyPostsEntryTile({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MyPostsPage()),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cBorder),
        ),
        child: Row(
          children: const [
            Expanded(
              child: Text(
                '작성한 게시글',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _cTextPrimary),
              ),
            ),
            Icon(Icons.chevron_right, color: _cTextPrimary),
          ],
        ),
      ),
    );
  }
}

// ------------------ 내가 쓴 게시글 목록 화면 ------------------
class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  late Future<_LoadedData> _future;
  String? _token;

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
  }

  Future<_LoadedData> _loadAll() async {
    _token = await getJwtTokenCached();
    final userId = await getUserId();
    if (_token == null || userId == null) {
      throw Exception('로그인이 필요합니다. (token/userId null)');
    }

    // 내 프로필(닉네임) + 내가 쓴 글 목록 병렬 로딩
    final results = await Future.wait([
      MyPostService.fetchUserProfile(token: _token!, userId: userId),
      MyPostService.fetchMyPosts(token: _token!, userId: userId),
    ]);

    final profile = results[0] as UserProfile;
    final posts = results[1] as List<MyPost>;
    return _LoadedData(nickname: profile.nickname, posts: posts);
  }

  String _fmt(DateTime dt) => DateFormat('yy.MM.dd HH:mm').format(dt);

  @override
  Widget build(BuildContext context) {
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 기준 해상도 비율(390x844)
    const w = 390.0;
    const h = 844.0;

    // 요구 간격을 비율로 계산
    final top40  = screenHeight * (40 / h);   // musai / back 버튼 상단 40
    final left24 = screenWidth  * (24 / w);   // 좌우 24
    final gap20  = screenHeight * (20 / h);   // musai 아래 첫 카드까지 20
    final gap8   = screenHeight * (8  / h);   // 카드 간 8
    final bot10  = screenHeight * (10 / h);   // 하단 10

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        toolbarHeight: kToolbarHeight + top40,
        leading: Padding(
          padding: EdgeInsets.only(left: left24, top: top40),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 25, color: _cTextPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Padding(
          padding: EdgeInsets.only(top: top40),
          child: const Text(
            'musai',
            style: TextStyle(
              color: _cTextPrimary, // #343231
              fontWeight: FontWeight.w600,
              fontSize: 32, // 요청 반영
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<_LoadedData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('불러오기에 실패했습니다.', style: TextStyle(color: _cTextPrimary)),
                      const SizedBox(height: 6),
                      Text('${snap.error}', textAlign: TextAlign.center, style: const TextStyle(color: _cTextSecondary)),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => setState(() => _future = _loadAll()),
                        child: const Text('다시 시도', style: TextStyle(color: _cTextPrimary)),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snap.data!;
            final items = data.posts;
            final myNickname = data.nickname;

            if (items.isEmpty) {
              return const Center(
                child: Text('작성한 게시글이 없습니다.', style: TextStyle(color: _cTextPrimary)),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.only(
                left: left24,
                right: left24,
                top: gap20,
                bottom: bot10,
              ),
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: gap8),
              itemBuilder: (context, i) {
                final p = items[i];

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommunityDetailScreen(postId: p.postId),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _cBorder), // #EFEFEF
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 12,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 상단: (작성자) 내 닉네임 + 날짜 + info
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                myNickname.isEmpty ? '나' : myNickname,
                                style: const TextStyle(
                                  color: _cTextPrimary, // #343231
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _fmt(p.createdAt),
                              style: const TextStyle(fontSize: 12, color: _cTextHint), // #9E9E9E
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.info_outline, size: 15, color: _cInfoIcon), // #837670
                          ],
                        ),
                        const SizedBox(height: 6),

                        // 본문: 내용 우선, 없으면 제목
                        Text(
                          (p.content.isEmpty ? p.title : p.content),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, color: _cTextSecondary), // #646363
                        ),
                        const SizedBox(height: 8),
                        // 썸네일(최대 4장)
                        _PostThumbRow(images: [p.image1, p.image2, p.image3, p.image4]),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LoadedData {
  final String nickname;
  final List<MyPost> posts;
  _LoadedData({required this.nickname, required this.posts});
}

// ------------------ 이미지 썸네일 ------------------
class _PostThumbRow extends StatelessWidget {
  final List<String?> images;
  const _PostThumbRow({required this.images});

  bool _isValid(String? s) {
    if (s == null) return false;
    final v = s.trim().toLowerCase();
    if (v.isEmpty || v == 'string' || v == 'null') return false;
    return v.startsWith('http://') || v.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final valid = images.where(_isValid).cast<String>().toList();
    if (valid.isEmpty) return const SizedBox.shrink();

    final width = (MediaQuery.of(context).size.width - 24 - 24 - 8 * 3) / 4; // 좌우 24 반영
    return SizedBox(
      height: width,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: valid.length.clamp(0, 4),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final url = valid[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF3F3F3),
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, color: _cTextHint),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
