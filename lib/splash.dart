import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:safence/providers/authProvider.dart';
import 'package:safence/views/auth/home.dart';
import 'package:safence/views/main/main_page.dart';
import 'package:safence/views/static/loading.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget{
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>{

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Timer(Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => authProvider.isAuthenticated ? HomeController() : HomePage()),
        );
      }
    });
  }


  @override
  Widget build(BuildContext context){
    return LoadingScreen();
  }
}