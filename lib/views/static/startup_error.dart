import 'package:flutter/material.dart';

class StartupErrorScreen extends StatelessWidget {
  final List<String> messages;
  const StartupErrorScreen({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Configuration error', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Fix the issues below and restart the app:', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: messages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => Text('• ${messages[i]}', style: const TextStyle(color: Colors.redAccent)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
