import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show EventChannel;
import 'package:safence/models/message_category.dart';
import 'package:safence/components/message_filter.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:safence/views/main/message_detail.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const MessagesApp());
}

class MessagesApp extends StatelessWidget {
  const MessagesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const MessagesScreen(),
    );
  }
}

class MessageData {
  final String sender;
  final String content;
  final String time;
  final bool isYesterday;
  final MessageCategory category;

  MessageData({
    required this.sender,
    required this.content,
    required this.time,
    required this.isYesterday,
    required this.category,
  });

  Color get senderColor {
    switch (category) {
      case MessageCategory.spam:
        return Color(0xFFE25C5C);
      case MessageCategory.important:
        return Color(0xFFE9AD40);
      default:
        return Colors.white;
    }
  }
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  MessageCategory _selectedCategory = MessageCategory.all;
  bool _isFilterMenuOpen = false;
  String _searchQuery = '';
  late final SmsQuery _smsQuery;
  static const EventChannel _smsStream = EventChannel('safence/sms_stream');
  final List<MessageData> _allMessages = [];

  @override
  void initState() {
    super.initState();
    _initSms();
  }

  // Background handler must be a top-level or static function. We only use foreground here.
  Future<void> _initSms() async {
    _smsQuery = SmsQuery();
    // Request SMS permission at runtime
    final granted = await _ensureSmsPermission();
    if (!mounted) return;
    if (granted) {
      await _loadInbox();
      _listenIncoming();
    }
  }

  Future<bool> _ensureSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<void> _loadInbox() async {
    try {
      final List<SmsMessage> inbox = await _smsQuery.querySms(
        kinds: [SmsQueryKind.inbox],
        sort: true,
      );
      final now = DateTime.now();
      final mapped = inbox.map((m) {
  final dt = m.date ?? now;
        final today = DateTime(now.year, now.month, now.day);
        final yday = today.subtract(const Duration(days: 1));
        final isYesterday = dt.isAfter(yday) && dt.isBefore(today);
        return MessageData(
          sender: m.address ?? 'Unknown',
          content: m.body ?? '',
          time: _formatTime(dt, now),
          isYesterday: isYesterday,
          category: _categorize(m),
        );
      }).toList();
      setState(() {
        _allMessages
          ..clear()
          ..addAll(mapped);
      });
    } catch (e) {
      // ignore errors silently or show a toast/snackbar in future
    }
  }

  void _listenIncoming() {
    _smsStream.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final now = DateTime.now();
        final dt = DateTime.fromMillisecondsSinceEpoch((event['timestamp'] as num?)?.toInt() ?? now.millisecondsSinceEpoch);
        final data = MessageData(
          sender: (event['address'] as String?) ?? 'Unknown',
          content: (event['body'] as String?) ?? '',
          time: _formatTime(dt, now),
          isYesterday: false,
          category: _categorizeFromText((event['address'] as String?) ?? '', (event['body'] as String?) ?? ''),
        );
        if (!mounted) return;
        setState(() {
          _allMessages.insert(0, data);
        });
      }
    });
  }

  MessageCategory _categorizeFromText(String address, String body) {
    final sender = address.toLowerCase();
    final b = body.toLowerCase();
    if (b.contains('otp') || b.contains('one time') || b.contains('verification')) return MessageCategory.important;
    if (sender.contains('bank') || b.contains('credited') || b.contains('debited') || b.contains('payment')) return MessageCategory.important;
    if (b.contains('win') || b.contains('prize') || b.contains('lottery') || b.contains('urgent') || b.contains('click here')) return MessageCategory.spam;
    return MessageCategory.regular;
  }

  String _formatTime(DateTime dt, DateTime now) {
    final difference = now.difference(dt);
    if (difference.inDays >= 2) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
  }

  MessageCategory _categorize(SmsMessage m) {
    final sender = (m.address ?? '').toLowerCase();
    final body = (m.body ?? '').toLowerCase();
    // naive heuristics; you can wire to backend later
    if (body.contains('otp') || body.contains('one time') || body.contains('verification')) {
      return MessageCategory.important;
    }
    if (sender.contains('bank') || body.contains('credited') || body.contains('debited') || body.contains('payment')) {
      return MessageCategory.important;
    }
    if (body.contains('win') || body.contains('prize') || body.contains('lottery') || body.contains('urgent') || body.contains('click here')) {
      return MessageCategory.spam;
    }
    return MessageCategory.regular;
  }

  List<MessageData> get _filteredMessages {
    Iterable<MessageData> list = _allMessages;
    if (_selectedCategory != MessageCategory.all) {
      list = list.where((m) => m.category == _selectedCategory);
    }
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((m) =>
          m.sender.toLowerCase().contains(q) || (m.content.toLowerCase().contains(q)));
    }
    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 80.0),
          child: Column(
            children: [
              _buildSearchBar(),
              MessageFilter(selectedCategory: _selectedCategory, onCategoryChanged: (c) => setState(() => _selectedCategory = c)),
              _buildMessagesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: "Search messages...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            const Icon(Icons.more_vert, color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }

  

  Widget _buildMessagesList() {
    final messages = _filteredMessages;
    if (messages.isEmpty) {
      return const Expanded(child: Center(child: Text('No messages in this category', style: TextStyle(color: Colors.grey))));
    }

    // Group messages into Today / Yesterday / Older
    final Map<String, List<MessageData>> groups = {'Today': [], 'Yesterday': [], 'Older': []};
    for (final m in messages) {
      if (m.isYesterday) {
        groups['Yesterday']!.add(m);
      } else {
        if (m.time == 'Yesterday') {
          groups['Yesterday']!.add(m);
        } else {
          final isToday = RegExp(r"^\d{2}:\d{2}").hasMatch(m.time);
          if (isToday) {
            groups['Today']!.add(m);
          } else {
            groups['Older']!.add(m);
          }
        }
      }
    }

    final sectionOrder = ['Today', 'Yesterday', 'Older'];

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sectionOrder.fold<int>(0, (acc, key) => acc + (groups[key]!.isEmpty ? 0 : groups[key]!.length + 1)),
        itemBuilder: (context, index) {
          // iterate through sections to find which section and which item
          int cursor = 0;
          for (final section in sectionOrder) {
            final list = groups[section]!;
            if (list.isEmpty) continue;
            // header
            if (index == cursor) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Text(section, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              );
            }
            cursor += 1;
            // items
            if (index < cursor + list.length) {
              final item = list[index - cursor];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: MessageCard(message: item),
              );
            }
            cursor += list.length;
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
class MessageCard extends StatelessWidget {
  final MessageData message;

  const MessageCard({super.key, required this.message});

  IconData _getIconForSender(String sender) {
    final s = sender.toLowerCase();
    if (s.contains('flipkart')) return Icons.shopping_bag;
    if (s.contains('amazon')) return Icons.shopping_cart;
    if (s.contains('sbi') || s.contains('hdfc')) return Icons.account_balance;
    if (s.contains('swiggy')) return Icons.fastfood;
    if (s.contains('uber')) return Icons.directions_car;
    if (s.contains('netflix')) return Icons.movie;
    if (s.contains('income')) return Icons.money;
    if (s.contains('linkedin')) return Icons.work;
    if (s.contains('gov')) return Icons.account_balance_outlined;
    if (s.contains('vi') || sender == '54321') return Icons.sim_card;
    if (s.contains('tcsp') || s.contains('prize') || s.contains('spam')) return Icons.warning;
    return Icons.message;
  }

  static const List<Color> _pastelColors = [
    Color(0xFFFFD1DC),
    Color(0xFFFFF1C2),
    Color(0xFFCCFFFD),
    Color(0xFFD8F3DC),
    Color(0xFFE6E6FA),
    Color(0xFFFFE5B4),
  ];

  @override
  Widget build(BuildContext context) {
    final avatarColor = _pastelColors[message.sender.hashCode % _pastelColors.length];
    final icon = _getIconForSender(message.sender);
    final isImportant = message.category == MessageCategory.important;

    return Card(
      color: const Color(0xFF0F0F0F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: avatarColor,
          child: Icon(icon, color: Colors.black87, size: 20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(message.sender, style: TextStyle(color: message.senderColor, fontSize: 16, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            Text(message.time, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            children: [
              Expanded(child: Text(message.content, style: const TextStyle(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (isImportant) ...[
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE9AD40), borderRadius: BorderRadius.circular(12)), child: const Text('Important', style: TextStyle(color: Colors.black87, fontSize: 12))),
              ]
            ],
          ),
        ),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => MessageDetailScreen(
            sender: message.sender,
            content: message.content,
            time: message.time,
            isYesterday: message.isYesterday,
            category: message.category,
          )));
        },
      ),
    );
  }
}