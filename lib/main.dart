import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:io' show File;
import 'package:safence/providers/authProvider.dart';
import 'package:safence/providers/firebase_auth_provider.dart';
import 'package:safence/views/auth/auth_gate.dart';
import 'package:safence/utils/orientation.dart';
import 'package:provider/provider.dart';
import 'package:safence/views/static/startup_error.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final missing = <String>[];
  // If Firebase is already initialized (e.g., Android auto-init via provider),
  // skip enforcing .env presence to avoid false "config error" screens.
  final alreadyInitialized = Firebase.apps.isNotEmpty;
  final willManualInit = kIsWeb || !alreadyInitialized;

  if (willManualInit) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      for (final k in [
        'FIREBASE_ANDROID_API_KEY',
        'FIREBASE_ANDROID_APP_ID',
        'FIREBASE_ANDROID_PROJECT_ID',
        'FIREBASE_ANDROID_MESSAGING_SENDER_ID',
      ]) {
        if ((dotenv.env[k] ?? '').isEmpty) missing.add('$k is missing in .env');
      }
    }
    if (kIsWeb) {
      for (final k in [
        'FIREBASE_WEB_API_KEY',
        'FIREBASE_WEB_APP_ID',
        'FIREBASE_WEB_PROJECT_ID',
        'FIREBASE_WEB_MESSAGING_SENDER_ID',
      ]) {
        if ((dotenv.env[k] ?? '').isEmpty) missing.add('$k is missing in .env');
      }
    }
  }

  Widget appWidget;
  bool firebaseReady = false;
  // If .env values are missing we can still attempt to initialize using native
  // platform configuration (google-services.json / GoogleService-Info.plist) when
  // available. This makes local/dev runs easier for people who configured native
  // files but don't use .env.
  if (missing.isNotEmpty) {
    debugPrint('Warning: missing .env values: ${missing.join(', ')}');
    // Heuristic: if native Android or iOS config files exist, try init without options.
    final hasNativeAndroid = File('android/app/google-services.json').existsSync();
    final hasNativeIos = File('ios/Runner/GoogleService-Info.plist').existsSync();
    try {
      if (willManualInit) {
        if (kIsWeb) {
          // On web we need explicit options; fall through to error below.
          throw StateError('Missing web .env config');
        }
        if (hasNativeAndroid || hasNativeIos) {
          // Initialize using native config bundled in the platform project.
          await Firebase.initializeApp();
        } else {
          // No native files and no .env -> fail fast.
          appWidget = StartupErrorScreen(messages: missing);
          // Skip the rest and show the error screen.
          setOrientation();
          runApp(MaterialApp(debugShowCheckedModeBanner: false, home: appWidget));
          return;
        }
      }
      firebaseReady = true;
      appWidget = const MyApp();
    } catch (e, st) {
      debugPrint('Firebase init failed: $e\n$st');
      appWidget = StartupErrorScreen(messages: [
        'Firebase initialization failed:',
        e.toString(),
        'Check that your .env values match the registered Firebase app (package/bundle ID) or that native config files are present.',
      ]);
    }
  } else {
    try {
      // Only initialize manually if not already initialized (prevents duplicate DEFAULT app).
      if (willManualInit) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      firebaseReady = true;
      appWidget = const MyApp();
    } catch (e, st) {
      debugPrint('Firebase init failed: $e\n$st');
      appWidget = StartupErrorScreen(messages: [
        'Firebase initialization failed:',
        e.toString(),
        'Check that your .env values match the registered Firebase app (package/bundle ID).',
      ]);
    }
  }
  setOrientation();

  if (!firebaseReady) {
    // Run minimal app without Firebase-dependent providers to avoid crashes
    runApp(MaterialApp(debugShowCheckedModeBanner: false, home: appWidget));
    return;
  }

  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FirebaseAuthProvider()),
      ],
      child: appWidget));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safence',
      debugShowCheckedModeBanner: false,
      home: const AuthGate()
    );
  }
}