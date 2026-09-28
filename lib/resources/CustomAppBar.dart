import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mikk/resources/Custom_InkWell.dart';
import 'package:mikk/values/Color.dart';

import '../values/AppFontStyleAndSize.dart';
import 'TextWidget.dart';

class CustomAppBar extends StatefulWidget {
  final bool showLeading;
  final String title;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final EdgeInsets? margin;
  final bool isLightTheme;

  const CustomAppBar({
    super.key,
    this.showLeading = false,
    this.title = "",
    this.titleFontSize,
    this.titleFontWeight, this.margin, this.isLightTheme = true,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.isLightTheme ? whiteColor : blackColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          widget.showLeading
              ? CustomInkwell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  childWidget: Container(
                    margin: widget.margin ?? EdgeInsets.only(left: 5, right: 10),
                    child: Icon(
                      Icons.arrow_back,
                      size: 20.sp,
                      color: widget.isLightTheme ? blackColor : whiteColor,
                    ),
                  ),
                )
              : Container(
                  height: 0,
                  width: 0,
                ),
          Visibility(
            visible: widget.title.isNotEmpty,
            child: TextWidget(
              txt: widget.title,
              fontSize: widget.titleFontSize ?? FontSizeAndWidth.title,
              fontWeight: widget.titleFontWeight ?? FontSizeAndWidth.medium,
              color: widget.isLightTheme ? blackColor : whiteColor,
            ),
          )
        ],
      ),
    );
  }
}
