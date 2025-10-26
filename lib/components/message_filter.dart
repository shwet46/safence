import 'package:flutter/material.dart';
import 'package:safence/models/message_category.dart';

typedef CategoryChanged = void Function(MessageCategory);

class MessageFilter extends StatefulWidget {
  final MessageCategory selectedCategory;
  final CategoryChanged onCategoryChanged;

  const MessageFilter({super.key, required this.selectedCategory, required this.onCategoryChanged});

  @override
  State<MessageFilter> createState() => _MessageFilterState();
}

class _MessageFilterState extends State<MessageFilter> {
  bool _open = false;

  String _labelFor(MessageCategory c) {
    switch (c) {
      case MessageCategory.spam:
        return 'Spam';
      case MessageCategory.important:
        return 'Important';
      case MessageCategory.regular:
        return 'Regular';
      default:
        return 'All Messages';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: GestureDetector(
            onTap: () => setState(() => _open = !_open),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8952D4), Color(0xFF6B3DB0)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.tune, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _labelFor(widget.selectedCategory),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
        if (_open)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _optionRow(MessageCategory.all, 'All Messages'),
                _optionRow(MessageCategory.spam, 'Spam', Color(0xFFE25C5C)),
                _optionRow(MessageCategory.important, 'Important', Color(0xFFE9AD40)),
                _optionRow(MessageCategory.regular, 'Regular'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _optionRow(MessageCategory c, String label, [Color? color]) {
    final selected = widget.selectedCategory == c;
    return InkWell(
      onTap: () {
        widget.onCategoryChanged(c);
        setState(() => _open = false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF333333), width: 0.5))),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? const Color(0xFF8952D4) : Colors.grey, size: 18),
            const SizedBox(width: 10),
            if (color != null) ...[
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
            ],
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}