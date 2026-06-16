import 'package:flutter/material.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final double? height;
  final Function(String?) validator;
  final double? width;
  final String? hintText;

  const AppTextField({
    super.key,
    this.height,
    required this.controller,
    required this.keyboardType,
    required this.isPassword,
    required this.validator,
    this.width,
    this.hintText,
  });

  @override
  AppTextFieldState createState() => AppTextFieldState();
}

class AppTextFieldState extends State<AppTextField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? const Color(0xFF252525) : Colors.white;
    final hintColor = isDark ? const Color(0xFF666666) : ColorManager.lightGrey;
    final idleColor = isDark ? const Color(0xFF3A3A3A) : ColorManager.lightGrey;
    final textColor = isDark ? Colors.white : ColorManager.black;
    final iconColor = isDark ? const Color(0xFF666666) : ColorManager.lightGrey;

    return SizedBox(
      width: widget.width ?? double.infinity,
      child: FormField<String>(
        validator: (v) => widget.validator(v),
        builder: (FormFieldState<String> field) {
          final hasError = field.hasError;
          final hasValue = widget.controller.text.isNotEmpty;
          final isSuccess = hasValue && !hasError && field.value != null;

          final borderColor = hasError
              ? ColorManager.red
              : isSuccess
                  ? ColorManager.green
                  : idleColor;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                keyboardType: widget.keyboardType,
                controller: widget.controller,
                obscureText: widget.isPassword && !_isPasswordVisible,
                style: TextStyle(
                  color: textColor,
                  fontFamily: 'GeneralSans',
                  fontSize: 15,
                ),
                onChanged: (v) => field.didChange(v),
                minLines: 1,
                maxLines: widget.isPassword ? 1 : (widget.height != null ? null : 5),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyles.font15semiBold.copyWith(color: hintColor),
                  suffixIcon: _buildSuffixIcon(isSuccess, hasError, iconColor),
                  filled: true,
                  fillColor: bgColor,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: widget.height != null ? 0 : 16,
                  ),
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(width: 1.5, color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(width: 1.5, color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      width: 1.5,
                      color: hasError
                          ? ColorManager.red
                          : isDark
                              ? ColorManager.accent
                              : ColorManager.black,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(width: 1.5, color: ColorManager.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(width: 1.5, color: ColorManager.red),
                  ),
                ),
              ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 6),
                  child: Text(
                    field.errorText!,
                    style: const TextStyle(color: ColorManager.red, fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget? _buildSuffixIcon(bool isSuccess, bool hasError, Color iconColor) {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          size: 22,
          color: iconColor,
        ),
        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
      );
    } else if (isSuccess) {
      return Icon(Icons.check_circle, color: ColorManager.green, size: 22);
    } else if (hasError) {
      return Icon(Icons.error, color: ColorManager.red, size: 22);
    }
    return null;
  }
}
