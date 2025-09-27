import 'package:flutter/material.dart';
import 'package:leafybot_flutter_app/Comman_Widget/custom_button.dart';

import '../constant/appColors.dart';

class SuccessPopup extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final String? imageAsset;
  final Color iconColor;
  final String buttonText;
  final VoidCallback onButtonPressed;

  const SuccessPopup({
    Key? key,
    required this.title,
    required this.message,
    this.icon,
    this.imageAsset,
    this.iconColor = Colors.green,
    this.buttonText = 'Continue',
    required this.onButtonPressed,
  })  : assert(icon != null || imageAsset != null,
  'Either icon or imageAsset must be provided'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.only(left: 22.0,right: 22,top: 30,bottom: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            if (icon != null)
              CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.1),
                radius: 30,
                child: Icon(icon, color: iconColor, size: 40),
              ),
            if (imageAsset != null)
              CircleAvatar(
                backgroundColor: Colors.transparent,
                radius: 30,
                child: Image.asset(
                  imageAsset!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 18,
                letterSpacing: 0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 18,
                letterSpacing: 0,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(text: buttonText, onPressed: onButtonPressed)
          ],
        ),
      ),
    );
  }
}
