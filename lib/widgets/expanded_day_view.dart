import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:forge2d/forge2d.dart';
import 'memo_widget.dart';
import '../models/friend.dart';
import '../services/friend_manager.dart';
import '../models/ball_info.dart';
import '../services/ball_storage_service.dart';
import '../models/emoji_info.dart';

class ExpandedDayView extends StatefulWidget {
  final DateTime selectedDate;
  final Function(List<BallInfo>) onClose;
  final VoidCallback onBallsChanged; // 추가

  ExpandedDayView({
    required this.selectedDate,
    required this.onClose,
    required this.onBallsChanged, // 추가
  });

  @override
  _ExpandedDayViewState createState() => _ExpandedDayViewState();
}

class _ExpandedDayViewState extends State<ExpandedDayView> with SingleTickerProviderStateMixin {
  List<Friend> friends = [];
  late World world;
  List<Ball> balls = [];
  List<EmojiBody> emojis = []; // EmojiBody 리스트로 변경
  late AnimationController _controller;
  
  // 날짜 표시 박스의 크기
  late double dateBoxWidth;
  late double dateBoxHeight;

  final _ballStorageService = BallStorageService();

  bool _needsSave = false;
  int _frameCount = 0;
  static const int SAVE_INTERVAL = 60; // 60프레임마다 저장 (약 1초)

  final List<String> emojiList = ['😀', '😡', '😢', '😳', '😴', '😐', '🤔', '😍', '🤮', '😱'];

  @override
  void initState() {
    super.initState();
    _loadFriends();
    world = World(Vector2(0, 160));
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _controller.addListener(_updatePhysics);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBallsAndEmojis();
      _addWalls();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 물리 시뮬레이션 업데이트
  void _updatePhysics() {
    world.stepDt(1 / 60);
    setState(() {});
    
    _frameCount++;
    if (_frameCount >= SAVE_INTERVAL && _needsSave) {
      _saveBallsAndEmojis();
      _frameCount = 0;
      _needsSave = false;
    }
  }

  // 친구 목록 불러오기
  void _loadFriends() async {
    final loadedFriends = await FriendManager.getFriends();
    setState(() {
      friends = loadedFriends;
    });
  }

  // 친구 추가 다이얼로그 표시
  void _addFriend() async {
    final result = await showDialog<Friend>(
      context: context,
      builder: (context) => AddFriendDialog(),
    );
    if (result != null) {
      await FriendManager.addFriend(result);
      _loadFriends();
    }
  }

  // 공 추가
  void _addBall(Color color, double size) {
    final random = math.Random();
    final ball = Ball(
      world,
      position: Vector2(
        random.nextDouble() * dateBoxWidth,
        size // 공이 시작하는 높이를 공의 크기로 설정
      ),
      radius: size,
      restitution: 0.8,
      color: color,
    );
    setState(() {
      balls.add(ball);
    });
    _needsSave = true;
    widget.onBallsChanged(); // 콜백 호출
  }

  // 벽 추가 (공의 움직임을 제한하기 위함)
  void _addWalls() {
    // 바닥
    _addWall(Vector2(0, dateBoxHeight), Vector2(dateBoxWidth, dateBoxHeight));
    // 왼쪽 벽
    _addWall(Vector2(0, 0), Vector2(0, dateBoxHeight));
    // 오른쪽 벽
    _addWall(Vector2(dateBoxWidth, 0), Vector2(dateBoxWidth, dateBoxHeight));
  }

  // 개별 벽 추가
  void _addWall(Vector2 start, Vector2 end) {
    final wall = world.createBody(BodyDef()..type = BodyType.static);
    final shape = EdgeShape()..set(start, end);
    wall.createFixture(FixtureDef(shape)..friction = 0.3);
  }

  // 공 정보 저장
  Future<void> _saveBalls() async {
    final ballInfoList = balls.map((ball) => BallInfo(
      color: ball.color,
      radius: ball.radius,
      x: ball.body.position.x / dateBoxWidth,
      y: ball.body.position.y / dateBoxHeight,
    )).toList();
    await _ballStorageService.saveBalls(widget.selectedDate, ballInfoList);
  }

  // 공 정보 불러오기
  Future<void> _loadBalls() async {
    final ballInfoList = await _ballStorageService.loadBalls(widget.selectedDate);
    if (ballInfoList.isNotEmpty) {
      setState(() {
        balls = ballInfoList.map((info) => Ball(
          world,
          position: Vector2(info.x * dateBoxWidth, info.y * dateBoxHeight),
          radius: info.radius,
          restitution: 0.8,
          color: info.color,
        )).toList();
      });
    }
  }

  void _addEmoji(String emoji) {
    final random = math.Random();
    final emojiBody = EmojiBody(
      world,
      position: Vector2(
        random.nextDouble() * dateBoxWidth,
        random.nextDouble() * dateBoxHeight,
      ),
      emoji: emoji,
    );
    setState(() {
      emojis.add(emojiBody);
    });
    _needsSave = true;
    widget.onBallsChanged();
  }

  Future<void> _saveBallsAndEmojis() async {
    await _saveBalls();
    final emojiInfoList = emojis.map((emojiBody) => EmojiInfo(
      emoji: emojiBody.emoji,
      x: emojiBody.body.position.x / dateBoxWidth,
      y: emojiBody.body.position.y / dateBoxHeight,
    )).toList();
    await _ballStorageService.saveEmojis(widget.selectedDate, emojiInfoList);
  }

  Future<void> _loadBallsAndEmojis() async {
    await _loadBalls();
    final emojiInfoList = await _ballStorageService.loadEmojis(widget.selectedDate);
    if (emojiInfoList.isNotEmpty) {
      setState(() {
        emojis = emojiInfoList.map((info) => EmojiBody(
          world,
          position: Vector2(info.x * dateBoxWidth, info.y * dateBoxHeight),
          emoji: info.emoji,
        )).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    dateBoxWidth = screenSize.width * 0.3;
    dateBoxHeight = screenSize.height * 0.3;

    return WillPopScope(
      onWillPop: () async {
        await _saveBallsAndEmojis();
        return true;
      },
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.all(16),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('오늘은 무슨 일이 있었나요?', style: TextStyle(color: Colors.black)),
            actions: [
              IconButton(
                icon: Icon(Icons.close, color: Colors.black),
                onPressed: _saveBallsAndClose,
              ),
            ],
          ),
          body: Container(
            width: screenSize.width * 0.9,
            height: screenSize.height * 0.8,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: dateBoxWidth,
                      height: dateBoxHeight,
                      margin: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 16,
                            top: 16,
                            child: Text(
                              '${widget.selectedDate.day}',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          CustomPaint(
                            painter: BallAndEmojiPainter(balls, emojis),
                            size: Size(dateBoxWidth, dateBoxHeight),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: dateBoxHeight,
                        margin: EdgeInsets.all(16),
                        child: MemoWidget(date: widget.selectedDate),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            ...friends.map((friend) => _buildFriendCircle(friend)),
                            _buildAddFriendButton(),
                          ],
                        ),
                        SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: emojiList.map((emoji) => _buildEmojiButton(emoji)).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendCircle(Friend friend) {
    return GestureDetector(
      onTapDown: (details) => _addBall(friend.color, 20),  // 일반 탭
      onLongPress: () => _addBall(friend.color, 20),  // 길게 누르기
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: friend.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(height: 4),
          Text(friend.name, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAddFriendButton() {
    return GestureDetector(
      onTap: _addFriend,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: Colors.black),
          ),
          SizedBox(height: 4),
          Text('친구 추가', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmojiButton(String emoji) {
    return GestureDetector(
      onTap: () => _addEmoji(emoji),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  void _saveBallsAndClose() async {
    await _saveBallsAndEmojis();
    final ballInfoList = balls.map((ball) => BallInfo(
      color: ball.color,
      radius: ball.radius,
      x: ball.body.position.x / dateBoxWidth,
      y: ball.body.position.y / dateBoxHeight,
    )).toList();
    widget.onClose(ballInfoList);
    Navigator.of(context).pop();
  }
}

class Ball {
  final Body body;
  final Color color;
  final double radius;

  Ball(World world, {required Vector2 position, required this.radius, required double restitution, required this.color}) :
    body = world.createBody(BodyDef()
      ..type = BodyType.dynamic
      ..position = position
    ) {
    final shape = CircleShape()..radius = radius;
    body.createFixture(FixtureDef(shape)
      ..shape = shape
      ..restitution = restitution
      ..density = 1.0
      ..friction = 0.2
    );
  }
}

class EmojiBody {
  final Body body;
  final String emoji;

  EmojiBody(World world, {required Vector2 position, required this.emoji}) :
    body = world.createBody(BodyDef()
      ..type = BodyType.dynamic
      ..position = position
    ) {
    final shape = CircleShape()..radius = 10.0; // 이모지의 크기를 설정
    body.createFixture(FixtureDef(shape)
      ..shape = shape
      ..restitution = 0.8
      ..density = 1.0
      ..friction = 0.2
    );
  }
}

class BallAndEmojiPainter extends CustomPainter {
  final List<Ball> balls;
  final List<EmojiBody> emojis;

  BallAndEmojiPainter(this.balls, this.emojis);

  @override
  void paint(Canvas canvas, Size size) { 
    for (final ball in balls) {
      final paint = Paint()..color = ball.color;
      canvas.drawCircle(
        Offset(ball.body.position.x, ball.body.position.y),
        ball.radius,
        paint,
      );
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final emojiBody in emojis) {
      textPainter.text = TextSpan(
        text: emojiBody.emoji,
        style: TextStyle(fontSize: 20),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(emojiBody.body.position.x - textPainter.width / 2,
               emojiBody.body.position.y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AddFriendDialog extends StatefulWidget {
  @override
  _AddFriendDialogState createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('친구 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: '이름'),
          ),
          SizedBox(height: 16),
          ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (Color color) {
              setState(() => _selectedColor = color);
            },
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              Navigator.of(context).pop(Friend(
                name: _nameController.text,
                color: _selectedColor,
              ));
            }
          },
          child: Text('추가'),
        ),
      ],
    );
  }
}