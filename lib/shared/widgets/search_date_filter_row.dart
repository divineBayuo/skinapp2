// -------------------------
// SEARCH + DATE FILTER ROW
// -------------------------

import 'package:flutter/material.dart';
import 'package:skinapp2/core/theme/app_theme.dart';

class SearchDateRow extends StatelessWidget {
  final TextEditingController searchCtrl;
  final VoidCallback onDateTap;
  final String? selectedDate;

  const SearchDateRow({
    super.key,
    required this.searchCtrl,
    required this.onDateTap,
    this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bgWhite,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppColors.fieldBg, width: 1.5),
            ),
            child: TextField(
              controller: searchCtrl,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textNavy,
              ),
              decoration: const InputDecoration(
                hintText: 'Search name / ID',
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onDateTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.bgWhite,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppColors.fieldBg, width: 1.5),
            ),
            child: Row(
              children: [
                Text(
                  selectedDate ?? 'Choose Date',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selectedDate != null
                        ? AppColors.textNavy
                        : AppColors.textHint,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.textMid,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
