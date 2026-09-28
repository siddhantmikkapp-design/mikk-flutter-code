import 'package:flutter/material.dart';

class GlobalListModel {
  double iconSize;
  String image;
  IconData? icon;
  String title;
  String subTitle;
  final Function? onTap;

  GlobalListModel({
    this.icon,
    required this.title,
    this.subTitle = "",
    this.image = "",
    this.iconSize = 20.0,
    this.onTap
  });
}
