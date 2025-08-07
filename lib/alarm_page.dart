import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'utils/auth_storage.dart';
import 'bottom_nav_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AlarmPage extends StatefulWidget {
  final int initialIndex;
  const AlarmPage({Key? key, required this.initialIndex}) : super(key: key);

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  String? token;
  int? userId;
  List<dynamic> alarms = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadAuthInfo();
    if (userId != null) {
      await _fetchAlarms();
    }
  }

  Future<void> _loadAuthInfo() async {
    token = await getJwtToken();
    userId = await getUserId();
    setState(() {});
  }

  Future<void> _fetchAlarms() async {
    final response = await http.get(
      Uri.parse('http://43.203.23.173:8080/alarm/list/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      setState(() {
        alarms = (jsonDecode(utf8.decode(response.bodyBytes)) as List)
            .where((alarm) => alarm['isRead'] == false)
            .toList();
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (userId == null) return;

    final response = await http.put(
      Uri.parse('http://43.203.23.173:8080/alarm/readAll/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        alarms.clear();
      });
    } else {
      // Optional: handle error
      print('❌ 모든 알림 읽음 처리 실패');
    }
  }

  Future<void> _markAlarmAsRead(int alarmId) async {
    if (token == null) return;

    final response = await http.put(
      Uri.parse('http://43.203.23.173:8080/alarm/read/$alarmId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        final index = alarms.indexWhere((alarm) => alarm['alarmId'] == alarmId);
        if (index != -1) {
          alarms[index]['isRead'] = true;
          alarms.removeAt(index);
        }
      });
    } else {
      print('❌ 알림 읽음 처리 실패');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: _buildAlarmAppBar(context, _markAllAsRead),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.025),
            Expanded(
              child: ListView.separated(
                itemCount: alarms.length,
                separatorBuilder: (context, index) => SizedBox(height: screenHeight * 0.01),
                itemBuilder: (context, index) {
                  final alarm = alarms[index];
                  final createdAt = DateTime.parse(alarm['createdAt']);
                  final formattedDate = DateFormat('MM.dd HH:mm').format(createdAt);

                  return GestureDetector(
                    onTap: () async {
                      await _markAlarmAsRead(alarm['alarmId']);
                      // TODO: 게시물 이동은 이후 구현
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.02,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFFFEFDFC),
                        border: Border.all(
                          color: Color(0xFFEBEBEB),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _getAlarmTitle(alarm['type']),
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF343231),
                                  ),
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF706B66),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.0047),
                          Text(
                            _getAlarmContent(alarm['type']),
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF343231),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBarWidget(currentIndex: widget.initialIndex),
    );
  }

  // 알림 내용은 추후 수정 예정
  String _getAlarmTitle(String type) {
    switch (type) {
      case 'REPLY':
        return '내 댓글에 답글이 달렸습니다';
      case 'COMMENT':
        return '내 게시글에 댓글이 달렸습니다';
      default:
        return '알림 제목';
    }
  }

  String _getAlarmContent(String type) {
    switch (type) {
      case 'REPLY':
        return '답글 내용이 여기에 표시됩니다.';
      case 'COMMENT':
        return '댓글 내용이 여기에 표시됩니다.';
      default:
        return '알림 내용';
    }
  }
}

PreferredSizeWidget _buildAlarmAppBar(BuildContext context, VoidCallback onMarkAllRead) {
  final screenWidth = MediaQuery.of(context).size.width;

  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    leading: Padding(
      padding: EdgeInsets.only(left: screenWidth * 0.06),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF343231)),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    title: Text(
      'musai',
      style: TextStyle(
        color: const Color(0xFF343231),
        fontSize: screenWidth * 0.08,
        fontWeight: FontWeight.bold,
        letterSpacing: 0,
      ),
    ),
    actions: [
      Padding(
        padding: EdgeInsets.only(right: screenWidth * 0.06),
        child: PopupMenuButton<int>(
          icon: Icon(Icons.more_vert, color: const Color(0xFF343231), size: screenWidth * 0.051),
          onSelected: (value) {
            if (value == 0) {
              onMarkAllRead();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 0,
              child: Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  return Text(
                    '모두 읽음으로 표시',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF343231),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ],
  );
}