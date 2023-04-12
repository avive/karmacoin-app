import 'package:flutter/material.dart';
import 'package:karma_coin/common_libs.dart';
import 'package:karma_coin/ui/helpers/widget_utils.dart';
import 'package:simple_animations/simple_animations.dart';

class AnimatedRightWave extends StatelessWidget {
  final double height;
  final double speed;
  final double offset;

  const AnimatedRightWave(
      {super.key, this.height = 0.0, this.speed = 1.0, this.offset = 0.0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        width: height,
        height: constraints.biggest.height,
        child: LoopAnimationBuilder(
            duration: Duration(milliseconds: (10000 / speed).round()),
            tween: Tween(begin: 0.0, end: 2 * pi),
            builder: (context, value, child) {
              return CustomPaint(
                foregroundPainter: CurvePainter(value + offset),
              );
            }),
      );
    });
  }
}

class CurvePainter extends CustomPainter {
  final double value;

  const CurvePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()..color = kcPurple.withAlpha(60);
    final path = Path();

    final x1 = sin(value);
    final x2 = sin(value + pi / 2);
    final x3 = sin(value + pi);

    final width = size.width * 0.5;

    final startPointX = width * (0.5 + 0.4 * x1);
    final controlPointX = width * (0.5 + 0.4 * x2);
    final endPointX = width * (0.5 + 0.4 * x3);

    path.moveTo(size.width, 0);

    path.lineTo(size.width - startPointX, 0);

    path.quadraticBezierTo(width - controlPointX, size.height * 0.5,
        size.width - endPointX, size.height);

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, white);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
