import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Particle, World;
import 'package:flutter/material.dart' hide Image;

import 'game_colors.dart';
import 'ground_sensor.dart';
import 'main.dart';
import 'tire.dart';

class Car extends BodyComponent<PadRacingGame> {
  Car({required this.playerNumber, required this.cameraComponent})
      : super(priority: 3);

  static final colors = [
    GameColors.green.color,
    GameColors.blue.color,
  ];

  final ValueNotifier<int> lap = ValueNotifier<int>(0);
  late final TextComponent lapText;
  final int playerNumber;
  final Set<GroundSensor> passedStartControl = {};
  final CameraComponent cameraComponent;
  final double _backTireMaxDriveForce = 300.0;
  final double _frontTireMaxDriveForce = 600.0;
  final double _backTireMaxLateralImpulse = 8.5;
  final double _frontTireMaxLateralImpulse = 7.5;
  late final Image _image;
  final size = const Size(6, 10);
  final scale = 10.0;
  late final _renderPosition = -size.toOffset() / 2;
  late final _scaledRect = (size * scale).toRect();
  late final _renderRect = _renderPosition & size;

  final vertices = <Vector2>[
    Vector2(1.5, -5.0),
    Vector2(3.0, -2.5),
    Vector2(2.8, 0.5),
    Vector2(1.0, 5.0),
    Vector2(-1.0, 5.0),
    Vector2(-2.8, 0.5),
    Vector2(-3.0, -2.5),
    Vector2(-1.5, -5.0),
  ];

  @override
  Future<void> onLoad() async {
    super.onLoad();
    lapText = TextComponent(
      position: -cameraComponent.viewport.size / 2 + Vector2.all(20),
    );
    void updateLapText() {
      lapText.text = 'Lap: ${lap.value}';
    }

    lap.addListener(updateLapText);
    updateLapText();
    cameraComponent.viewport.add(lapText);

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, _scaledRect);
    final path = Path();
    paint.color = colors[playerNumber];
    for (var i = 0.0; i < _scaledRect.width / 4; i++) {
      paint.color = paint.color.darken(0.1);
      path.reset();
      final offsetVertices = vertices
          .map(
            (v) =>
                v.toOffset() * scale -
                Offset(i * v.x.sign, i * v.y.sign) +
                _scaledRect.bottomRight / 2,
          )
          .toList();
      path.addPolygon(offsetVertices, true);
      canvas.drawPath(path, paint);
    }
    final picture = recorder.endRecording();
    _image = await picture.toImage(
      _scaledRect.width.toInt(),
      _scaledRect.height.toInt(),
    );
  }

  @override
  Body createBody() {
    paint.color = ColorExtension.random();
    final startPosition =
        Vector2.all(20) + Vector2.all(20) * playerNumber.toDouble();
    final def = BodyDef()
      ..type = BodyType.dynamic
      ..position = startPosition;
    final body = world.createBody(def)
      ..userData = this
      ..angularDamping = 3.0;

    final shape = PolygonShape()..set(vertices);
    final fixtureDef = FixtureDef(shape)
      ..density = 0.2
      ..restitution = 2.0;
    body.createFixture(fixtureDef);

    final jointDef = RevoluteJointDef();
    jointDef.bodyA = body;
    jointDef.enableLimit = true;
    jointDef.lowerAngle = 0.0;
    jointDef.upperAngle = 0.0;
    jointDef.localAnchorB.setZero();

    final tires = List.generate(4, (i) {
      final isFrontTire = i <= 1;
      final isLeftTire = i.isEven;
      return Tire(
        gameRef.pressedKeySets[playerNumber],
        isFrontTire ? _frontTireMaxDriveForce : _backTireMaxDriveForce,
        isFrontTire ? _frontTireMaxLateralImpulse : _backTireMaxLateralImpulse,
        jointDef,
        isFrontTire
            ? Vector2(isLeftTire ? -3.0 : 3.0, 3.5)
            : Vector2(isLeftTire ? -3.0 : 3.0, -4.25),
        isTurnableTire: isFrontTire,
      );
    });

    gameRef.cameraWorld.addAll(tires);
    return body;
  }

  @override
  void update(double dt) {
    cameraComponent.viewfinder.position = body.position;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawImageRect(
      _image,
      _scaledRect,
      _renderRect,
      paint,
    );
  }
}
