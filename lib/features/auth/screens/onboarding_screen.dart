// -----------------------
// ONBOARDING SCREEN
// -----------------------
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:skinapp2/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
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
                  GestureDetector(
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
