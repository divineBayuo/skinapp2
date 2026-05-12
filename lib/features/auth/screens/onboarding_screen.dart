// -----------------------
// ONBOARDING SCREEN
// -----------------------
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:skinapp2/core/theme/app_theme.dart';

class _SlideToStart extends StatefulWidget {
  final VoidCallback onSlideComplete;
  const _SlideToStart({required this.onSlideComplete});

  @override
  State<_SlideToStart> createState() => __SlideToStartState();
}

class __SlideToStartState extends State<_SlideToStart>
    with SingleTickerProviderStateMixin {
  double _dragPos = 0;
  bool _completed = false;
  late double _trackWidth;

  static const double _thumbSize = 52;
  static const double _trackHeight = 60;
  static const double _threshold = 0.85;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        _trackWidth = constraints.maxWidth;
        final maxDrag = _trackWidth - _thumbSize - 8;
        final progress = (_dragPos / maxDrag).clamp(0.0, 1.0);

        return GestureDetector(
          onHorizontalDragUpdate: _completed
              ? null
              : (d) {
                  setState(() {
                    _dragPos = (_dragPos + d.delta.dx).clamp(0, maxDrag);
                  });
                  if (_dragPos / maxDrag >= _threshold && !_completed) {
                    setState(() => _completed = true);
                    HapticFeedback.mediumImpact();
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      widget.onSlideComplete,
                    );
                  }
                },
          onHorizontalDragEnd: _completed
              ? null
              : (_) {
                  setState(() => _dragPos = 0);
                },
          child: Container(
            height: _trackHeight,
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // fading as thumb moves right
                Center(
                  child: AnimatedOpacity(
                    opacity: (1 - progress * 2).clamp(0.0, 1.0),
                    duration: Duration.zero,
                    child: const Text(
                      'Slide to get started',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
                // draggable thumb
                AnimatedPositioned(
                  duration: _completed
                      ? const Duration(milliseconds: 250)
                      : Duration.zero,
                  curve: Curves.easeOut,
                  left: _completed
                      ? _trackWidth - _thumbSize - 4
                      : _dragPos + 4,
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: const BoxDecoration(
                      color: AppColors.navy,
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _completed
                          ? const Icon(
                              Icons.check_rounded,
                              key: ValueKey('check'),
                              color: AppColors.teal,
                              size: 22,
                            )
                          : const Icon(
                              Icons.arrow_forward_rounded,
                              key: ValueKey('arrow'),
                              color: AppColors.teal,
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A1628),
                  Color(0xFF071232),
                  Color(0xFF030A1A),
                ],
              ),
            ),
          ),
          // DNA visual (particle glow)
          Positioned(
            top: 0,
            left: 0,
            bottom: 200,
            child: SizedBox(
              //height: MediaQuery.of(context).size.height * 0.52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow
                  Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00D4FF).withOpacity(0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // DNA icon
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF1A4FA0).withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.hub_rounded,
                      size: 80,
                      color: Color(0xFF5CD8F0),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).size.height * 0.4),

          // Bottom content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 36,
                        height: 1.15,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: 'Take care of\nyour health\n',
                          style: TextStyle(fontWeight: FontWeight.w400),
                        ),
                        TextSpan(
                          text: 'in time',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Get started!
                  /* GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppColors.navy,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.teal,
                              size: 20,
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              'Get Started!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 52),
                        ],
                      ),
                    ),
                  ), */
                  _SlideToStart(onSlideComplete: () =>context.go('/login'))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
