import 'package:flutter/material.dart';

class SettingsModel {
  double size;
  String image;
  IconData? icon;
  String txt;
  Widget? redirectTo;
  String url;
  String share;
  SettingsModel({this.icon, required this.txt, this.image = "", this.size = 30.0,this.redirectTo,this.url = "",this.share =""});
}
