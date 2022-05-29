import 'package:flame/palette.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Particle, World;
import 'package:flutter/material.dart' hide Image, Gradient;
import 'package:flutter/services.dart';

import 'game.dart';
import 'vehicle/tank.dart';

class Caterpillar extends BodyComponent<PadRacingGame> {
  Caterpillar({
    required this.tank,
    required this.pressedKeys,
    required this.isLeftCaterpillar,
    required this.jointDef,
  }) : super(
          paint: Paint()
            ..color = tank.paint.color
            ..strokeWidth = 0.2
            ..style = PaintingStyle.stroke,
          priority: 2,
        );

  final Tank tank;
  final size = Vector2(0.5, 5);
  late final RRect _renderRect = RRect.fromLTRBR(
    -size.x,
    -size.y,
    size.x,
    size.y,
    const Radius.circular(0.3),
  );

  final Set<LogicalKeyboardKey> pressedKeys;

  final RevoluteJointDef jointDef;
  late final RevoluteJoint joint;
  final bool isLeftCaterpillar;

  final Paint _black = BasicPalette.black.paint();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // gameRef.cameraWorld.add(Trail(car: car, tire: this));
  }

  @override
  Body createBody() {
    final jointAnchor = Vector2(isLeftCaterpillar ? -3.0 : 3.0, 0);

    final def = BodyDef()
      ..type = BodyType.dynamic
      ..position = tank.body.position + jointAnchor;
    final body = world.createBody(def)..userData = this;

    final polygonShape = PolygonShape()..setAsBoxXY(0.5, 1.25);
    body.createFixtureFromShape(polygonShape, 1.0).userData = this;

    jointDef.bodyB = body;
    jointDef.localAnchorA.setFrom(jointAnchor);
    world.createJoint(joint = RevoluteJoint(jointDef));
    joint.setLimits(0, 0);

    return body;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(_renderRect, _black);
    canvas.drawRRect(_renderRect, paint);
  }
}
