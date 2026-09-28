import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../values/Color.dart';

class CustomRaisedButton extends StatelessWidget {
  final Widget? child;
  final List<Color>? colors;
  final double? width , height;
  final EdgeInsets margin;
  final bool showShadow;
  final bool showBorder;

  //final double height;
  final Function? onPressed;

  const CustomRaisedButton({
    Key? key,
    @required this.child,
    this.colors,
    this.width = double.infinity,
    this.height = 46.0,
    this.onPressed,
    this.showShadow = true,
    this.showBorder = false,
    this.margin = EdgeInsets.zero
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
          gradient: LinearGradient(colors: colors ?? [primaryColor1, primaryColor1]),
          border: Border.all(color: primaryColor1),
          boxShadow: [
            BoxShadow(
              color: showShadow ? Colors.grey[500]! : Colors.transparent,
              offset: showShadow ?  const Offset(0.0, 1.5) : const Offset(0.0, 0.0),
              blurRadius: showShadow ? 1.5 : 0,
            ),
          ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            onTap:()=> onPressed!(),
            child: Center(
              child: child,
            )),
      ),
    );
  }
}
