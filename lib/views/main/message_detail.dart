import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safence/models/message_category.dart';

class MessageDetailScreen extends StatelessWidget {
  final String sender;
  final String content;
  final String time;
  final bool isYesterday;
  final MessageCategory category;

  const MessageDetailScreen({
    super.key,
    required this.sender,
    required this.content,
    required this.time,
    required this.isYesterday,
    required this.category,
  });

  Color _categoryColor() {
    switch (category) {
      case MessageCategory.spam:
        return const Color(0xFFE25C5C);
      case MessageCategory.important:
        return const Color(0xFFE9AD40);
      default:
        return const Color(0xFF2A2A2A);
    }
  }

  String _categoryLabel() {
    switch (category) {
      case MessageCategory.spam:
        return 'Spam';
      case MessageCategory.important:
        return 'Important';
      default:
        return 'Regular';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        title: Text(sender, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied'), duration: Duration(seconds: 1)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
            },
          ),
        ],
      ),
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 16, 16, 46),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0B0B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF222222)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF2A2A2A),
                    child: Text(sender.isNotEmpty ? sender[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sender, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(time, style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 12)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _categoryColor(),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(_categoryLabel(), style: TextStyle(color: category == MessageCategory.regular ? Colors.white70 : Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Divider(color: Color(0xFF222222)),
            const SizedBox(height: 12),
            // Message content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SelectableText(content, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4)),
              ),
            ),
            const SizedBox(height: 18),
            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF222222), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: content));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied'), duration: Duration(seconds: 1)));
                    },
                    icon: const Icon(Icons.copy, color: Colors.white70),
                    label: const Text('Copy', style: TextStyle(color: Colors.white70)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8952D4), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      // placeholder for reply action
                    },
                    icon: const Icon(Icons.reply, color: Colors.white),
                    label: const Text('Reply', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}