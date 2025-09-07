import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  final List<String> _icons = [
    'assets/icons/navbar/callLog.svg',
    'assets/icons/navbar/sms.svg',
    'assets/icons/navbar/spam.svg',
    'assets/icons/navbar/mail.svg',
    'assets/icons/navbar/user.svg',
  ];

  final List<String> _labels = [
    "Calls",
    "SMS",
    "Spams",
    "Mails",
    "Profile",
  ];

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: const Color.fromARGB(255, 29, 29, 29), // solid sticked background
      elevation: 8,
      child: SizedBox(
        height: 65, // height of navbar
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_icons.length, (index) {
            final isSelected = currentIndex == index;
            return GestureDetector(
              onTap: () => onItemSelected(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    _icons[index],
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      isSelected
                          ? const Color(0xFF7B52AE)
                          : Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _labels[index],
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  )
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}