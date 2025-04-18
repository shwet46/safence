import 'package:flutter/material.dart';
import 'package:safence/providers/authProvider.dart';
import 'package:safence/splash.dart';
import 'package:safence/utils/orientation.dart';
import 'package:provider/provider.dart';
// import 'package:gradegenius/utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setOrientation();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safence',
      debugShowCheckedModeBanner: false,
      home:SplashScreen()
    );
  }
}