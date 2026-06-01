import 'package:flutter/material.dart';

class MyPainter extends CustomPainter {
  MyPainter(this.size);

  final Size size;

  @override
  void paint(Canvas canvas, Size size) {
    // SVG rendering is handled by SvgPicture.string with flutter_svg 2.x.
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
