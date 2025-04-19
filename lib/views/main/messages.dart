import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  final List<MessageData> _allMessages = [
    MessageData(sender: '54321', content: 'Your Vi recharge is successful curre...', time: '03:41', isYesterday: false, category: MessageCategory.regular),
    MessageData(sender: 'VM-TCSP', content: 'Click here to win the rewards and...', time: '02:45', isYesterday: false, category: MessageCategory.spam),
    MessageData(sender: 'Maha-gov', content: 'Your registration is successful kindly...', time: '03:41', isYesterday: false, category: MessageCategory.important),
    MessageData(sender: 'Flipkart', content: 'Your order is placed successfully...', time: 'Yesterday', isYesterday: true, category: MessageCategory.regular),
    MessageData(sender: 'SBI-Bank', content: 'Your account is credited with Rs. 50,...', time: 'Yesterday', isYesterday: true, category: MessageCategory.important),
    MessageData(sender: '54321', content: 'Your Vi recharge is successful curre...', time: 'Yesterday', isYesterday: true, category: MessageCategory.regular),
    MessageData(sender: 'Amazon', content: 'Your order #AB123456 has been shipped...', time: '01:15', isYesterday: false, category: MessageCategory.regular),
    MessageData(sender: 'DM-PRIZE', content: 'Congratulations! You won \$5,000,000 in our lottery...', time: '12:07', isYesterday: false, category: MessageCategory.spam),
    MessageData(sender: 'HDFC-Bank', content: 'Your credit card payment of Rs. 15,000 is due...', time: '09:22', isYesterday: false, category: MessageCategory.important),
    MessageData(sender: 'Netflix', content: 'New release: Your favorite show has a new season...', time: '11:30', isYesterday: false, category: MessageCategory.regular),
    MessageData(sender: 'SPAM-VIP', content: 'URGENT: Your car warranty is about to expire...', time: '07:18', isYesterday: false, category: MessageCategory.spam),
    MessageData(sender: 'Swiggy', content: '50% OFF your next order! Use code TASTY50...', time: '2 days ago', isYesterday: false, category: MessageCategory.regular),
    MessageData(sender: 'Income Tax', content: 'Your tax refund has been processed. Amount...', time: '2 days ago', isYesterday: false, category: MessageCategory.important),
    MessageData(sender: 'LinkedIn', content: 'You have 5 new connection requests and 3 new...', time: '3 days ago', isYesterday: false, category: MessageCategory.regular),
    MessageData(sender: '98765', content: 'Your OTP for transaction is 459832. Valid for 5...', time: '3 days ago', isYesterday: false, category: MessageCategory.regular),
    MessageData(sender: 'Uber', content: 'Your ride has been confirmed. Driver arriving in...', time: '3 days ago', isYesterday: false, category: MessageCategory.regular),
  ];

  List<MessageData> get _filteredMessages {
    if (_selectedCategory == MessageCategory.all) return _allMessages;
    return _allMessages.where((m) => m.category == _selectedCategory).toList();
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
              _buildSearchContainer(),
              _buildFilterBar(),
              _buildMessagesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchContainer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Color(0xFF333333), shape: BoxShape.circle)),
          SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              height: 45,
              decoration: BoxDecoration(
                color: Color(0xFF222222),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Icon(Icons.search, color: Colors.grey, size: 24),
                  Icon(Icons.more_vert, color: Colors.grey, size: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => _isFilterMenuOpen = !_isFilterMenuOpen),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(color: Color(0xFF8952D4), borderRadius: BorderRadius.circular(22)),
                  child: Row(
                    children: [
                      Icon(Icons.tune, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        _getFilterText(),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isFilterMenuOpen)
          Positioned(
            top: 50,
            left: 15,
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                color: Color(0xFF222222),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
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