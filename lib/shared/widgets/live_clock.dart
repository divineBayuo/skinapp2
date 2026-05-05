import 'dart:async';

import 'package:flutter/material.dart';
import 'package:skinapp2/core/theme/app_theme.dart';

class LiveClock extends StatefulWidget {
  final TextStyle? style;
  const LiveClock({super.key, this.style});

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late DateTime _now;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Tick every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = _pad(_now.hour);
    final m = _pad(_now.minute);
    final s = _pad(_now.second);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$h\n$m',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 52,
            fontWeight: FontWeight.w900,
            color: AppColors.textNavy,
            height: 1.0,
            letterSpacing: -2,
          ),
        ),
        Text(s, style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.textNavy,
            height: 1.0,
            letterSpacing: -2,
          ),),
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
    );
  }
}
