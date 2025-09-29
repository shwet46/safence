import 'package:flutter/material.dart';
import 'package:safence/utils/constants.dart';

class Page404 extends StatefulWidget {
  final String pageName;
  const Page404({super.key, required this.pageName});


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
      children: [
        Text(
          '${widget.pageName} Page',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            color: Constants.darkThemeFontColor,
            height: 1
          ),
        ),
        const Text(
          'is under progress',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            color: Constants.darkThemeFontColor,
            height: 1.5
          ),
        ),
      ],
    ),
  ),
  );
}
}