import 'package:flutter/material.dart';

class EmojiInfo {
  final String emoji;
  final double x;
  final double y;

  EmojiInfo({
    required this.emoji,
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    'x': x,
    'y': y,
  };

  factory EmojiInfo.fromJson(Map<String, dynamic> json) => EmojiInfo(
    emoji: json['emoji'] as String,
    x: json['x'] as double,
    y: json['y'] as double,
  );
}