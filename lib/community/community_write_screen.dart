import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io'; // File 클래스 사용을 위해 추가
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; // 이미지 압축용
import '../utils/auth_storage.dart';
import 'community_screen.dart';

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
        if (multi != null && multi.isNotEmpty) {
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

  /// image1~image4에 Base64로 넣을 Map 생성
  Future<Map<String, String>> _encodeImagesForRequest() async {
    final map = <String, String>{};
    print('🔍 이미지 인코딩 시작 - 총 ${_images.length}장');
    
    // 최대 4장만 반영
    for (int i = 0; i < 4; i++) {
      if (i < _images.length) {
        final file = _images[i];
        print('🔍 이미지 ${i + 1} 처리: ${file.path}');
        
        final bytes = await _images[i].readAsBytes();
        print('🔍 이미지 ${i + 1} 원본 크기: ${bytes.lengthInBytes} bytes');
        
        final comp = await _compressBytes(bytes);
        print('🔍 이미지 ${i + 1} 압축 후 크기: ${comp.lengthInBytes} bytes');
        
        final b64 = base64Encode(comp);
        print('🔍 이미지 ${i + 1} Base64 길이: ${b64.length}');
        
        // API 스펙에 맞게 단순 Base64 문자열로 전송
        map['image${i + 1}'] = b64;
      } else {
        // 빈 슬롯은 빈 문자열로
        map['image${i + 1}'] = '';
        print('🔍 이미지 ${i + 1}: 빈 슬롯');
      }
    }
    
    print('🔍 최종 이미지 맵 키: ${map.keys.toList()}');
    return map;
  }

  // ---------- 업로드 ----------

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
      final imagesMap = await _encodeImagesForRequest();

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

      print('🔍 ${isEditMode ? "게시물 수정" : "게시물 작성"} 시작...');
      print('🔍 토큰: ${token != null ? "있음" : "없음"}');
      print('🔍 사용자 ID: $userId');
      print('🔍 이미지 개수: ${_images.length}');
      print('🔍 이미지 맵: $imagesMap');
      print('🔍 요청 본문: $requestBody');
      print('🔍 HTTP 메서드: ${isEditMode ? "PUT" : "POST"}');

      final uri = isEditMode
          ? Uri.parse('http://43.203.23.173:8080/post/update/${widget.postId}')
          : Uri.parse('http://43.203.23.173:8080/post/add');
      
      print('🔍 요청 URI: $uri');

      final response = isEditMode
          ? await http.put(
              uri,
              headers: {
                'accept': '*/*',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(requestBody),
            )
          : await http.post(
              uri,
              headers: {
                'accept': '*/*',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(requestBody),
            );

      print('📊 응답 상태 코드: ${response.statusCode}');
      print('📊 응답 헤더: ${response.headers}');
      print('📊 응답 바디: ${response.body}');
      print('📊 요청 헤더: ${isEditMode ? "PUT" : "POST"} ${uri.toString()}');
      print('📊 요청 본문 크기: ${json.encode(requestBody).length} characters');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditMode ? '게시물이 성공적으로 수정되었습니다.' : '게시물이 성공적으로 작성되었습니다.')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isEditMode ? "게시물 수정" : "게시물 작성"}에 실패했습니다. (${response.statusCode})')),
        );
      }
    } catch (e, stackTrace) {
      print('❌ ${widget.postId != null ? "게시물 수정" : "게시물 작성"} 에러: $e');
      print('❌ 스택 트레이스: $stackTrace');
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
      backgroundColor: const Color(0xFFFFFEFD),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              // X 버튼
              Positioned(
                top: screenHeight * (23 / 844),
                left: screenWidth * (24 / 390),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // 글쓰기/수정 타이틀
              Positioned(
                top: screenHeight * (31 / 844),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    widget.postId != null ? '수정하기' : '글쓰기',
                    style: TextStyle(
                      fontSize: screenWidth * (20 / 390),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ),

              // 완료 버튼
              Positioned(
                top: screenHeight * (31 / 844),
                right: screenWidth * (24 / 390),
                child: GestureDetector(
                  onTap: isLoading ? null : _submitPost,
                  child: Container(
                    width: screenWidth * (52 / 390),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * (12 / 390),
                      vertical: screenHeight * (4 / 844),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF837670),
                      borderRadius: BorderRadius.circular(screenWidth * (23.226 / 390)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(177, 177, 177, 0.3),
                          blurRadius: screenWidth * (3.097 / 390),
                          spreadRadius: screenWidth * (0.774 / 390),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              width: screenWidth * (16 / 390),
                              height: screenWidth * (16 / 390),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              '완료',
                              style: TextStyle(
                                fontSize: screenWidth * (14 / 390), // 16 -> 14
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              // 본문 입력 영역
              Positioned(
                top: screenHeight * (87 / 844),
                left: screenWidth * (24 / 390),
                right: screenWidth * (24 / 390),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                                            // 제목 입력란
                      Container(
                        width: screenWidth * (342 / 390),
                        height: screenHeight * (48 / 844),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF6F2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _titleController,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * (20 / 390),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                          decoration: InputDecoration(
                            hintText: '제목',
                            hintStyle: TextStyle(
                              color: const Color(0xFFB1B1B1),
                              fontSize: screenWidth * (20 / 390),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard',
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: screenWidth * (20 / 390),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * (12 / 844)),

                      // 내용 입력란
                      Container(
                        width: screenWidth * (342 / 390),
                        height: screenHeight * (456 / 844),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEBEBEB)),
                        ),
                        child: TextField(
                          controller: _contentController,
                          maxLines: null,
                          expands: true,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * (16 / 390),
                            fontFamily: 'Pretendard',
                          ),
                          decoration: InputDecoration(
                            hintText: '내용을 입력하세요.',
                            hintStyle: TextStyle(
                              color: const Color(0xFFB1B1B1),
                              fontSize: screenWidth * (16 / 390),
                              fontFamily: 'Pretendard',
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(screenWidth * (20 / 390)),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * (20 / 844)),

                      // --- 이미지 업로드 영역 (최대 4) ---
                      Container(
                        width: screenWidth * (342 / 390),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * (4 / 390),
                          vertical: screenHeight * (8 / 844),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEBEBEB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 상단 라벨 + 개수
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * (12 / 390),
                                vertical: screenHeight * (4 / 844),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '이미지',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: screenWidth * (14 / 390),
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF706B66),
                                    ),
                                  ),
                                  Text(
                                    '${_images.length}/4',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: screenWidth * (12 / 390),
                                      color: const Color(0xFFB1B1B1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * (12 / 844)), // 4 -> 12

                            // 2x2 그리드: 선택된 이미지 + 추가 버튼
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4, // 한 줄에 4칸(작은 정사각형)
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: 4,
                              itemBuilder: (context, index) {
                                final hasImage = index < _images.length;
                                if (hasImage) {
                                  final file = _images[index];
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                           borderRadius: BorderRadius.circular(12),
                                           border: Border.all(color: const Color(0xFFEBEBEB)),
                                           image: DecorationImage(
                                             image: FileImage(
                                               File(file.path),
                                             ),
                                             fit: BoxFit.cover,
                                           ),
                                           color: const Color(0xFFF8F8F8),
                                         ),
                                       ),
                                       Positioned(
                                         top: -6,
                                         right: -6,
                                         child: InkWell(
                                           onTap: () => _removeImage(index),
                                           child: Container(
                                             width: 22,
                                             height: 22,
                                             decoration: const BoxDecoration(
                                               color: Colors.black87,
                                               shape: BoxShape.circle,
                                             ),
                                             child: const Icon(Icons.close, size: 14, color: Colors.white),
                                           ),
                                         ),
                                       ),
                                     ],
                                   );
                                 } else {
                                   // 빈 슬롯(추가 버튼)
                                   final canAdd = _images.length < 4;
                                   return GestureDetector(
                                     onTap: canAdd ? _pickImages : null,
                                     child: Container(
                                       decoration: BoxDecoration(
                                         color: const Color(0xFFFEF6F2),
                                         borderRadius: BorderRadius.circular(12),
                                         border: Border.all(color: const Color(0xFFEBEBEB)),
                                       ),
                                       child: Center(
                                         child: Icon(
                                           Icons.add_photo_alternate_rounded,
                                           size: screenWidth * (20 / 390),
                                           color: const Color(0xFFB1B1B1),
                                         ),
                                       ),
                                     ),
                                   );
                                 }
                               },
                             ),
                           ],
                         ),
                       ),
                        SizedBox(height: screenHeight * (12 / 844)),
                      // 커뮤니티 이용 수칙
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: screenWidth * (16 / 390)),
                          child: Text(
                            '커뮤니티 이용 수칙\n비속어 사용 금지 등등..',
                            style: TextStyle(
                              color: const Color(0xFF706B66),
                              fontSize: screenWidth * (12 / 390),
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * (12 / 844)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
