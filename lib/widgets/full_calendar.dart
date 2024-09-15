import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:forge2d/forge2d.dart';
import 'dart:math' as math;
import 'expanded_day_view.dart';
import '../models/ball_info.dart';
import '../models/emoji_info.dart';
import '../services/ball_storage_service.dart';
import '../utils/physics_engine.dart';

class FullCalendar extends StatefulWidget {
  final DateTime? selectedDate;
  final bool isExpanded;
  final Function(DateTime)? onDaySelected;

  FullCalendar({this.selectedDate, this.isExpanded = false, this.onDaySelected});

  @override
  _FullCalendarState createState() => _FullCalendarState();
}

class _FullCalendarState extends State<FullCalendar> with SingleTickerProviderStateMixin {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final BallStorageService _ballStorageService = BallStorageService();
  Map<DateTime, List<BallInfo>> _ballsMap = {};
  Map<DateTime, PhysicsEngine> _physicsEngines = {};
  Map<DateTime, List<EmojiInfo>> _emojisMap = {};
  late AnimationController _animationController;
  final double _ballRadiusRatio = 0.4;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate ?? DateTime.now();
    _selectedDay = widget.selectedDate;
    _loadBallsForMonth(_focusedDay);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 16),
    )..addListener(() {
      setState(() {
        _updatePhysics();
      });
    });
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updatePhysics() {
    for (var engine in _physicsEngines.values) {
      engine.step(1 / 60);  // 60 FPS로 시뮬레이션
    }
  }

  Future<void> _loadBallsForMonth(DateTime month) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);
    
    final newBallsMap = await _ballStorageService.loadBallsForDateRange(startDate, endDate);
    final newEmojisMap = await _ballStorageService.loadEmojisForDateRange(startDate, endDate);
    
    setState(() {
      _ballsMap = newBallsMap;
      _emojisMap = newEmojisMap;
      _createPhysicsEngines();
    });
  }

  void _createPhysicsEngines() {
    _physicsEngines.clear();
    final cellSize = Vector2(MediaQuery.of(context).size.width / 7, MediaQuery.of(context).size.height / 8);
    
    // 공이나 이모지가 있는 모든 날짜에 대해 PhysicsEngine 생성
    Set<DateTime> datesWithContent = Set<DateTime>.from(_ballsMap.keys)..addAll(_emojisMap.keys);
    
    for (var date in datesWithContent) {
      final balls = _ballsMap[date] ?? [];
      final emojis = _emojisMap[date] ?? [];
      
      final engine = PhysicsEngine(
        gravity: Vector2(0, 30),
        worldWidth: cellSize.x,
        worldHeight: cellSize.y,
      );
      
      for (var ball in balls) {
        engine.addBall(ball, _ballRadiusRatio);
      }
      
      for (var emoji in emojis) {
        engine.addEmoji(emoji);
      }
      
      _physicsEngines[date] = engine;
    }
  }

  void _updateCalendar() {
    setState(() {
      _loadBallsForMonth(_focusedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2010, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay,) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        _showExpandedDayView(selectedDay);
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
        _loadBallsForMonth(focusedDay);
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        cellMargin: EdgeInsets.zero,
        cellPadding: EdgeInsets.zero,
      ),
      daysOfWeekHeight: 40,
      rowHeight: (MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top - 40) / 7.1,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: false,
        leftChevronVisible: false,
        rightChevronVisible: false,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, focusedDay) {
          return _buildCalendarCell(day, false, false);
        },
        selectedBuilder: (context, day, focusedDay) {
          return _buildCalendarCell(day, true, false);
        },
        todayBuilder: (context, day, focusedDay) {
          return _buildCalendarCell(day, false, true);
        },
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day, bool isSelected, bool isToday) {
    final balls = _ballsMap[DateTime(day.year, day.month, day.day)] ?? [];
    final emojis = _emojisMap[DateTime(day.year, day.month, day.day)] ?? [];
    final engine = _physicsEngines[DateTime(day.year, day.month, day.day)];
    
    return Container(
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.3) : (isToday ? Colors.blue.withOpacity(0.1) : null),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isSelected ? Colors.blue : (isToday ? Colors.blue : null),
                  fontWeight: isSelected || isToday ? FontWeight.bold : null,
                ),
              ),
            ),
          ),
          if (balls.isNotEmpty || emojis.isNotEmpty)
            CustomPaint(
              painter: BallAndEmojiPainter(engine, balls, emojis, _ballRadiusRatio),
              size: Size(MediaQuery.of(context).size.width / 7, MediaQuery.of(context).size.height / 8),
            ),
        ],
      ),
    );
  }

  void _showExpandedDayView(DateTime selectedDay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(20),
          child: ExpandedDayView(
            selectedDate: selectedDay,
            onClose: (List<BallInfo> updatedBalls) async {
              await _ballStorageService.saveBalls(selectedDay, updatedBalls);
              _loadBallsForMonth(_focusedDay);
              setState(() {});
            },
            onBallsChanged: () {
              _loadBallsForMonth(_focusedDay);
              setState(() {});
            },
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(FullCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _loadBallsForMonth(widget.selectedDate ?? DateTime.now());
    }
  }
}

class BallAndEmojiPainter extends CustomPainter {
  final PhysicsEngine? engine;
  final List<BallInfo> balls;
  final List<EmojiInfo> emojis;
  final double radiusRatio;

  BallAndEmojiPainter(this.engine, this.balls, this.emojis, this.radiusRatio);

  @override
  void paint(Canvas canvas, Size size) {
    final positions = engine?.getPositions() ?? [];
    
    // 공 그리기
    for (int i = 0; i < positions.length && i < balls.length; i++) {
      final paint = Paint()
        ..color = balls[i].color.withOpacity(1.0)
        ..style = PaintingStyle.fill;
      final radius = math.max(balls[i].radius * radiusRatio, 5.0);
      canvas.drawCircle(
        Offset(positions[i].x, positions[i].y),
        radius,
        paint,
      );
    }

    // 이모지 그리기
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = balls.length; i < positions.length && i - balls.length < emojis.length; i++) {
      final emoji = emojis[i - balls.length];
      textPainter.text = TextSpan(
        text: emoji.emoji,
        style: TextStyle(fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(positions[i].x - textPainter.width / 2,
               positions[i].y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}