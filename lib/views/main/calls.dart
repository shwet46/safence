import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart'; 
import 'package:url_launcher/url_launcher.dart';
import 'package:safence/components/contact_detail.dart';
import 'package:safence/services/numverify_service.dart';

class CallsPage extends StatefulWidget {
  const CallsPage({super.key});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  bool showContacts = false;
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _permissionDenied = false;
  String _searchQuery = "";
  List<CallLogEntry> _callLogs = [];
  bool _isLoading = true;
  // Cache spam detection results for numbers (normalized)
  final Map<String, bool> _spamCache = {};
  final Set<String> _spamCheckInProgress = {};

  @override
  void initState() {
    super.initState();
    _initializePage();
    _setupPhoneStateListener();
  }

  Future<void> _initializePage() async {
    await _requestPermissions();
    await _fetchContacts();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _setupPhoneStateListener() {
    PhoneState.stream.listen((event) {
      if (event == PhoneStateStatus.CALL_ENDED) {
        Future.delayed(const Duration(seconds: 1), _fetchCallLogs);
      }
    });
  }

  Future<void> _refreshData() async {
    await _fetchCallLogs();
    await _fetchContacts();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.contacts,
    ].request();

    if (statuses[Permission.phone]!.isGranted) {
      _fetchCallLogs();
    }
    if (statuses[Permission.contacts]!.isDenied ||
        statuses[Permission.contacts]!.isPermanentlyDenied) {
      if (mounted) {
        setState(() => _permissionDenied = true);
      }
    }
  }

  Future<void> _fetchCallLogs() async {
    final bool isGranted = await Permission.phone.isGranted;
    if (isGranted) {
      final Iterable<CallLogEntry> logs = await CallLog.get();
      if (mounted) {
        setState(() {
          _callLogs = logs.toList();
        });
      }
    }
  }

  Future<void> _fetchContacts() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      if (mounted) {
        setState(() => _permissionDenied = true);
      }
    } else {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      contacts.sort((a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
      if (mounted) {
        setState(() {
          _contacts = contacts;
          _filteredContacts = List<Contact>.from(contacts);
        });
      }
    }
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
      _filteredContacts = _contacts
          .where((c) =>
              c.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint('Could not launch $phoneNumber');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 10),
              _buildFilterButtons(),
              const SizedBox(height: 10),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  color: Colors.white,
                  backgroundColor: const Color(0xFF222222),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : showContacts
                          ? _buildContactsView()
                          : _buildRecentLogView(),
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
                  hintText: "Search contacts...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                onChanged: _filterContacts,
              ),
            ),
            const Icon(Icons.more_vert, color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Row(
        children: [
          _buildToggleButton(
            "Contacts",
            Icons.people,
            showContacts,
            () => setState(() => showContacts = true),
          ),
          const SizedBox(width: 10),
          _buildToggleButton(
            "Recent log",
            Icons.call,
            !showContacts,
            () => setState(() => showContacts = false),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
      String title, IconData icon, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF8952D4) : const Color(0xFF222222),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactsView() {
    if (_permissionDenied) {
      return const Center(
          child: Text("Contact permission denied",
              style: TextStyle(color: Colors.white)));
    }

    if (_filteredContacts.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty
              ? "No contacts found"
              : "No contacts on this device",
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
      );
    }

    final Map<String, List<Contact>> grouped = {};

    for (final c in _filteredContacts) {
      final letter = c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : "#";
      grouped.putIfAbsent(letter, () => []).add(c);
    }
    final sortedLetters = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedLetters.length,
      itemBuilder: (context, index) {
        final letter = sortedLetters[index];
        final contacts = grouped[letter]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(letter, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            ...contacts.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  child: _buildContactTile(c),
                )),
          ],
        );
      },
    );
  }

  Widget _buildContactTile(Contact c) {
    final phoneNumber = c.phones.isNotEmpty ? c.phones.first.number : null;
    final extraCount = c.phones.length > 1 ? c.phones.length - 1 : 0;
    final initials = c.displayName.isNotEmpty ? c.displayName.trim().split(' ').map((s) => s.characters.first).take(2).join().toUpperCase() : '?';
    final color = _pastelColors[c.displayName.hashCode % _pastelColors.length];

    return Card(
      color: const Color(0xFF0F0F0F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ContactDetailPage(contact: c))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: c.thumbnail != null
            ? CircleAvatar(backgroundImage: MemoryImage(c.thumbnail!), radius: 26)
            : CircleAvatar(
                radius: 26,
                backgroundColor: color,
                child: Text(initials, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              ),
        title: Text(c.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(
          phoneNumber != null ? (extraCount > 0 ? '$phoneNumber • +$extraCount more' : phoneNumber) : '(no number)',
          style: const TextStyle(color: Colors.white70),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: phoneNumber != null ? () => _makePhoneCall(phoneNumber) : null,
              icon: const Icon(Icons.call, color: Color(0xFF8952D4)),
            ),
            IconButton(
              onPressed: phoneNumber != null ? () => _sendSms(phoneNumber) : null,
              icon: const Icon(Icons.message, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendSms(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open SMS app')));
    }
  }

  Widget _buildRecentLogView() {
    if (_callLogs.isEmpty) {
      return const Center(
          child: Text("No call logs found",
              style: TextStyle(color: Colors.white)));
    }
    // First group by date (Today, Yesterday, or dd/mm/yyyy), then within each
    // date group, group by phone number so calls from the same number on the
    // same date are shown together.
    final Map<String, List<CallLogEntry>> groupedByDate = {};
    for (final log in _callLogs) {
      if (log.timestamp == null) continue;
      final date = _formatDate(DateTime.fromMillisecondsSinceEpoch(log.timestamp!));
      groupedByDate.putIfAbsent(date, () => []).add(log);
    }

    // Sort date groups by most recent call within that date
    final dateEntries = groupedByDate.entries.toList()
      ..sort((a, b) {
        final aLatest = a.value.map((e) => e.timestamp ?? 0).reduce((v, e) => v > e ? v : e);
        final bLatest = b.value.map((e) => e.timestamp ?? 0).reduce((v, e) => v > e ? v : e);
        return bLatest.compareTo(aLatest);
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: dateEntries.length,
      itemBuilder: (context, di) {
        final dateLabel = dateEntries[di].key;
        final logsForDate = dateEntries[di].value;

        // Group logs for this date by normalized phone number
        final Map<String, List<CallLogEntry>> byNumber = {};
        for (final log in logsForDate) {
          final number = log.number ?? 'Unknown';
          final key = _normalizeNumber(number);
          byNumber.putIfAbsent(key, () => []).add(log);
        }

        // Sort groups by latest timestamp descending
        final groups = byNumber.entries.toList()
          ..sort((a, b) {
            final aLatest = a.value.map((e) => e.timestamp ?? 0).reduce((v, e) => v > e ? v : e);
            final bLatest = b.value.map((e) => e.timestamp ?? 0).reduce((v, e) => v > e ? v : e);
            return bLatest.compareTo(aLatest);
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
              child: Text(dateLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                children: groups.map((entry) {
                  final logs = entry.value;
                  final displayName = logs.firstWhere((l) => (l.name ?? '').isNotEmpty, orElse: () => logs.first).name ?? logs.first.number ?? 'Unknown';
                  final number = logs.first.number ?? 'Unknown';
                  final count = logs.length;
                  final latestTs = logs.map((e) => e.timestamp ?? 0).reduce((v, e) => v > e ? v : e);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildNumberGroupTile(displayName, number, logs, count, latestTs),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  String _normalizeNumber(String number) {
    // Keep digits only and take last 10 digits for grouping
    final digits = number.replaceAll(RegExp(r"[^0-9]"), '');
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }

  // Pastel color palette for avatars
  static const List<Color> _pastelColors = [
    Color(0xFFFFD1DC), // pink
    Color(0xFFFFF1C2), // lemon
    Color(0xFFCCFFFD), // aqua
    Color(0xFFD8F3DC), // mint
    Color(0xFFE6E6FA), // lavender
    Color(0xFFFFE5B4), // peach
  ];

  Widget _buildNumberGroupTile(String name, String number, List<CallLogEntry> logs, int count, int latestTs) {
    if (!_isNumberInContacts(number)) {
      _ensureSpamStatus(number);
    }
    final initials = name.trim().isNotEmpty ? name.trim().split(' ').map((s) => s.characters.first).take(2).join().toUpperCase() : '?';
    final color = _pastelColors[number.hashCode % _pastelColors.length];
    final latestCall = logs.reduce((a, b) => (a.timestamp ?? 0) > (b.timestamp ?? 0) ? a : b);
    return Card(
      color: const Color(0xFF121212),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        collapsedIconColor: Colors.white70,
        iconColor: Colors.white,
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: color,
          child: Text(initials, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Icon(_getCallIcon(latestCall.callType), color: _getCallColor(latestCall.callType), size: 14),
            const SizedBox(width: 6),
            Text(_callTypeLabel(latestCall.callType), style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(width: 8),
            Text('• ${_formatTime(latestTs)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(width: 6),
            Flexible(child: Text(' • $number', style: const TextStyle(color: Colors.white38, fontSize: 12), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 6),
            // Spam badge when numverify/service marks number as spam.
            // Do not show badge for saved contacts.
            if (!_isNumberInContacts(number) && _spamCache[_normalizeNumber(number)] == true) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE25C5C), borderRadius: BorderRadius.circular(12)),
                child: const Text('Spam', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        children: logs.map((call) {
          return Column(
            children: [
              ListTile(
                onTap: call.number != null ? () => _makePhoneCall(call.number!) : null,
                leading: Icon(_getCallIcon(call.callType), color: _getCallColor(call.callType)),
                title: Text(call.name ?? call.number ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                subtitle: Text('${_formatDate(DateTime.fromMillisecondsSinceEpoch(call.timestamp ?? 0))} • ${_formatTime(call.timestamp ?? 0)}', style: const TextStyle(color: Colors.white60)),
                trailing: Text(_formatDuration(call.duration ?? 0), style: const TextStyle(color: Colors.white54)),
              ),
              if (call != logs.last) const Divider(color: Color(0xFF222222), height: 1, indent: 70, endIndent: 12),
            ],
          );
        }).toList(),
        childrenPadding: EdgeInsets.zero,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
          child: Text('$count', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  void _ensureSpamStatus(String number) {
    final key = _normalizeNumber(number);
    if (key.isEmpty) return;
    if (_spamCache.containsKey(key) || _spamCheckInProgress.contains(key)) return;
    _spamCheckInProgress.add(key);

    NumverifyService.isSpamNumber(number).then((isSpam) {
      if (!mounted) return;
      setState(() {
        _spamCache[key] = isSpam;
        _spamCheckInProgress.remove(key);
      });
    }).catchError((_) {
      _spamCheckInProgress.remove(key);
    });
  }

  bool _isNumberInContacts(String number) {
    final key = _normalizeNumber(number);
    if (key.isEmpty) return false;
    for (final c in _contacts) {
      for (final p in c.phones) {
        final pn = _normalizeNumber(p.number);
        if (pn.isNotEmpty && pn == key) return true;
      }
    }
    return false;
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '${m}m ${s}s';
  }

  String _callTypeLabel(CallType? callType) {
    switch (callType) {
      case CallType.outgoing:
        return 'Outgoing';
      case CallType.missed:
        return 'Missed';
      case CallType.rejected:
        return 'Rejected';
      case CallType.incoming:
        return 'Incoming';
      default:
        return 'Call';
    }
  }

  

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) {
      return 'Today';
    } else if (dateToCompare == yesterday) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getCallIcon(CallType? callType) {
    switch (callType) {
      case CallType.outgoing:
        return Icons.call_made;
      case CallType.missed:
        return Icons.call_missed;
      case CallType.rejected:
        return Icons.call_end;
      default:
        return Icons.call_received;
    }
  }

  Color _getCallColor(CallType? callType) {
    switch (callType) {
      case CallType.outgoing:
        return Colors.green;
      case CallType.missed:
      case CallType.rejected:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}