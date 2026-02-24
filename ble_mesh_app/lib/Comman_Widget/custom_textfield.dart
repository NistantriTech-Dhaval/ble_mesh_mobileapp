import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:ntpl_ble_mesh_demo/constant/appColors.dart';
import 'package:ntpl_ble_mesh_demo/constant/assets_path.dart';

class CustomTextField extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final void Function(String?)? onChanged;
  final void Function(String?)? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixTap;
  final Color? fillColor;
  final bool filled;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? textStyle;
  final TextInputAction? textInputAction;
  final bool isPassword;
  final bool isRequired;
  final bool isvalidemail;
  /// Text field border colors
  final Color? borderColor;
  final Color? errorBorderColor;
  final double borderWidth;

  /// Filter icon and action
  final Widget? filterIcon;
  final VoidCallback? onFilterTap;

  /// Filter button customization
  final Color? filterBackgroundColor;
  final Color? filterBorderColor;
  final double filterBorderWidth;
  final double filterBorderRadius;
  final double filterSpacing;
  final double filterHeight;
  final double filterWidth;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    this.hintText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.isvalidemail=false,
    this.isPassword = false,
    this.isRequired = false,
    this.fillColor,
    this.filled = false,
    this.borderRadius = 8,
    this.contentPadding,
    this.textStyle,
    this.textInputAction,
    this.borderColor,
    this.errorBorderColor,
    this.borderWidth = 1,
    this.filterIcon,
    this.onFilterTap,
    this.filterBackgroundColor = Colors.white,
    this.filterBorderColor = Colors.red,
    this.filterBorderWidth = 1,
    this.filterBorderRadius = 8,
    this.filterSpacing = 8.0,
    this.filterHeight = 50,
    this.filterWidth = 50,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final _showPasswordNotifier = ValueNotifier<bool>(false);
    return ValueListenableBuilder(
        valueListenable: _showPasswordNotifier,
        builder: (BuildContext context, bool showPassword, child) {
      return  Row(
      children: [
        // Expanded text field
        Expanded(
          child: FormBuilderTextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword ? !showPassword : false,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: textInputAction,
            style: textStyle,

            inputFormatters: inputFormatters,
            validator:
            FormBuilderValidators.compose([
              if(isRequired==true)
                FormBuilderValidators.required(errorText: 'This Field is Required'),
              if(isvalidemail==true)
                FormBuilderValidators.email(errorText: 'Invalid Email Format'),
            ]),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: prefixIcon,
              suffixIcon: isPassword?
              Container(
                margin: const EdgeInsets.only(right: 10),
                child: IconButton(
                  icon: _showPasswordNotifier.value
                      ? Image.asset(
                    AssetsPath.eye_on_icon,
                    color: AppColors.gray,
                  )
                      : Image.asset(
                    AssetsPath.eye_off_icon,
                    color: AppColors.gray,
                  ),
                  onPressed: () {
                    _showPasswordNotifier.value =
                    !_showPasswordNotifier.value;
                  },
                ),
              )
                  :suffixIcon != null
                  ? GestureDetector(
                onTap: onSuffixTap,
                child: suffixIcon,
              )
                  : null,
              filled: filled,
              fillColor: fillColor,
              contentPadding: contentPadding,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: borderColor ?? Colors.grey,
                  width: borderWidth,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: borderColor ?? Colors.blue,
                  width: borderWidth,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: errorBorderColor ?? Colors.red,
                  width: borderWidth,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: errorBorderColor ?? Colors.red,
                  width: borderWidth,
                ),
              ),
            ), name: '',
          ),
        ),

        // Optional filter button
        if (filterIcon != null && onFilterTap != null) ...[
          SizedBox(width: filterSpacing),
          Container(
            height: filterHeight,
            width: filterWidth,
            decoration: BoxDecoration(
              color: filterBackgroundColor,
              border: Border.all(
                color: filterBorderColor ?? Colors.red,
                width: filterBorderWidth,
              ),
              borderRadius: BorderRadius.circular(filterBorderRadius),
            ),
            child: Center(
              child: GestureDetector(
                onTap: onFilterTap,
                child: filterIcon!,
              ),
            ),
          ),
        ],
      ],
    );});
  }
}
