import 'package:flutter/material.dart';
import '../widgets/full_calendar.dart';
import 'expanded_calendar_screen.dart';
import '../services/ball_storage_service.dart';
import '../widgets/memo_widget.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final BallStorageService _ballStorageService = BallStorageService();
  int _selectedIndex = 0;

  void _resetAllData() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('전체 초기화'),
          content: Text('모든 데이터를 초기화하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('초기화'),
              onPressed: () async {
                await _ballStorageService.clearAllData();
                Navigator.of(context).pop();
                setState(() {}); // 캘린더 새로고침
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('모든 데이터가 초기화되었습니다.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            FullCalendar(
              onDaySelected: (selectedDay) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExpandedCalendarScreen(selectedDate: selectedDay),
                  ),
                );
              },
            ),
            MemoWidget(
              date: DateTime.now(),
              onShare: (emoji, text) {
                // 메모 저장 로직 구현
              },
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('설정'),
                  SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _resetAllData,
                    child: Text('전체 초기화'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 50, // 네비게이션 바의 높이를 줄임
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: '캘린더',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.note),
              label: '메모',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '설정',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 10, // 선택된 아이템의 텍스트 크기를 줄임
          unselectedFontSize: 10, // 선택되지 않은 아이템의 텍스트 크기를 줄임
          iconSize: 14, // 아이콘 크기를 줄임
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}