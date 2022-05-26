import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame/palette.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Particle, World;
import 'package:flutter/services.dart';

import '../game_colors.dart';
import 'vehicle.dart';

class Tank extends Vehicle {
  Tank({
    required super.playerNumber,
    required super.cameraComponent,
  });

  static final colors = [
    GameColors.green.color,
    GameColors.blue.color,
  ];

  late final Image _image;
  late final _renderPosition = -size.toOffset() / 2;
  late final _scaledRect = (size * scale).toRect();
  late final _renderRect = _renderPosition & size;
  Set<LogicalKeyboardKey> pressedKeys = {};
  static const double _backTireMaxDriveForce = 300.0;
  static const double _frontTireMaxDriveForce = 600.0;
  static const double _backTireMaxLateralImpulse = 8.5;
  static const double _frontTireMaxLateralImpulse = 7.5;
  late final double _maxDriveForce = _frontTireMaxDriveForce;
  late final double _maxLateralImpulse = _frontTireMaxLateralImpulse;

// Make mutable if ice or something should be implemented
  final double _currentTraction = 1.0;

  final double _maxForwardSpeed = 250.0;
  final double _maxBackwardSpeed = -40.0;

  late final RevoluteJoint joint;

  final double _lockAngle = 0.6;
  final double _turnSpeedPerSecond = 4;

  final Paint _black = BasicPalette.black.paint();

  final vertices = <Vector2>[
    Vector2(1.5, -5.0),
    Vector2(1.0, -2.5),
    Vector2(3.8, 0.5),
    Vector2(0.0, 5.0),
    Vector2(-1.0, 5.0),
    Vector2(-2.8, 0.5),
    Vector2(-3.0, -2.5),
    Vector2(-1.5, -6.0),
  ];

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, _scaledRect);
    final path = Path();
    paint.color = colors[playerNumber];
    final bodyPaint = Paint()..color = paint.color;
    for (var i = 0.0; i < _scaledRect.width / 4; i++) {
      bodyPaint.color = bodyPaint.color.darken(0.1);
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
      canvas.drawPath(path, bodyPaint);
    }
    final picture = recorder.endRecording();
    _image = await picture.toImage(
      _scaledRect.width.toInt(),
      _scaledRect.height.toInt(),
    );
  }

  @override
  Body createBody() {
    pressedKeys = gameRef.pressedKeySets[playerNumber];

    final startPosition =
        Vector2(20, 30) + Vector2(15, 0) * playerNumber.toDouble();
    final def = BodyDef()
      ..type = BodyType.dynamic
      ..position = startPosition;
    final body = world.createBody(def)
      ..userData = this
      ..angularDamping = 3.0;

    final jointAnchor = Vector2(-3.0, 3.5);

    final defT = BodyDef()
      ..type = BodyType.dynamic
      ..position = body.position + jointAnchor;
    final bodyT = world.createBody(defT)..userData = this;

    final jointDef = RevoluteJointDef()
      ..bodyA = body
      ..enableLimit = true
      ..lowerAngle = 0.0
      ..upperAngle = 0.0
      ..localAnchorB.setZero();

    jointDef.bodyB = bodyT;
    jointDef.localAnchorA.setFrom(jointAnchor);
    world.createJoint(joint = RevoluteJoint(jointDef));
    joint.setLimits(0, 0);

    final shape = PolygonShape()..set(vertices);
    final fixtureDef = FixtureDef(shape)
      ..density = 0.2
      ..restitution = 2.0;
    body.createFixture(fixtureDef);

    return body;
  }

  @override
  void update(double dt) {
    if (body.isAwake || pressedKeys.isNotEmpty) {
      _updateTurn(dt);
      _updateFriction();
      if (!gameRef.isGameOver) {
        _updateDrive();
      }
    }
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

  void _updateFriction() {
    final impulse = _lateralVelocity
      ..scale(-body.mass)
      ..clampScalar(-_maxLateralImpulse, _maxLateralImpulse)
      ..scale(_currentTraction);
    body.applyLinearImpulse(impulse);
    body.applyAngularImpulse(
      0.1 * _currentTraction * body.getInertia() * -body.angularVelocity,
    );

    final currentForwardNormal = _forwardVelocity;
    final currentForwardSpeed = currentForwardNormal.length;
    currentForwardNormal.normalize();
    final dragForceMagnitude = -2 * currentForwardSpeed;
    body.applyForce(
      currentForwardNormal..scale(_currentTraction * dragForceMagnitude),
    );
  }

  void _updateDrive() {
    var desiredSpeed = 0.0;
    if (pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      desiredSpeed = _maxForwardSpeed;
    }
    if (pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      desiredSpeed += _maxBackwardSpeed;
    }

    final currentForwardNormal = body.worldVector(Vector2(0.0, 1.0));
    final currentSpeed = _forwardVelocity.dot(currentForwardNormal);
    var force = 0.0;
    if (desiredSpeed < currentSpeed) {
      force = -_maxDriveForce;
    } else if (desiredSpeed > currentSpeed) {
      force = _maxDriveForce;
    }

    if (force.abs() > 0) {
      body.applyForce(currentForwardNormal..scale(_currentTraction * force));
    }
  }

  void _updateTurn(double dt) {
    var desiredAngle = 0.0;
    var desiredTorque = 0.0;
    var isTurning = false;
    if (pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      desiredTorque = -15.0;
      desiredAngle = -_lockAngle;
      isTurning = true;
    }
    if (pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      desiredTorque += 15.0;
      desiredAngle += _lockAngle;
      isTurning = true;
    }
    if (isTurning) {
      final turnPerTimeStep = _turnSpeedPerSecond * dt;
      final angleNow = joint.jointAngle();
      final angleToTurn = (desiredAngle - angleNow)
          .clamp(-turnPerTimeStep, turnPerTimeStep)
          .toDouble();
      final angle = angleNow + angleToTurn;
      joint.setLimits(angle, angle);
    } else {
      joint.setLimits(0, 0);
    }
    body.applyTorque(desiredTorque);
  }

// Cached Vectors to reduce unnecessary object creation.
  final Vector2 _worldLeft = Vector2(1.0, 0.0);
  final Vector2 _worldUp = Vector2(0.0, -1.0);

  Vector2 get _lateralVelocity {
    final currentRightNormal = body.worldVector(_worldLeft);
    return currentRightNormal
      ..scale(currentRightNormal.dot(body.linearVelocity));
  }

  Vector2 get _forwardVelocity {
    final currentForwardNormal = body.worldVector(_worldUp);
    return currentForwardNormal
      ..scale(currentForwardNormal.dot(body.linearVelocity));
  }
}
