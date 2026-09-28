import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mikk/values/AppFontStyleAndSize.dart';
import 'package:mikk/values/ImageUrl.dart';

import '../../utils/CommonMethods.dart';
import '../../values/Color.dart';

typedef onClickCallBack = void Function();

class CustomProfileMenuItem extends StatefulWidget {
  final onClickCallBack onClickCall;
  String label = "", desc = "", image = "";
  FontWeight? fontStyle = FontSizeAndWidth.bold;
  Color? color;
  IconData? icon;

  CustomProfileMenuItem(
      {Key? key,
      required this.label,
      required this.desc,
      required this.onClickCall,
      this.fontStyle,
      this.image = "",
      this.color,
      this.icon})
      : super(key: key);

  @override
  _CustomProfileMenuItemState createState() {
    label = this.label;
    return _CustomProfileMenuItemState();
  }
}

class _CustomProfileMenuItemState extends State<CustomProfileMenuItem> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => widget.onClickCall(),
      child: Container(
          //width: MediaQuery.of(context).size.width,
          padding: widget.image.isEmpty
              ? const EdgeInsets.only(top: 16.0, bottom: 16.0, left: 16.0, right: 10.0)
              : const EdgeInsets.only(top: 6.0, bottom: 6.0, left: 10.0, right: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Visibility(
                visible: widget.image.isNotEmpty,
                child: Container(
                  width: 50,
                  height: 50,
                  padding: EdgeInsets.all(7),
                  margin: EdgeInsets.only(right: 16.0),
                  decoration: BoxDecoration(borderRadius: const BorderRadius.all(Radius.circular(32.0)),
                      color: widget.color ?? Colors.transparent),
                      // color: widget.color!= null ? widget.color : Colors.transparent),
                  child: CachedNetworkImage(
                    imageUrl: widget.image.isNotEmpty ? widget.image : ImageUrl.ic_splash,
                    fit: BoxFit.cover,
                    width: 40,
                    height: 40,
                    progressIndicatorBuilder:
                        (context, url, downloadProgress) => Center(
                            child: CircularProgressIndicator(
                                value: downloadProgress.progress)),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ),
              ),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: CommonMethods.setTextStyle(
                          FontSizeAndWidth.subTitle, widget.fontStyle!),
                    ),
                    Text(
                      widget.desc,
                      style: CommonMethods.setTextStyle(
                          FontSizeAndWidth.tinyText, FontSizeAndWidth.medium),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: widget.icon != null,
                child: Container(
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(32.0)),
                    color: widget.color ?? Colors.transparent,
                    // gradient: LinearGradient(colors: [primaryColor1, primaryColor2])
                  ),
                  // margin: EdgeInsets.only(right: 16.0),
                  child: Icon(
                    widget.icon,
                    size: 24.0,
                    color: blackColor.withOpacity(0.5),
                  ),
                ),
              ),
             /* Visibility(
                visible: widget.image.isEmpty,
                child: Icon(
                  *//*widget.icon != null ? widget.icon :*//* Icons.navigate_next,
                  size: 24.0,
                  color: blackColor,
                ),
              )*/
            ],
          )),
    );
  }
}
