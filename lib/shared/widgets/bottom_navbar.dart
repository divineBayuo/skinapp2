// ----------------
// BOTTOM NAV BAR
// ----------------

import 'package:flutter/material.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/models/user.dart';

class SkinNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final AccessRole role;

  const SkinNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            index: 0,
            current: currentIndex,
            onTap: onTap,
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            index: 1,
            current: currentIndex,
            onTap: onTap,
          ),
          _NavItem(
            icon: Icons.description_outlined,
            index: 2,
            current: currentIndex,
            onTap: onTap,
          ),
          _NavItem(
            icon: Icons.folder_outlined,
            index: 3,
            current: currentIndex,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Icon(
          icon,
          size: 24,
          color: selected ? AppColors.teal : AppColors.navy,
        ),
      ),
    );
  }
}
