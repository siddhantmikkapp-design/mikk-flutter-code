import 'package:flutter/material.dart';
import '../utils/LogHelper.dart';
import '../values/Color.dart';

class GradientBorder extends StatefulWidget {
  Widget? child;
  Color? backgroundColor;
  Color? borderColor;
  double height;
  double width;
  double radius;
  double opacity;
  int angle;
  double? borderWidth;
  EdgeInsets? padding;
  EdgeInsets? margin;
  Alignment? alignment;
  bool? isBoxShadow;
  double? borderRadiusTopLeft;
  double? borderRadiusTopRight;
  double? borderRadiusBottomLeft;
  double? borderRadiusBottomRight;

  GradientBorder({
    this.child,
    this.backgroundColor = Colors.black87,
    this.borderColor,
    this.height = 50,
    this.width = 100,
    this.radius = 10,
    this.opacity = 1,
    this.angle = 1,
    this.borderWidth = 0.5,
    this.isBoxShadow = true,
    this.alignment = Alignment.center,
    Key? key,
    required this.padding,
    this.margin = const EdgeInsets.all(0.0),
    this.borderRadiusTopLeft,
    this.borderRadiusTopRight,
    this.borderRadiusBottomLeft,
    this.borderRadiusBottomRight,
  }) : super(key: key);

  @override
  State<GradientBorder> createState() => _GradientBorderState();
}

class _GradientBorderState extends State<GradientBorder> {
  double screenWidth = 0.0;
  double screenHeight = 0.0;

  bool isGradient = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      // LogHelper("widget.borderColor : ${widget.borderColor}");
      if (widget.borderColor != null) {
        isGradient = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: widget.height,
      width: widget.width,
      margin: widget.margin,
      decoration: widget.angle == 2
          ? BoxDecoration(
              border: Border.all(color: isGradient ? Colors.transparent : widget.borderColor!, width: widget.borderWidth!),
              gradient: LinearGradient(
                colors: [
                  isGradient ? borderColor1.withOpacity(widget.opacity) : Colors.transparent,
                  isGradient ? borderColor2.withOpacity(widget.opacity) : Colors.transparent
                ],
              ),
              borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
            )
          : widget.angle == 1
              ? BoxDecoration(
                  border: Border.all(color: isGradient ? Colors.transparent : widget.borderColor!, width: widget.borderWidth!),
                  gradient: LinearGradient(
                    colors: [
                      isGradient ? borderColor1.withOpacity(widget.opacity) : Colors.transparent,
                      isGradient ? borderColor2.withOpacity(widget.opacity) : Colors.transparent
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(widget.borderRadiusTopLeft ?? widget.radius),
                    topRight: Radius.circular(widget.borderRadiusTopRight ?? widget.radius),
                    bottomLeft: Radius.circular(widget.borderRadiusBottomLeft ?? widget.radius),
                    bottomRight: Radius.circular(widget.borderRadiusBottomRight ?? widget.radius),
                  ),
                  // borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
                )
              : BoxDecoration(
                  border: Border.all(color: isGradient ? Colors.transparent : widget.borderColor!, width: widget.borderWidth!),
                  gradient: LinearGradient(colors: [
                    isGradient ? borderColor1.withOpacity(widget.opacity) : Colors.transparent,
                    isGradient ? borderColor2.withOpacity(widget.opacity) : Colors.transparent
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.all(Radius.circular(widget.radius)),
                ),
      child: Container(
        margin: EdgeInsets.all(widget.borderWidth!),
        padding: widget.padding,
        alignment: widget.alignment,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(widget.borderRadiusTopLeft ?? widget.radius - (widget.borderWidth!)),
              topRight: Radius.circular(widget.borderRadiusTopRight ?? widget.radius - (widget.borderWidth!)),
              bottomLeft: Radius.circular(widget.borderRadiusBottomLeft ?? widget.radius - (widget.borderWidth!)),
              bottomRight: Radius.circular(widget.borderRadiusBottomRight ?? widget.radius - (widget.borderWidth!)),
            ),
            // BorderRadius.all(Radius.circular(widget.radius - (widget.borderWidth!))),
            color: isGradient ? widget.backgroundColor! : Colors.black45,
            boxShadow: [
              BoxShadow(
                color: borderColor2.withOpacity(widget.isBoxShadow! ? 0.2 : 0.0001),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(4, 5),
              ),
            ]),
        child: widget.child!,
      ),
    );
  }
}
