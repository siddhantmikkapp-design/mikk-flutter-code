
import 'package:flutter/material.dart';
class CustomInkwell extends StatefulWidget {
  final Function onTap;
  final Widget? childWidget;
   const CustomInkwell({super.key,required this.onTap,this.childWidget});

  @override
  State<CustomInkwell> createState() => _CustomInkwellState();
}
class _CustomInkwellState extends State<CustomInkwell> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      onTap:() {
        widget.onTap();
      },
      child:widget.childWidget,
    );
  }
}

// class CustomInkWell{
//   static inkWell({required Function onTap,Widget? childWidget }){
//     return InkWell(
//       splashColor: Colors.transparent,
//       highlightColor: Colors.transparent,
//       hoverColor: Colors.transparent,
//       focusColor: Colors.transparent,
//       onTap:() {
//         onTap();
//       },
//       child:childWidget,
//     );
//   }
// }
