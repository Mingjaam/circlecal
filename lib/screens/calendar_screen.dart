import 'package:flutter/material.dart';
import '../widgets/full_calendar.dart';
import 'expanded_calendar_screen.dart';
import '../services/ball_storage_service.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final BallStorageService _ballStorageService = BallStorageService();

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
      appBar: AppBar(
        title: Text('캘린더 앱'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetAllData,
            tooltip: '전체 초기화',
          ),
        ],
      ),
      body: FullCalendar(
        onDaySelected: (selectedDay) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpandedCalendarScreen(selectedDate: selectedDay),
            ),
          );
        },
      ),
    );
  }
}