import 'dart:ui';

import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Particle, World;
import 'package:flutter/material.dart' hide Image, Gradient;

import '../game.dart';
import '../game_colors.dart';
import '../lap_line.dart';
import '../tire.dart';

// TODO -> move 'dynamic' logic from tire to vehicle

abstract class Vehicle extends BodyComponent<PadRacingGame> {
  Vehicle({
    required this.playerNumber,
    required this.cameraComponent,
  }) : super(priority: 3);

  static final colors = [
    GameColors.green.color,
    GameColors.blue.color,
  ];

  final int playerNumber;
  final CameraComponent cameraComponent;

  final ValueNotifier<int> lapNotifier = ValueNotifier<int>(1);
  final Set<LapLine> passedStartControl = {};
  final size = const Size(6, 10);
  final scale = 10.0;
}
