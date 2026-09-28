import 'package:flutter/material.dart';
import 'dart:math' as math;

class DashedRect extends StatelessWidget {
  final Color color;
  final double strokeWidth;
  final double gap;
  BorderRadius? borderRadius;
  DashedRect(
      {this.color = Colors.black, this.strokeWidth = 1.0,  this.borderRadius, this.gap = 5.0});
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: EdgeInsets.all(strokeWidth / 2),
        child: CustomPaint(
          painter:
          DashRectPainter(color: color, strokeWidth: strokeWidth, gap: gap,
            // borderRadius: borderRadius
          ),
        ),
      ),
    );
  }
}

class DashRectPainter extends CustomPainter {
  double strokeWidth;
  Color color;
  double gap;
  DashRectPainter(
      {this.strokeWidth = 5.0, this.color = Colors.red, this.gap = 5.0});
  @override
  void paint(Canvas canvas, Size size) {
    Paint dashedPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    double x = size.width;
    double y = size.height;
    Path _topPath = getDashedPath(
      a: math.Point(0, 0),
      b: math.Point(x, 0),
      gap: gap,
    );
    Path _rightPath = getDashedPath(
      a: math.Point(x, 0),
      b: math.Point(x, y),
      gap: gap,
    );
    Path _bottomPath = getDashedPath(
      a: math.Point(0, y),
      b: math.Point(x, y),
      gap: gap,
    );
    Path _leftPath = getDashedPath(
      a: math.Point(0, 0),
      b: math.Point(0.001, y),
      gap: gap,
    );
    canvas.drawPath(_topPath, dashedPaint,);
    canvas.drawPath(_rightPath, dashedPaint);
    canvas.drawPath(_bottomPath, dashedPaint);
    canvas.drawPath(_leftPath, dashedPaint);
    double w = size.width;
    double h = size.height;
    double r = 15;
    var paint1 = Paint()
      ..color = Color(0x888888)
      ..style = PaintingStyle.fill;
    RRect fullRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w / 2, h / 2), width: w, height: h),
      Radius.circular(r),
    );
    // canvas.drawRRect(fullRect, paint1);
    // canvas.drawCircle(fullRect, paint1);
  }

  Path getDashedPath({
    math.Point<double>? a,
    math.Point<double>? b,
    @required gap,
  }) {
    Size size = Size(b!.x - a!.x, b.y - a.y);
    Path path = Path();
    path.moveTo(a.x, a.y);
    bool shouldDraw = true;
    math.Point currentPoint = math.Point(a.x, a.y);
    num radians = math.atan(size.height / size.width);
    num dx = math.cos(radians) * gap < 0
        ? math.cos(radians) * gap * -1
        : math.cos(radians) * gap;
    num dy = math.sin(radians) * gap < 0
        ? math.sin(radians) * gap * -1
        : math.sin(radians) * gap;
    while (currentPoint.x <= b.x && currentPoint.y <= b.y) {
      shouldDraw
          ? path.lineTo(double.parse(currentPoint.x.toString()),double.parse( currentPoint.y.toString()))
          : path.moveTo(double.parse(currentPoint.x.toString()),double.parse( currentPoint.y.toString()));
      shouldDraw = !shouldDraw;
      currentPoint = math.Point(
        currentPoint.x + dx,
        currentPoint.y + dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}