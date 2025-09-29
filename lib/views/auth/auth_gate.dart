import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safence/views/auth/login.dart';
import 'package:safence/views/main/main_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _timeout = false;

  @override
  void initState() {
    super.initState();
    // Fallback: if auth stream doesn't emit quickly, show Login to avoid being stuck
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _timeout = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) return const HomeController();
        if (snapshot.connectionState == ConnectionState.waiting && !_timeout) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }
        return const LoginPage();
      },
    );
  }
}
