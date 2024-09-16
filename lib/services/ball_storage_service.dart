import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ball_info.dart';
import '../models/stored_memo.dart';

class BallStorageService {
  String _getKey(DateTime date) {
    return 'balls_${date.year}_${date.month}_${date.day}';
  }

  Future<void> saveBalls(DateTime date, List<BallInfo> balls) async {
    final prefs = await SharedPreferences.getInstance();
    final ballInfoList = balls.map((ball) => ball.toJson()).toList();
    await prefs.setString(_getKey(date), jsonEncode(ballInfoList));
  }

  Future<List<BallInfo>> loadBalls(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final ballsJson = prefs.getString(_getKey(date));
    if (ballsJson != null) {
      final ballInfoList = (jsonDecode(ballsJson) as List).map((item) => BallInfo.fromJson(item)).toList();
      return ballInfoList;
    }
    return [];
  }

  Future<Map<DateTime, List<BallInfo>>> loadBallsForDateRange(DateTime start, DateTime end) async {
    final Map<DateTime, List<BallInfo>> ballsMap = {};
    for (DateTime date = start; date.isBefore(end.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
      final balls = await loadBalls(date);
      if (balls.isNotEmpty) {
        ballsMap[DateTime(date.year, date.month, date.day)] = balls;
      }
    }
    return ballsMap;
  }

  Future<void> clearAllData() async {
    // 모든 데이터를 지우는 로직 구현
    // 예: SharedPreferences를 사용하는 경우
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  String _getEmojiKey(DateTime date) {
    return 'emojis_${date.year}_${date.month}_${date.day}';
  }

  String _getMemoKey(DateTime date) {
    return 'memos_${date.year}_${date.month}_${date.day}';
  }

  Future<void> saveMemos(DateTime date, List<SharedMemo> memos) async {
    final prefs = await SharedPreferences.getInstance();
    final memoList = memos.map((memo) => memo.toJson()).toList();
    await prefs.setString(_getMemoKey(date), jsonEncode(memoList));
  }

  Future<List<SharedMemo>> loadMemos(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final memosJson = prefs.getString(_getMemoKey(date));
    if (memosJson != null) {
      final memoList = (jsonDecode(memosJson) as List).map((item) => SharedMemo.fromJson(item)).toList();
      return memoList;
    }
    return [];
  }

}
