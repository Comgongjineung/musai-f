import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // for MediaType
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io'; // File 클래스 사용을 위해 추가
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; // 이미지 압축용
import '../utils/auth_storage.dart';

class CommunityWriteScreen extends StatefulWidget {
  final int? postId; // 수정 모드일 때 사용
  final String? initialTitle; // 수정 모드일 때 사용
  final String? initialContent; // 수정 모드일 때 사용
  
  const CommunityWriteScreen({
    super.key, 
    this.postId, 
    this.initialTitle, 
    this.initialContent,
  });

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool isLoading = false;
  String? token;
  int? userId;

  // 이미지 상태
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = []; // 최대 4장

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadAuthInfo();
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }
  }

  Future<void> _loadAuthInfo() async {
    token = await getJwtToken();
    userId = await getUserId();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ---------- 이미지 선택/삭제/압축/인코딩 ----------

  Future<void> _pickImages() async {
    try {
      // 남은 슬롯만큼만 선택 가능하게
      final remain = 4 - _images.length;
      if (remain <= 0) return;

      // 멀티 픽(가능 플랫폼에서) + 단일 보조
      // 우선 멀티 시도
      List<XFile> picked = [];
      try {
        final multi = await _picker.pickMultiImage(
          imageQuality: 100, // 원본 유지(압축은 우리가 따로 처리)
        );
      if (multi.isNotEmpty) {
        picked = multi.take(remain).toList();
      }
      } catch (_) {
        // 일부 기기에서 pickMultiImage 미지원: 아래에서 단일로 보조
      }

      // 멀티가 비거나 지원 안되면 단일 선택으로 보조
      if (picked.isEmpty) {
        final one = await _picker.pickImage(source: ImageSource.gallery);
        if (one != null) picked = [one];
      }

      if (picked.isEmpty) return;

      setState(() {
        _images.addAll(picked.take(remain));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  /// 바이트 기준 강력 압축(최대 1280px로 리사이즈 + 품질 70, 100KB 근사 목표)
  Future<Uint8List> _compressBytes(Uint8List bytes) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;

      // 긴 변이 1280px를 넘으면 축소 (더 작게)
      const maxSide = 1280;
      final width = decoded.width;
      final height = decoded.height;
      img.Image toEncode = decoded;
      if (width > maxSide || height > maxSide) {
        final resized = img.copyResize(
          decoded,
          width: width > height ? maxSide : (width * maxSide / height).round(),
          height: height >= width ? maxSide : (height * maxSide / width).round(),
          interpolation: img.Interpolation.average,
        );
        toEncode = resized;
      }
      
      // 만약 여전히 너무 크다면 800px로 더 축소
      if (toEncode.width > 800 || toEncode.height > 800) {
        final smallerResized = img.copyResize(
          toEncode,
          width: toEncode.width > toEncode.height ? 800 : (toEncode.width * 800 / toEncode.height).round(),
          height: toEncode.height >= toEncode.width ? 800 : (toEncode.height * 800 / toEncode.width).round(),
          interpolation: img.Interpolation.average,
        );
        toEncode = smallerResized;
        print('🔍 추가 축소: ${toEncode.width}x${toEncode.height}');
      }

      // 1차 인코딩 (품질 70으로 시작)
      Uint8List out = Uint8List.fromList(img.encodeJpg(toEncode, quality: 70));

      // 100KB 근사까지 품질 낮춰가며 재시도 (하드루프 방지 5회)
      int quality = 65;
      int attempts = 0;
      while (out.lengthInBytes > 100 * 1024 && attempts < 5 && quality >= 40) {
        out = Uint8List.fromList(img.encodeJpg(toEncode, quality: quality));
        quality -= 5;
        attempts += 1;
      }
      
      // 최종 크기 체크 및 경고
      if (out.lengthInBytes > 100 * 1024) {
        print('⚠️ 경고: 이미지가 여전히 100KB를 초과합니다 (${(out.lengthInBytes / 1024).toStringAsFixed(1)}KB)');
      }
      
      print('🔍 압축 결과: ${out.lengthInBytes} bytes (품질: ${quality + 5})');
      return out;
    } catch (_) {
      // 실패 시 원본 반환
      return bytes;
    }
  }


  /// 이미지 1개를 서버에 업로드하고 URL을 반환 (성공 시)
  Future<String?> _uploadImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final compBytes = await _compressBytes(bytes);

      final uri = Uri.parse('http://43.203.23.173:8080/post/image');
      final request = http.MultipartRequest('POST', uri);
      final authToken = (token ?? '').trim();
      if (authToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      request.headers['accept'] = 'application/json';

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        compBytes,
        filename: 'upload.jpg', // 서버가 이미지 확장자/타입을 검사하므로 고정 JPG로 전송
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['imageUrl'] != null) {
          print('🔍 업로드된 이미지 URL: ${data['imageUrl']}');
          return data['imageUrl'] as String;
        } else {
          print('❗ 이미지 업로드 실패 (서버 응답: $data)');
          return null;
        }
      } else {
        print('❗ 이미지 업로드 실패 (상태 코드: ${response.statusCode})');
        return null;
      }
    } catch (e, stack) {
      print('❌ 이미지 업로드 중 오류: $e');
      print('❌ 스택 트레이스: $stack');
      return null;
    }
  }

  /// 최대 4장의 이미지를 업로드하고 image1~image4에 URL(또는 빈 문자열)로 채운 Map 반환
  Future<Map<String, String>> _uploadImagesAndBuildMap() async {
    final map = <String, String>{};
    print('🔍 이미지 업로드 → URL 수집 시작 - 총 ${_images.length}장');
    for (int i = 0; i < 4; i++) {
      if (i < _images.length) {
        final file = _images[i];
        final url = await _uploadImage(file);
        if (url != null) {
          map['image${i + 1}'] = url;
          //print('🔍 이미지 ${i + 1} URL: $url');
        } else {
          map['image${i + 1}'] = '';
          //print('❗ 이미지 ${i + 1} 업로드 실패');
        }
      } else {
        map['image${i + 1}'] = '';
        //print('🔍 이미지 ${i + 1}: 빈 슬롯');
      }
    }
    //print('🔍 최종 이미지 URL 맵 키: ${map.keys.toList()}');
    return map;
  }

  Future<void> _submitPost() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }

      final isEditMode = widget.postId != null;
      print('🔍 이미지 업로드 → URL 수집 플로우 시작');
      final imagesMap = await _uploadImagesAndBuildMap();
      // 만약 업로드 실패가 하나라도 있으면 중단
      final hasFailed = imagesMap.entries
          .where((e) => e.key.startsWith('image'))
          .any((e) => e.value.isEmpty && _images.length >= int.parse(e.key.replaceFirst('image', '')));
      if (hasFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 업로드에 실패했습니다.')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final baseBody = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        ...imagesMap,
      };

      final requestBody = isEditMode
          ? baseBody
          : {
              'userId': userId ?? 0,
              'title': _titleController.text.trim(),
              'content': _contentController.text.trim(),
              ...imagesMap,
            };

      // --- Begin: Build and log headers ---
      final authToken = (token ?? '').trim();
      if (authToken.isEmpty) {
        print('❗ JWT 토큰이 비어 있습니다.');
      } else {
        // 토큰 앞부분만 로깅 (보안상 전체 출력 금지)
        final prefix = authToken.length > 16 ? authToken.substring(0, 16) : authToken;
        print('🔑 토큰 prefix: $prefix...');
      }

      final headers = <String, String>{
        'accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
        if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
      };
      print('📤 요청 헤더(전송 예정): $headers');
      // --- End: Build and log headers ---

      final uri = isEditMode
          ? Uri.parse('http://43.203.23.173:8080/post/update/${widget.postId}')
          : Uri.parse('http://43.203.23.173:8080/post/add');

      print('🔍 요청 URI: $uri');

      final response = isEditMode
          ? await http.put(
              uri,
              headers: headers,
              body: json.encode(requestBody),
            )
          : await http.post(
              uri,
              headers: headers,
              body: json.encode(requestBody),
            );

      /*print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 바디: ${response.body}');
      print('요청 헤더: ${isEditMode ? "PUT" : "POST"} ${uri.toString()}');
      print('요청 본문 크기: ${json.encode(requestBody).length} characters');*/

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditMode ? '게시물이 성공적으로 수정되었습니다.' : '게시물이 성공적으로 작성되었습니다.')),
        );
        // 게시물 작성 후 잠시 대기 (서버 처리 시간)
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isEditMode ? "게시물 수정" : "게시물 작성"}에 실패했습니다. (${response.statusCode})')),
        );
      }
    } catch (e, stackTrace) {
      print('${widget.postId != null ? "게시물 수정" : "게시물 작성"} 에러: $e');
      print('스택 트레이스: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDFC),
        elevation: 0,
        scrolledUnderElevation: 2, // 스크롤 시 그림자
        surfaceTintColor: const Color(0xFFFAFAFA), // 스크롤 시 그림자 색상
        leading: Padding(
          padding: EdgeInsets.only(left: screenWidth * 0.06),
          child: IconButton(
            icon: Icon(
              Icons.close, 
              color: const Color(0xFF343231),
              size: screenWidth * 0.06, // 반응형 크기 (약 24px)
            ),
            onPressed: () => Navigator.pop(context),
            iconSize: screenWidth * 0.06, // 터치 영역도 반응형으로
          ),
        ),
        title: Text(
          widget.postId != null ? '수정하기' : '글쓰기',
          style: TextStyle(
            fontSize: screenWidth * 0.050, // ≈ 0.050 * 390
            fontWeight: FontWeight.w600,
            color: const Color(0xFF343231),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.06),
            child: GestureDetector(
              onTap: isLoading ? null : _submitPost,
              child: Container(
                width: screenWidth * 0.138,
                height: screenHeight * 0.033,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.031, // ≈12/390
                  vertical: screenHeight * 0.002, // ≈2/844
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF837670),
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(177, 177, 177, 0.3),
                      blurRadius: screenWidth * 0.008,
                      spreadRadius: screenWidth * 0.002,
                    ),
                  ],
                ),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: screenWidth * 0.04,
                          height: screenWidth * 0.04,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : Text(
                          '완료',
                          style: TextStyle(
                            fontSize: screenWidth * 0.041,
                            color: const Color(0xFFFEFDFC),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.024),
                  _buildTitleField(context),
                  SizedBox(height: screenHeight * 0.014),
                  _buildContentField(context),
                  SizedBox(height: screenHeight * 0.024),
                  _buildImageSection(context),
                  SizedBox(height: screenHeight * 0.024),
                  _buildCommunityPrecautions(context),
                  SizedBox(height: screenHeight * 0.014),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.057,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF6F2),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: TextField(
        controller: _titleController,
        style: TextStyle(
          color: const Color(0xFF343231),
          fontSize: screenWidth * 0.05,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: '제목',
          hintStyle: TextStyle(
            color: const Color(0xFFB1B1B1),
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.051,
          ),
        ),
      ),
    );
  }

  Widget _buildContentField(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.540,
      decoration: BoxDecoration(
        color: const Color(0xFFFEFDFC),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: TextField(
        controller: _contentController,
        maxLines: null,
        expands: true,
        style: TextStyle(
          color: Color(0xFF343231),
          fontSize: screenWidth * 0.041,
        ),
        decoration: InputDecoration(
          hintText: '내용을 입력하세요.',
          hintStyle: TextStyle(
            color: const Color(0xFFB1B1B1),
            fontSize: screenWidth * 0.041,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(screenWidth * 0.041),
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.010,
        vertical: screenHeight * 0.009,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFDFC),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.031,
              vertical: screenHeight * 0.005,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '이미지',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: screenWidth * 0.041,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF706B66),
                  ),
                ),
                Text(
                  '${_images.length}/4',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: screenWidth * 0.031,
                    color: const Color(0xFFB1B1B1),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.014),
          _buildImageGrid(context),
        ],
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        final hasImage = index < _images.length;
        if (hasImage) {
          return _imageTile(context, index);
        } else {
          return _addSlotTile(context);
        }
      },
    );
  }

  Widget _imageTile(BuildContext context, int index) {
    final file = _images[index];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: const Color(0xFFEBEBEB)),
            image: DecorationImage(
              image: FileImage(File(file.path)),
              fit: BoxFit.cover,
            ),
            color: const Color(0xFFF8F8F8),
          ),
        ),
        Positioned(
          top: -6.0,
          right: -6.0,
          child: InkWell(
            onTap: () => _removeImage(index),
            child: Container(
              width: 22.0,
              height: 22.0,
              decoration: const BoxDecoration(
                color: Color(0xFF343231),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14.0, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addSlotTile(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final canAdd = _images.length < 4;
    return GestureDetector(
      onTap: canAdd ? _pickImages : null,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFEF6F2),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: const Color(0xFFEBEBEB)),
        ),
        child: Center(
          child: Icon(
            Icons.add_photo_alternate_rounded,
            size: screenWidth * 0.051,
            color: const Color(0xFFB1B1B1),
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityPrecautions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: screenWidth * 0.04,
                color: const Color(0xFF706B66),
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                '커뮤니티 이용 주의사항',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: screenWidth * 0.032,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF343231),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            '• 전시회와 관련된 내용만 게시해주세요\n'
            '• 타인의 저작권을 침해하는 내용은 금지됩니다\n'
            '• 개인정보(이름, 연락처 등)를 공개하지 마세요\n'
            '• 욕설, 비방, 혐오 표현은 사용하지 마세요\n'
            '• 상업적 목적의 광고나 홍보는 금지됩니다\n'
            '• 부적절한 내용은 관리자에 의해 삭제될 수 있습니다',
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              height: 1.5,
              color: const Color(0xFF706B66),
            ),
          ),
        ],
      ),
    );
  }

}
