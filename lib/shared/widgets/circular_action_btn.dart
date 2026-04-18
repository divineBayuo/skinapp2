// -------------------------------
// CIRCULAR ACTION BTN
// -------------------------------
import 'package:flutter/material.dart';
import 'package:skinapp2/core/theme/app_theme.dart';

class CircularActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? bgColor;
  final Color? iconColor;
  final double size;

  const CircularActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.bgColor,
    this.iconColor,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.navy,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (bgColor ?? AppColors.navy).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: size * 0.42,
          color: iconColor ?? AppColors.textWhite,
        ),
      ),
    );
  }
}
