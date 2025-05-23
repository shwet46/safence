import 'package:flutter/material.dart';
import 'package:safence/components/bottomnav.dart';
import 'package:safence/utils/constants.dart';
import 'package:safence/views/main/mails.dart';
import 'package:safence/views/main/messages.dart';
import 'package:safence/views/main/calls.dart';
import 'package:safence/views/static/page404.dart';

class HomeController extends StatefulWidget {
  const HomeController({super.key});

  @override
  State<HomeController> createState() => _HomeControllerState();
}

class _HomeControllerState extends State<HomeController> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  List<Widget> get _pages => [
    CallsPage(),
    MessagesScreen(),
    Page404(),
    MailsPage(),
    Page404(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // void _onItemTapped(int index) {
  //   if (index != _selectedIndex) {
  //     setState(() {
  //       _selectedIndex = index;
  //     });
  //     _pageController.jumpToPage(index);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.darkThemeBg,
      body: Stack(
        children: [
          _pages[_selectedIndex],
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CustomBottomNav(
                  currentIndex: _selectedIndex,
                  onItemSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}