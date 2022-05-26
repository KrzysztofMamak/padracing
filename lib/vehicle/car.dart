import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Particle, World;

import '../game_colors.dart';
import '../tire.dart';
import 'vehicle.dart';

class Car extends Vehicle {
  Car({
    required super.playerNumber,
    required super.cameraComponent,
  });

  static final colors = [
    GameColors.green.color,
    GameColors.blue.color,
  ];

  late final List<Tire> tires;
  late final Image _image;
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
    final startPosition =
        Vector2(20, 30) + Vector2(15, 0) * playerNumber.toDouble();
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

    final jointDef = RevoluteJointDef()
      ..bodyA = body
      ..enableLimit = true
      ..lowerAngle = 0.0
      ..upperAngle = 0.0
      ..localAnchorB.setZero();

    tires = List.generate(4, (i) {
      final isFrontTire = i <= 1;
      final isLeftTire = i.isEven;
      return Tire(
        car: this,
        pressedKeys: gameRef.pressedKeySets[playerNumber],
        isFrontTire: isFrontTire,
        isLeftTire: isLeftTire,
        jointDef: jointDef,
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

  @override
  void onRemove() {
    for (final tire in tires) {
      tire.removeFromParent();
    }
  }
}
