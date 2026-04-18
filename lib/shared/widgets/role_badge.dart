// --------------------
// ROLE BADGE
// --------------------
import 'package:flutter/material.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/models/user.dart';

class RoleBadge extends StatelessWidget {
  final AccessRole role;
  final bool compact;
  const RoleBadge({super.key, required this.role, this.compact = false});

  Color get _color {
    switch (role) {
      case AccessRole.collector:
        return AppColors.roleCollector;
      case AccessRole.physician:
        return AppColors.rolePhysician;
      case AccessRole.researcher:
        return AppColors.roleResearcher;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}
