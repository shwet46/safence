import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'dart:async'; 

class SpamPage extends StatefulWidget {
  const SpamPage({super.key});

  @override
  State<SpamPage> createState() => _SpamPageState();
}

class _SpamPageState extends State<SpamPage> {
  final SmsQuery _smsQuery = SmsQuery();
  List<CallLogEntry> _callLogs = [];
  List<SmsMessage> _smsMessages = [];
  bool _loadingCalls = true;
  bool _loadingSms = true;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  // Pastel colors for avatars
  static const List<Color> _pastelColors = [
    Color(0xFFFFD1DC), // pink
    Color(0xFFFFF1C2), // lemon
    Color(0xFFCCFFFD), // aqua
    Color(0xFFD8F3DC), // mint
    Color(0xFFE6E6FA), // lavender
    Color(0xFFFFE5B4), // peach
  ];

  // Simple static spam mails sample
  final List<Map<String, String>> _spamMails = [
    {
      'sender': 'DM-PRIZE',
      'subject': 'YOU WON Rs.5,000,000 LOTTERY',
      'preview':
          'Congratulations! You have been selected as our lucky winner...',
      'time': '2 Hours Ago',
    },
    {
      'sender': 'Unknown-Sender',
      'subject': 'Claim Your Free Gift Now',
      'preview': 'Click here to claim your free iPhone 15 Pro Max...',
      'time': '6 Hours Ago',
    }
  ];

  @override
  void initState() {
    super.initState();
    _initData();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchText = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    // Start both and wait for them to complete
    await Future.wait([
      _loadCallLogs(),
      _loadSms(),
    ]);
  }

  Future<void> _loadCallLogs() async {
    if (await Permission.phone.request().isGranted) {
      try {
        final Iterable<CallLogEntry> logs = await CallLog.get();
        if (mounted) {
          setState(() {
            _callLogs = logs.toList();
          });
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error loading call logs: $e');
      }
    }
    if (mounted) setState(() => _loadingCalls = false);
  }

  Future<void> _loadSms() async {
    if (await Permission.sms.request().isGranted) {
      try {
        final List<SmsMessage> inbox =
            await _smsQuery.querySms(kinds: [SmsQueryKind.inbox], sort: true);
        if (mounted) {
          setState(() {
            _smsMessages = inbox;
          });
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error loading SMS: $e');
      }
    }
    if (mounted) setState(() => _loadingSms = false);
  }

  String _normalizeNumber(String number) {
    final digits = number.replaceAll(RegExp(r"[^0-9]"), '');
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }

  bool _isSpamMessage(SmsMessage m) {
    final b = (m.body ?? '').toLowerCase();
    final sender = (m.address ?? '').toLowerCase();
    if (b.contains('win') ||
        b.contains('prize') ||
        b.contains('lottery') ||
        b.contains('urgent') ||
        b.contains('click here') ||
        b.contains('claim')) return true;
    if (sender.contains('tcsp') ||
        sender.contains('prize') ||
        sender.contains('spam')) return true;
    return false;
  }

  String _formatTileTimestamp(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dt.year, dt.month, dt.day);

    if (messageDate == today) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${dt.day}/${dt.month}/${dt.year.toString().substring(2)}';
    }
  }

  String _formatDateHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dt.year, dt.month, dt.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          // Removed hardcoded bottom padding
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildTabBar(),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildNumbersTab(),
                      _buildMessagesTab(),
                      _buildMailsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Material(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(12),
      child: TabBar(
        tabAlignment: TabAlignment.fill, // Ensures tabs fill the space
        indicator: BoxDecoration(
          color: const Color(0xFF8952D4),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8952D4).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: [
          // Removed SizedBox wrappers
          Tab(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.phone, size: 14),
                SizedBox(width: 4),
                Text('Numbers'),
              ],
            ),
          ),
          Tab(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.message, size: 14),
                SizedBox(width: 4),
                Text('Messages'),
              ],
            ),
          ),
          Tab(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.mail, size: 14),
                SizedBox(width: 4),
                Text('Mails'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumbersTab() {
    if (_loadingCalls) {
      return const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8952D4))));
    }

    // Group by normalized number
    final Map<String, List<CallLogEntry>> byNumber = {};
    for (final log in _callLogs) {
      final number = log.number ?? 'Unknown';
      final key = _normalizeNumber(number);
      byNumber.putIfAbsent(key.isEmpty ? number : key, () => []).add(log);
    }

    // Heuristic: suspect spam when a number appears >= 3 times and has no name
    final suspected = byNumber.entries.where((e) {
      final list = e.value;
      final hasName = list.any((l) => (l.name ?? '').trim().isNotEmpty);
      return list.length >= 3 && !hasName;
    }).toList();

    if (suspected.isEmpty) {
      return _buildEmptyState(
          Icons.phone_paused, 'No suspected spam calls found');
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Suspected Spam (${suspected.length})',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
        ...suspected.map((entry) => _buildNumberTile(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildNumberTile(String key, List<CallLogEntry> logs) {
    final display = logs.first.name?.isNotEmpty == true
        ? logs.first.name!
        : (logs.first.number ?? key);
    final latestTs =
        logs.map((e) => e.timestamp ?? 0).reduce((a, b) => a > b ? a : b);
    final initials = display
        .trim()
        .split(' ')
        .map((s) => s.isEmpty ? '?' : s[0].toUpperCase())
        .take(2)
        .join();
    final color = _pastelColors[display.hashCode % _pastelColors.length];
    const bool isSuspected = true; // Always true in this new logic

    return Card(
      color: const Color(0xFF1A1A1A), // Consistent card color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color,
          child: Text(initials,
              style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                display,
                style: const TextStyle(
                  color: Color(0xFFE25C5C), // Always red
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              _formatTileTimestamp(latestTs),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(Icons.call, size: 14, color: Color(0xFFE25C5C)),
              const SizedBox(width: 4),
              Text(
                '${logs.length} calls',
                style: const TextStyle(
                  color: Color(0xFFE25C5C),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE25C5C).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFE25C5C), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Suspected Spam',
                      style: TextStyle(
                        color: Color(0xFFE25C5C),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesTab() {
    if (_loadingSms) {
      return const Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8952D4))));
    }
    final spam = _smsMessages.where(_isSpamMessage).toList();
    if (spam.isEmpty) {
      return _buildEmptyState(
          Icons.mark_email_read, 'No spam messages found');
    }

    // Group messages by date
    final Map<String, List<SmsMessage>> grouped = {};
    for (final msg in spam) {
      if (msg.date == null) continue;
      // Use the new _formatDateHeader for grouping
      final dateKey = _formatDateHeader(msg.date!);
      grouped.putIfAbsent(dateKey, () => []).add(msg);
    }

    final sortedDates = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'Today') return -1;
        if (b == 'Today') return 1;
        if (a == 'Yesterday') return -1;
        if (b == 'Yesterday') return 1;
        // Basic date sort for 'dd/MM/yyyy'
        try {
          final dtA = a.split('/').reversed.join();
          final dtB = b.split('/').reversed.join();
          return dtB.compareTo(dtA);
        } catch (_) {
          return a.compareTo(b);
        }
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final messages = grouped[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                date,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...messages.map((m) => _buildMessageTile(m)),
          ],
        );
      },
    );
  }

  Widget _buildMessageTile(SmsMessage m) {
    return Card(
      color: const Color(0xFF1A1A1A), // Consistent card color
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFE25C5C),
          child:
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 26),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                m.address ?? 'Unknown',
                style: const TextStyle(
                  color: Color(0xFFE25C5C),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              m.date != null
                  ? '${m.date!.hour.toString().padLeft(2, '0')}:${m.date!.minute.toString().padLeft(2, '0')}'
                  : '',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              m.body ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE25C5C).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.report_gmailerrorred,
                      color: Color(0xFFE25C5C), size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Spam Message',
                    style: TextStyle(
                      color: Color(0xFFE25C5C),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMailsTab() {
    if (_spamMails.isEmpty) {
      return _buildEmptyState(Icons.mark_email_read, 'No spam mails');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _spamMails.length,
      itemBuilder: (context, index) {
        final mail = _spamMails[index];
        return _buildMailTile(mail);
      },
    );
  }

  Widget _buildMailTile(Map<String, String> mail) {
    return Card(
      color: const Color(0xFF1A1A1A), // Consistent card color
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFE25C5C),
                  child: Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            mail['sender']!,
                            style: const TextStyle(
                              color: Color(0xFFE25C5C),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE25C5C).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              mail['time']!,
                              style: const TextStyle(
                                color: Color(0xFFE25C5C),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mail['subject']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mail['preview']!,
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.not_interested, size: 16),
                  label: const Text('Not Spam'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE25C5C),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // Consistent color
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: "Search in spam...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            // Conditionally show the clear button
            if (_searchText.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                onPressed: () {
                  _searchController.clear();
                },
              )
          ],
        ),
      ),
    );
  }
}