// ----------------------------
// DATE/TIME WELCOME CARD
// ----------------------------
import 'package:flutter/material.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/shared/widgets/live_clock.dart';

class DatetimeWelcomeCard extends StatelessWidget {
  const DatetimeWelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    //final hour = now.hour.toString().padLeft(2, '0');
    //final min = now.minute.toString().padLeft(2, '0');
    final month = months[now.month - 1];
    final day = days[now.weekday - 1];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.fieldBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Time column
          Expanded(
            child: LiveClock() /* Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$hour\n$min',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textNavy,
                    height: 1.0,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Today',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMid,
                  ),
                ),
              ],
            ), */
          ),
          // Date Column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  month,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                now.day.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textNavy,
                  height: 1.0,
                  letterSpacing: -2,
                ),
              ),
              Text(
                day,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMid,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
