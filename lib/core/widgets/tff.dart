import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      width: widget.width ?? size.width * 0.9,
      child: FormField<String>(
        validator: (value) {
          return widget.validator(value);
        },
        builder: (FormFieldState<String> field) {
          // Determine the state
          bool hasError = field.hasError;
          bool hasValue = widget.controller.text.isNotEmpty;
          bool isSuccess = hasValue && !hasError && field.value != null;

          // Determine border color
          Color borderColor = hasError
              ? Colors.red
              : isSuccess
                  ? Colors.green
                  : ColorManager.lightGrey;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: widget.height ?? 55.h,
                decoration: ShapeDecoration(
                  color: ColorManager.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: borderColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: TextFormField(
                  keyboardType: widget.keyboardType,
                  controller: widget.controller,
                  obscureText: widget.isPassword && !_isPasswordVisible,
                  onChanged: (value) {
                    field.didChange(value);
                  },
                  minLines: widget.isPassword ? 1 : (widget.height != null ? null : 1),
                  maxLines: widget.isPassword ? 1 : (widget.height != null ? null : 5),
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyles.font15semiBold.copyWith(
                      color: ColorManager.lightGrey,
                    ),
                    suffixIcon: _buildSuffixIcon(isSuccess, hasError),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: widget.height == null ? 15 : 0,
                    ),
                    errorStyle: const TextStyle(height: 0),
                  ),
                ),
              ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Text(
                    field.errorText!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget? _buildSuffixIcon(bool isSuccess, bool hasError) {
    if (widget.isPassword) {
      // Password field always shows visibility toggle
      return IconButton(
        icon: Icon(
          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          size: 25,
          color: ColorManager.lightGrey,
        ),
        onPressed: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
      );
    } else if (isSuccess) {
      // Success state: show green checkmark
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 25,
      );
    } else if (hasError) {
      // Error state: show red error icon (optional)
      return const Icon(
        Icons.error,
        color: Colors.red,
        size: 25,
      );
    }
    return null;
  }
}