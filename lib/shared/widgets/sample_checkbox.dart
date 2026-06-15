import 'package:flutter/material.dart';
import 'package:skinapp2/core/theme/app_theme.dart';

class SampleCheckbox extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool checked;
  final DateTime? checkedAt;
  final bool editable;
  final void Function(bool)? onChanged;

  const SampleCheckbox({
    super.key,
    required this.label,
    required this.sublabel,
    required this.checked,
    required this.checkedAt,
    required this.editable,
    required this.onChanged,
  });

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get _formattedTime {
    if (checkedAt == null) return '';
    final d = checkedAt!;
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month - 1]} ${d.year}  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // only respond to taps if editable and not already checked
      // once ticked it stays ticked
      onTap: (editable && !checked && onChanged != null)
          ? () => onChanged!(true)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: checked
              ? AppColors.success.withOpacity(0.08)
              : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: checked
                ? AppColors.success.withOpacity(0.4)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // checkbox circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: checked
                      ? AppColors.success
                      : editable
                      ? AppColors.textMid
                      : AppColors.textMid.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: checked
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: checked
                          ? AppColors.success
                          : editable
                          ? AppColors.textNavy
                          : AppColors.textMid.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    checked && checkedAt != null ? _formattedTime : sublabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: checked
                          ? AppColors.success.withOpacity(0.8)
                          : AppColors.textMid.withOpacity(editable ? 1.0 : 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // lock icon when not editable
            if (!editable)
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: AppColors.textMid.withOpacity(0.4),
              ),

            // tap hint when editable and not yet ticked
            if (editable && !checked)
              Icon(Icons.touch_app_rounded, size: 14, color: AppColors.textMid),
          ],
        ),
      ),
    );
  }
}
