import 'package:flutter/material.dart';

import 'GradientDirection.dart';
// import 'package:simple_gradient_text/src/constants.dart';

/// A gradient text.
class GradientImage extends StatelessWidget {
  /// Colors used to show the gradient.
  final List<Color> colors;

  /// Direction in which the gradient will be displayed.
  final GradientDirection gradientDirection;

  /// The type of gradient to apply.
  final GradientType gradientType;

  /// The radius of the gradient, as a fraction of the shortest side
  /// of the paint box.
  final double radius;

  final String? image;
  final double? height;
  final BoxFit? fit;

  const GradientImage(
      String this.image,
      {
        required this.colors,
        this.gradientDirection = GradientDirection.ltr,
        this.gradientType = GradientType.linear,
        Key? key,
        this.radius = 1.0, this.height, this.fit,
      })  : assert(
  colors.length >= 2,
  'Colors list must have at least two colors',
  ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: _createShader,
      child: Image.asset(
        image!,
        // ImageSrc.gif_gif,
        height: height,
        fit: fit,
        // color: primaryColor1,
      ),
      /*Text(
        text,
        overflow: overflow,
        style: _style,
        textAlign: textAlign,
      ),*/
    );
  }

  Alignment _direction(String key) {
    final Map<String, Alignment> map = {};
    switch (gradientDirection) {
      case GradientDirection.rtl:
        map['begin'] = Alignment.centerRight;
        map['end'] = Alignment.centerLeft;
        break;
      case GradientDirection.ttb:
        map['begin'] = Alignment.topCenter;
        map['end'] = Alignment.bottomCenter;
        break;
      case GradientDirection.btt:
        map['begin'] = Alignment.bottomCenter;
        map['end'] = Alignment.topCenter;
        break;
      default:
        map['begin'] = Alignment.centerLeft;
        map['end'] = Alignment.centerRight;
        break;
    }
    return map[key]!;
  }

  Shader _createShader(Rect bounds) {
    switch (gradientType) {
      case GradientType.radial:
        return _radialGradient.createShader(bounds);
      default:
        return _linearGradient.createShader(bounds);
    }
  }

  Gradient get _linearGradient {
    return LinearGradient(
      begin: _direction('begin'),
      colors: colors,
      end: _direction('end'),
    );
  }

  Gradient get _radialGradient {
    return RadialGradient(
      colors: colors,
      radius: radius,
    );
  }

}
