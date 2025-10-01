import 'package:flutter/material.dart';
import 'package:leafybot_flutter_app/constant/appColors.dart';

/// Reusable circular progress indicator widget
class CircularProgressLoader extends StatelessWidget {
  final double size; // diameter of the circle
  final Color? color; // color of the loader
  final Color? backgroundcolor; // color of the loader
  final double strokeWidth; // thickness of the circle

  const CircularProgressLoader({
    Key? key,
    this.size = 24,
    this.color,
    this.backgroundcolor = AppColors.white,
    this.strokeWidth = 3.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            backgroundColor: backgroundcolor,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.green,
            ),
          ),
        ),
      ),
    );
  }
}
