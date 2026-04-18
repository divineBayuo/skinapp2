// -----------------------
// NTD INFO CARD
// -----------------------
import 'package:flutter/material.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/models/diagnosis.dart';

class NtdInfoCard extends StatelessWidget {
  final SkinNtdType type;
  final String description;

  const NtdInfoCard({super.key, required this.type, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type.label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textWhite.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
