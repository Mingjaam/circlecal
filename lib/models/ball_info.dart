import 'package:flutter/material.dart';

class BallInfo {
  Color color;
  double radius;
  double x;
  double y;

  BallInfo({
    required this.color,
    required this.radius,
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toJson() => {
    'color': color.value,
    'radius': radius,
    'x': x,
    'y': y,
  };

  factory BallInfo.fromJson(Map<String, dynamic> json) => BallInfo(
    color: Color(json['color'] as int),
    radius: json['radius'] as double,
    x: json['x'] as double,
    y: json['y'] as double,
  );
}