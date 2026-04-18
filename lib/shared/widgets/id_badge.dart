import 'package:flutter/material.dart';
import 'package:skinapp2/core/theme/app_theme.dart';

class PatientIdBadge extends StatelessWidget {
  final String idNumber;

  const PatientIdBadge({super.key, required this.idNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.navyLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ID No',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            idNumber,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textWhite,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
