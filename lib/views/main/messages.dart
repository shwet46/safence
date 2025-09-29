import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show EventChannel;
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
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

enum MessageCategory { all, spam, important, regular }

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
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          child: Column(
            children: [
              _buildSearchBar(),
              _buildFilterBar(),
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

  Widget _buildFilterBar() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => _isFilterMenuOpen = !_isFilterMenuOpen),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF8952D4),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tune, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        _getFilterText(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isFilterMenuOpen)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Color(0xFF222222),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterOption(MessageCategory.all, 'All Messages'),
                _buildFilterOption(MessageCategory.spam, 'Spam', Color(0xFFE25C5C)),
                _buildFilterOption(MessageCategory.important, 'Important', Color(0xFFE9AD40)),
                _buildFilterOption(MessageCategory.regular, 'Regular'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterOption(MessageCategory category, String text, [Color? iconColor]) {
    return InkWell(
      onTap: () => setState(() {
        _selectedCategory = category;
        _isFilterMenuOpen = false;
      }),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        width: double.infinity,
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF333333), width: 0.5))),
        child: Row(
          children: [
            Icon(
              _selectedCategory == category ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: _selectedCategory == category ? Color(0xFF8952D4) : Colors.grey,
              size: 18,
            ),
            SizedBox(width: 10),
            if (iconColor != null) ...[
              Container(width: 12, height: 12, decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle)),
              SizedBox(width: 8),
            ],
            Text(text, style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  String _getFilterText() {
    switch (_selectedCategory) {
      case MessageCategory.spam:
        return 'Spam Messages';
      case MessageCategory.important:
        return 'Important Messages';
      case MessageCategory.regular:
        return 'Regular Messages';
      default:
        return 'Filter Messages';
    }
  }

  Widget _buildMessagesList() {
    return Expanded(
      child: _filteredMessages.isEmpty
          ? Center(child: Text('No messages in this category', style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              itemCount: _filteredMessages.length,
              separatorBuilder: (_, __) => Divider(color: Color(0xFF222222), height: 1),
              itemBuilder: (context, index) => MessageItem(message: _filteredMessages[index]),
            ),
    );
  }
}

class MessageItem extends StatelessWidget {
  final MessageData message;

  const MessageItem({super.key, required this.message});

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Color(0xFF333333), shape: BoxShape.circle),
            child: Center(
              child: Icon(
                _getIconForSender(message.sender),
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      message.sender,
                      style: TextStyle(
                        color: message.senderColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      message.time,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  message.content,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}