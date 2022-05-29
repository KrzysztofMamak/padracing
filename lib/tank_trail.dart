import 'dart:ui';

import 'package:flame/components.dart';

import 'vehicle/tank.dart';

class TankTrail extends Component with HasPaint {
  TankTrail({
    required this.tank,
  }) : super(priority: 1);

  final Tank tank;

  final trail = <Offset>[];
  final _trailLength = 30;

  @override
  Future<void> onLoad() async {
    paint
      ..color = (tank.paint.color.withOpacity(0.9))
      ..strokeWidth = 5.0;
  }

  @override
  void update(double dt) {
    if (tank.body.linearVelocity.length2 > 100) {
      if (trail.length > _trailLength) {
        trail.removeAt(0);
      }
      final trailPoint = tank.body.position.toOffset();
      trail.add(trailPoint);
    } else if (trail.isNotEmpty) {
      trail.removeAt(0);
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawPoints(PointMode.polygon, trail, paint);
  }
}
