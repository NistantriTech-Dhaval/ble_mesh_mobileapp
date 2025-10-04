import 'package:flutter/material.dart';
import 'package:leafybot_flutter_app/constant/appColors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final double height;
  final double width;
  final IconData? icon; // ✅ optional material icon
  final String? assetPath; // ✅ optional asset image path
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor =  AppColors.darkgreen,
    this.height = 48,
    this.width= double.infinity,
    this.icon,
    this.assetPath,
    this.borderRadius = 8,
  }) : assert(
  icon == null || assetPath == null,
  'You can only provide either icon OR assetPath, not both.',
  );

  @override
  Widget build(BuildContext context) {
    Widget? leadingIcon;

    if (icon != null) {
      leadingIcon = Icon(icon, size: 20, color: AppColors.white);
    } else if (assetPath != null) {
      leadingIcon = Image.asset(assetPath!, height: 24, width: 24,color: AppColors.white,);
    }
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              leadingIcon,
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
