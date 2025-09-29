import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:safence/views/main/main_page.dart';
import 'package:safence/views/static/loading.dart';

class SplashScreen extends StatefulWidget{
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>{

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const HomeController()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context){
    return const LoadingScreen();
  }
}