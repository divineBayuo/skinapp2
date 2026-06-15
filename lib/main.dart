import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skinapp2/core/router/app_router.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/firebase_options.dart';
// import 'package:skinapp2/services/geocoding_retry_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // initialize app check before any other firebase service
  await FirebaseAppCheck.instance.activate(
    // using debug provider for emulators/dev builds
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity, // change to playIntegrity for release
    appleProvider: kDebugMode
        ? AppleProvider.debug
        : AppleProvider.deviceCheck, // change to deviceCheck for release
  );

  /* // start background geocoding retry - resolves community names
  // for records captured offline, runs silently in the background
  GeocodingRetryService().start(); */

  runApp(const ProviderScope(child: SkinNtdApp()));
}

class SkinNtdApp extends ConsumerWidget {
  const SkinNtdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SKiN NTD',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
