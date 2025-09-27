import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leafybot_flutter_app/constant/appColors.dart';

import '../constant/assets_path.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? imagePath; // <-- for logo
  final String? backButtonPath;
  final bool showBack;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? iconColor; // can override, but defaults auto
  final List<Widget>? actions;
  final VoidCallback? onBack; // ✅ new

  const CustomAppBar({
    super.key,
    this.title,
    this.centerTitle = true,
    this.backButtonPath = AssetsPath.backButton,
    this.imagePath,
    this.showBack = true,
    this.backgroundColor,
    this.iconColor,
    this.actions,
    this.onBack, // ✅ new
  });

  @override
  Widget build(BuildContext context) {
    // If no explicit color given → auto based on theme brightness
    final Color resolvedIconColor = iconColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF0D0D2B));
    final Color? titleImageColor =
    Theme.of(context).brightness == Brightness.dark ? Colors.white : null;

    return AppBar(
      elevation: 0,
      backgroundColor:
      backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      automaticallyImplyLeading: false,
      bottom: centerTitle==false?PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: AppColors.grayLight, // customize color
        ),
      ):null,
      titleSpacing: 10, // ✅ force title to start right after leading
      leading: showBack
          ? Padding(
            padding: const EdgeInsets.only(left: 10),
            child: IconButton(
                    icon: Image.asset(
            backButtonPath!,
            height: 30,
            color: resolvedIconColor,
                    ),
                    onPressed: onBack ?? () => Get.back(), // ✅ dynamic back
                  ),
          )
          : null,
      title: imagePath != null
          ? Image.asset(
        imagePath!,
        color: titleImageColor,
        height: 30,
      )
          : (title != null
          ? Text(
        title!,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          letterSpacing: 0,
          fontWeight: FontWeight.w600,
        ),
      )
          : null),
      centerTitle: centerTitle,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
