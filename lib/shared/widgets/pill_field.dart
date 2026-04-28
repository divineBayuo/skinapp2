// --------------------------
// PILL FIELD
// --------------------------
import 'package:flutter/material.dart';
import 'package:skinapp2/core/theme/app_theme.dart';

class PillField extends StatelessWidget {
  final String? hint;
  final String? label;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final bool enabled;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  const PillField({
    super.key,
    this.hint,
    this.label,
    this.controller,
    this.suffixIcon,
    this.prefixIcon,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.textInputAction,
    this.enabled = true,
    this.obscureText = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      textInputAction: textInputAction,
      enabled: enabled,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textNavy,
      ),
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      ),
      obscureText: obscureText,
      onChanged: onChanged,
    );
  }
}

// --------------------------
// PILL FIELD LABEL ROW
// --------------------------
class LabeledPillField extends StatelessWidget {
  final String label;
  final Widget field;

  const LabeledPillField({super.key, required this.label, required this.field});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMid,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 5),
        field,
      ],
    );
  }
}
