import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'utils/auth_storage.dart';
import 'bottom_nav_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_slidable/flutter_slidable.dart';

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
        alarms = (jsonDecode(utf8.decode(response.bodyBytes)) as List);
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
        for (var alarm in alarms) {
          alarm['isRead'] = true;
        }
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
        }
      });
    } else {
      print('❌ 알림 읽음 처리 실패');
    }
  }

  Future<void> _deleteAlarm(int alarmId) async {
    if (token == null) return;

    final response = await http.delete(
      Uri.parse('http://43.203.23.173:8080/alarm/$alarmId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        alarms.removeWhere((alarm) => alarm['alarmId'] == alarmId);
      });
    } else {
      print('❌ 알림 삭제 실패');
    }
  }

  Future<void> _deleteAllAlarms() async {
    if (token == null) return;
    final response = await http.delete(
      Uri.parse('http://43.203.23.173:8080/alarm/all/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      setState(() {
        alarms.clear();
      });
    } else {
      print('❌ 모든 알림 삭제 실패');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: _buildAlarmAppBar(context, _markAllAsRead, _deleteAllAlarms),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.025),
            Expanded(
              child: alarms.isEmpty
                  ? Center(
                      child: Text(
                        '도착한 알람이 없습니다.',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04, 
                          color: Color(0xFF706B66),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: alarms.length,
                      separatorBuilder: (context, index) => SizedBox(height: screenHeight * 0.01),
                      itemBuilder: (context, index) {
                        final alarm = alarms[index];
                        final createdAtString = alarm['createdAt'] ?? '';
                        DateTime? createdAt;
                        try {
                          createdAt = DateTime.parse(createdAtString);
                        } catch (_) {
                          createdAt = null;
                        }
                        final formattedDate = createdAt != null ? DateFormat('MM.dd HH:mm').format(createdAt) : '';

                        return Slidable(
                          key: Key(alarm['alarmId'].toString()),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            extentRatio: 185 / screenWidth,
                            children: [
                              Container(
                                width: screenWidth * 0.20, 
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: CustomSlidableAction(
                                  onPressed: (context) async {
                                    await _deleteAlarm(alarm['alarmId']);
                                  },
                                  backgroundColor: const Color(0xFFA28F7D),
                                  child: Center(
                                    child: Text(
                                      '삭제',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04, // 16px
                                        color: Color(0xFFFEFDFC),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: screenWidth * 0.20, 
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: CustomSlidableAction(
                                  onPressed: (context) async {
                                    await _markAlarmAsRead(alarm['alarmId']);
                                  },
                                  backgroundColor: const Color(0xFFEBEBEB),
                                  child: Center(
                                    child: Text(
                                      '읽음',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04, // 16px
                                        color: Color(0xFF706B66),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          child: GestureDetector(
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
                                  color: const Color(0xFFEBEBEB),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (alarm['isRead'] == false) ...[
                                        Container(
                                          width: screenWidth * 0.02, 
                                          height: screenWidth * 0.02,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFC06062),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.01), 
                                      ],
                                      Expanded(
                                        child: Text(
                                          alarm['title'] ?? '',
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
                                    alarm['content'] ?? '',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF343231),
                                    ),
                                  ),
                                ],
                              ),
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

}

PreferredSizeWidget _buildAlarmAppBar(BuildContext context, VoidCallback onMarkAllRead, VoidCallback onDeleteAllAlarms) {
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
          color: Color(0xFFFEF6F2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 2,
          onSelected: (value) {
            if (value == 0) {
              onMarkAllRead();
            } else if (value == 1) {
              onDeleteAllAlarms();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<int>(
              value: 0,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '모두 읽음 표시',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF343231),
                  ),
                ),
              ),
            ),
            PopupMenuItem<int>(
              value: 1,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '모든 알림 삭제',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF343231),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}