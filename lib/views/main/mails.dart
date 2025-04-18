import 'package:flutter/material.dart';

enum MessageCategory {
  all,
  important,
  normal,
  spam,
}

class MailsPage extends StatefulWidget {
  @override
  State<MailsPage> createState() => _MailsPageState();
}

class _MailsPageState extends State<MailsPage> {
  MessageCategory _selectedCategory = MessageCategory.all;
  bool _isFilterMenuOpen = false;

  final List<Map<String, String>> mails = [
    {
      'sender': 'Google Careers',
      'subject': 'Shortlisted: SWE Role',
      'preview': 'You have been shortlisted for the next round...',
      'time': 'Just now',
      'tag': 'important',
    },
    {
      'sender': 'Adobe Hiring',
      'subject': 'Thank You for Applying',
      'preview': 'We appreciate your interest. You will hear back...',
      'time': '4 Days Ago',
      'tag': 'normal',
    },
    {
      'sender': 'Google Summer of Code',
      'subject': 'Submission Confirmation',
      'preview': 'Your proposal has been submitted successfully...',
      'time': '4 Days Ago',
      'tag': 'normal',
    },
    {
      'sender': 'Amazon',
      'subject': 'Order Confirmation',
      'preview': 'Your order #AB123456 has been confirmed...',
      'time': 'Yesterday',
      'tag': 'important',
    },
    {
      'sender': 'LinkedIn',
      'subject': 'New Connection Requests',
      'preview': 'You have 5 new connection requests waiting...',
      'time': '2 Days Ago',
      'tag': 'normal',
    },
    // Adding 10 more mails including 2 important and 2 spam
    {
      'sender': 'Microsoft Teams',
      'subject': 'Urgent: Project Meeting Today',
      'preview': 'The project deadline meeting has been moved to 3PM...',
      'time': '1 Hour Ago',
      'tag': 'important',
    },
    {
      'sender': 'DM-PRIZE',
      'subject': 'YOU WON Rs.5,000,000 LOTTERY',
      'preview': 'Congratulations! You have been selected as our lucky winner...',
      'time': '2 Hours Ago',
      'tag': 'spam',
    },
    {
      'sender': 'Netflix',
      'subject': 'New Shows This Weekend',
      'preview': 'Check out the latest additions to your watchlist...',
      'time': '3 Hours Ago',
      'tag': 'normal',
    },
    {
      'sender': 'Bank of America',
      'subject': 'Important: Security Alert',
      'preview': 'We detected unusual activity on your account. Please verify...',
      'time': '5 Hours Ago',
      'tag': 'important',
    },
    {
      'sender': 'Unknown-Sender',
      'subject': 'Claim Your Free Gift Now',
      'preview': 'Click here to claim your free iPhone 15 Pro Max...',
      'time': '6 Hours Ago',
      'tag': 'spam',
    },
    {
      'sender': 'Dribbble',
      'subject': 'Weekly Inspiration Digest',
      'preview': 'Here are the top designs from this week that might inspire...',
      'time': 'Yesterday',
      'tag': 'normal',
    },
    {
      'sender': 'GitHub',
      'subject': 'Pull Request #42 Approved',
      'preview': 'Your pull request to the main branch has been approved...',
      'time': 'Yesterday',
      'tag': 'normal',
    },
    {
      'sender': 'Medium',
      'subject': 'Daily Reading List',
      'preview': 'Articles we think you might enjoy based on your interests...',
      'time': '2 Days Ago',
      'tag': 'normal',
    },
    {
      'sender': 'Spotify',
      'subject': 'New Playlist Recommendations',
      'preview': 'We created some playlists based on your listening habits...',
      'time': '3 Days Ago',
      'tag': 'normal',
    },
    {
      'sender': 'Twitter',
      'subject': 'Security Notification',
      'preview': 'A new login was detected from Washington DC. Was this you?...',
      'time': '3 Days Ago',
      'tag': 'normal',
    },
  ];

  Color getTagColor(String tag) {
    switch (tag) {
      case 'important':
        return Color(0xFFE9AD40);
      case 'spam':
        return Color(0xFFE25C5C);
      default:
        return Colors.white;
    }
  }

  List<Map<String, String>> get filteredMails {
    if (_selectedCategory == MessageCategory.all) return mails;
    String categoryTag = _getCategoryTag(_selectedCategory);
    return mails.where((mail) => mail['tag'] == categoryTag).toList();
  }

  String _getCategoryTag(MessageCategory category) {
    switch (category) {
      case MessageCategory.important:
        return 'important';
      case MessageCategory.spam:
        return 'spam';
      case MessageCategory.normal:
        return 'normal';
      default:
        return '';
    }
  }

  String _getFilterText() {
    switch (_selectedCategory) {
      case MessageCategory.important:
        return 'Important Mails';
      case MessageCategory.normal:
        return 'Regular Mails';
      case MessageCategory.spam:
        return 'Spam Mails';
      default:
        return 'Filter Mails';
    }
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
              const SizedBox(height: 10),
              _buildFilterBar(),
              const SizedBox(height: 10),
              Expanded(
                child: filteredMails.isEmpty
                    ? Center(child: Text('No mails in this category', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        itemCount: filteredMails.length,
                        separatorBuilder: (_, __) => Divider(color: Color(0xFF222222), height: 1),
                        itemBuilder: (context, index) => _buildMailItem(filteredMails[index]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF333333),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => _isFilterMenuOpen = !_isFilterMenuOpen),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF8952D4), // Purple color for filter button
                    borderRadius: BorderRadius.circular(22),
                  ),
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
                  _buildFilterOption(MessageCategory.all, 'All Mails'),
                  _buildFilterOption(MessageCategory.important, 'Important', Color(0xFFE9AD40)),
                  _buildFilterOption(MessageCategory.normal, 'Regular'),
                  _buildFilterOption(MessageCategory.spam, 'Spam', Color(0xFFE25C5C)),
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
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF333333), width: 0.5)),
        ),
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

  Widget _buildMailItem(Map<String, String> mail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF333333),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      mail['sender']!,
                      style: TextStyle(
                        color: getTagColor(mail['tag'] ?? ''),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      mail['time']!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  mail['subject']!,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  mail['preview']!,
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