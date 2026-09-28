import 'package:flutter/material.dart';
import 'package:mikk/resources/Custom_InkWell.dart';
import 'package:mikk/utils/CommonMethods.dart';
import 'package:mikk/values/AppFontStyleAndSize.dart';

import '../values/Color.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final Color fieldColor;
  final Color textFieldInputColor;
  final TextStyle? hintStyle;
  final bool showBorder;
  final bool isEnable;
  final TextEditingController? controller;
  final String? labelText;
  final String? errorText;
  final Color? borderColor;
  final EdgeInsets? padding;
  final Icon? suffixIcon;
  final Icon? prefixIcon;
  final Function? onSuffix;
  final Function(dynamic value)? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool obscureText;
  final Color? hintColor;
  final Color? labelColor;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.hintText,
    required this.fieldColor,
    this.hintStyle,
    this.showBorder = false,
    this.isEnable = true,
    this.controller,
    this.labelText = '',
    this.errorText = '',
    this.textFieldInputColor = Colors.black,
    this.borderColor,
    this.padding,
    this.suffixIcon,
    this.prefixIcon,
    this.onSuffix,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.obscureText = false,
    this.hintColor,
    this.labelColor,
    this.keyboardType,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.fieldColor,
          ),
          child: TextFormField(
            controller: widget.controller,
            enabled: widget.isEnable,
            readOnly: widget.readOnly,
            obscureText: _isObscured,
            textAlign: TextAlign.start,
            textAlignVertical: TextAlignVertical.center,
            onTap: widget.onTap,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: widget.textFieldInputColor,
              letterSpacing: 0.3,
            ),
            onChanged: (value) {
              if (widget.onChanged != null) {
                widget.onChanged!(value);
              }
            },
            decoration: InputDecoration(
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.obscureText
                  ? IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: widget.textFieldInputColor.withOpacity(0.6),
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
              )
                  : widget.suffixIcon,
              labelText: widget.labelText!.isNotEmpty ? widget.labelText : null,
              labelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: widget.labelColor ?? Colors.grey,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: widget.hintColor ?? widget.textFieldInputColor.withOpacity(0.4),
                letterSpacing: 0.3,
              ),
              fillColor: widget.fieldColor,
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.transparent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor2.withOpacity(0.3), width: 1),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red),
              ),
              contentPadding: widget.padding ?? EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              isDense: true,
            ),
          ),
        ),
        if (widget.errorText!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16, top: 6),
            child: Text(
              widget.errorText.toString(),
              style: TextStyle(
                color: Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}
