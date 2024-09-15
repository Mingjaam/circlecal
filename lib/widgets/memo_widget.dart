import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoWidget extends StatefulWidget {
  final DateTime date;

  MemoWidget({required this.date});

  @override
  _MemoWidgetState createState() => _MemoWidgetState();
}

class _MemoWidgetState extends State<MemoWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadMemo();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 메모 불러오기
  void _loadMemo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getMemoKey(widget.date);
      final memo = prefs.getString(key) ?? '';
      if (mounted) {  // 위젯이 여전히 트리에 있는지 확인
        setState(() {
          _controller.text = memo;
        });
      }
    } catch (e) {
      print('메모 불러오기 오류: $e');
    }
  }

  // 메모 저장하기
  void _saveMemo(String memo) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getMemoKey(widget.date);
    await prefs.setString(key, memo);
  }

  // 날짜별 고유 키 생성
  String _getMemoKey(DateTime date) {
    return 'memo_${date.year}_${date.month}_${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
      ),
      child: TextField(
        controller: _controller,
        maxLines: null,
        style: TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: '메모를 입력하세요',
          hintStyle: TextStyle(fontSize: 14),
          contentPadding: EdgeInsets.all(12),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          _saveMemo(value);
        },
      ),
    );
  }
}