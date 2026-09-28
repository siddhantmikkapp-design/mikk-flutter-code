import 'package:flutter/material.dart';

import '../values/AppFontStyleAndSize.dart';
import '../values/Color.dart';
import '../values/StaticText.dart';

class TextWidget extends StatefulWidget {
  // final Function? onTap;
  final String txt;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final int? maxLines;
  final String? fontFamily;

  final TextAlign? txtAlign;

  // String fontFamily = ConstantLabels.Poppins;
  const TextWidget({
    super.key,
    // this.onTap,
    this.fontFamily = ConstantLabels.Poppins,
    required this.txt,
    required this.fontSize, // = 14,
    required this.fontWeight, // = FontWeight.normal,
    this.color = blackColor,
    this.maxLines,
    this.txtAlign = TextAlign.start,
  });

  @override
  State<TextWidget> createState() => _TextWidgetState();
}

class _TextWidgetState extends State<TextWidget> {
  @override
  Widget build(BuildContext context) {
    return Text(
      widget.txt,
      textAlign: widget.txtAlign,
      maxLines: widget.maxLines,
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: widget.fontWeight,
        color: widget.color,
        fontFamily: widget.fontFamily,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
