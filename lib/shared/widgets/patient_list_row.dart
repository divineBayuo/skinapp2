import 'package:flutter/material.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/models/patient.dart';

class PatientListRow extends StatelessWidget {
  final PatientRecord patient;
  final VoidCallback onTap;
  final bool showTimestamp;

  const PatientListRow({
    super.key,
    required this.patient,
    required this.onTap,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.fieldBg,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                patient.fullName,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textNavy,
                ),
              ),
            ),
            Text(
              patient.formattedTimestamp,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
