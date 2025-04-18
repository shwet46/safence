import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:safence/utils/constants.dart';

class Page404 extends StatefulWidget {

  @override
  _Page404State createState() => _Page404State();
}

class _Page404State extends State<Page404> { 
  bool isAuth = true;

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
  return Scaffold(
    extendBodyBehindAppBar: true,
    backgroundColor: Constants.darkThemeBg,
    body: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        Text(
          '404',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 48,
            color: Constants.darkThemeFontColor,
            height: 1
          ),
        ),
        Text(
          'Sorry Page not found!',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            color: Constants.darkThemeFontColor,
            height: 1
          ),
        ),
      ],
    ),
  ),

  );
  
  }
}