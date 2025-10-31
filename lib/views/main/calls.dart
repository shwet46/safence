import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart'; 
import 'package:url_launcher/url_launcher.dart';
import 'package:safence/components/contact_detail.dart';
import 'package:safence/components/num_keypad.dart';
import 'package:safence/services/numverify_service.dart';
import 'package:safence/services/numlookup_service.dart';
import 'package:safence/views/main/call_detail.dart';

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
  // dial pad state
  bool _showDialPad = false;

  // Cache spam detection results for numbers (normalized)
  final Map<String, bool> _spamCache = {};
  final Set<String> _spamCheckInProgress = {};

  final Map<String, NumlookupResult?> _numlookupCache = {};
  final Set<String> _numlookupInProgress = {};

  final Map<String, Map<String, dynamic>?> _numverifyDetailsCache = {};
  final Set<String> _numverifyInProgress = {};

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
  // Compute exact offset based on how `CustomBottomNav` is laid out in main_page:
  // SafeArea (inset) + Padding(bottom:8) + Container margin.bottom (20) + nav height (70)
  final inset = MediaQuery.of(context).padding.bottom;
  const double navPaddingBottom = 8.0;
  const double navMargin = 20.0;
  const double navHeight = 70.0;
  const double extraGap = 36.0; // increased gap between nav and keypad to lift it higher
  final bottomNavGap = inset + navPaddingBottom + navMargin + navHeight + extraGap;
  final double navRightInset = navMargin; // align overlay horizontally with the nav's margin
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
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

            // Dial pad overlay positioned above bottom nav at bottom-right
            Positioned(
              right: navRightInset,
              bottom: bottomNavGap,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _showDialPad
                    ? NumKeypad(
                        key: const ValueKey('num_keypad'),
                        onClose: () => setState(() => _showDialPad = false),
                        onCall: (num) {
                          setState(() => _showDialPad = false);
                          _makePhoneCall(num);
                        },
                        onSms: (num) {
                          setState(() => _showDialPad = false);
                          _sendSms(num);
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            // Toggle button anchored bottom-right
            Positioned(
              right: navRightInset,
              bottom: inset + navPaddingBottom + navMargin + navHeight + 12.0, // place FAB higher above the nav
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF8952D4),
                onPressed: () => setState(() => _showDialPad = !_showDialPad),
                child: Icon(_showDialPad ? Icons.keyboard_hide : Icons.dialpad),
              ),
            ),
          ],
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

    // Trigger spam check for contact's primary number and read cached value
    final contactKey = phoneNumber != null ? _normalizeNumber(phoneNumber) : '';
    if (phoneNumber != null && contactKey.isNotEmpty) {
      _ensureSpamStatus(phoneNumber);
    }
    final bool contactIsSpam = contactKey.isNotEmpty && (_spamCache[contactKey] == true);

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
            if (contactIsSpam) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE25C5C), borderRadius: BorderRadius.circular(12)),
                child: const Text('Spam', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
            ],
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
    final key = _normalizeNumber(number);
    // Always trigger lookups so we can show location/owner info for all numbers
    _ensureSpamStatus(number);
    _ensureNumlookup(number);
    _ensureNumverifyDetails(number);

    final NumlookupResult? nl = key.isNotEmpty ? _numlookupCache[key] : null;
    final Map<String, dynamic>? nv = key.isNotEmpty ? _numverifyDetailsCache[key] : null;
    final bool nvSpam = nv != null ? _nvIsSpam(nv) : false;
    final bool isSpamFinal = (nl?.isSpam == true) || (nl == null && (nvSpam || _spamCache[key] == true));

    // Determine owner/carrier/location from available caches
    String? ownerName = nl?.owner;
    if (ownerName == null && nv != null) {
      for (final k in ['caller_name', 'callerid', 'name', 'owner', 'owner_name', 'contact_name']) {
        if (nv.containsKey(k) && nv[k] is String && (nv[k] as String).trim().isNotEmpty) {
          ownerName = nv[k] as String;
          break;
        }
      }
    }
    String? carrier = nl?.raw['carrier'] as String?;
    carrier ??= nv?['carrier'] as String?;
    String? location = nl?.raw['location'] as String?;
    location ??= nv?['location'] as String?;
    location ??= nv?['country_name'] as String?;

    final initials = name.trim().isNotEmpty ? name.trim().split(' ').map((s) => s.characters.first).take(2).join().toUpperCase() : '?';
    final color = _pastelColors[number.hashCode % _pastelColors.length];
    final latestCall = logs.reduce((a, b) => (a.timestamp ?? 0) > (b.timestamp ?? 0) ? a : b);

    return Card(
      color: const Color(0xFF121212),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            const SizedBox(width: 8),
        
            Flexible(
              child: InkWell(
                onTap: () {
                  final key = _normalizeNumber(number);
                  final nl = key.isNotEmpty ? _numlookupCache[key] : null;
                  final nv = key.isNotEmpty ? _numverifyDetailsCache[key] : null;
                  final spamScoreLocal = nl?.spamScore ?? (nv != null && nv['spam_score'] is num ? (nv['spam_score'] as num).toDouble() : null);
                  final isSpamLocal = (nl?.isSpam == true) || (nl == null && (nv != null ? _nvIsSpam(nv) : (_spamCache[key] == true)));
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => CallDetailScreen(number: number, owner: nl?.owner ?? ownerName, numlookup: nl?.raw, numverify: nv, spamScore: spamScoreLocal, isSpam: isSpamLocal)));
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$number', style: const TextStyle(color: Colors.white38, fontSize: 12), overflow: TextOverflow.ellipsis),
                    if (location != null && location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(location, style: const TextStyle(color: Colors.white38, fontSize: 11), overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSpamFinal) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE25C5C), borderRadius: BorderRadius.circular(12)),
                child: const Text('Spam', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
              child: Text('$count', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        onTap: () {
          // Also allow tapping the whole tile to open details
          final key = _normalizeNumber(number);
          final nl = key.isNotEmpty ? _numlookupCache[key] : null;
          final nv = key.isNotEmpty ? _numverifyDetailsCache[key] : null;
          final spamScoreLocal = nl?.spamScore ?? (nv != null && nv['spam_score'] is num ? (nv['spam_score'] as num).toDouble() : null);
          final isSpamLocal = (nl?.isSpam == true) || (nl == null && (nv != null ? _nvIsSpam(nv) : (_spamCache[key] == true)));
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => CallDetailScreen(number: number, owner: nl?.owner ?? null, numlookup: nl?.raw, numverify: nv, spamScore: spamScoreLocal, isSpam: isSpamLocal)));
        },
      ),
    );
  }

  void _ensureNumverifyDetails(String number) {
    final key = _normalizeNumber(number);
    if (key.isEmpty) return;
    if (_numverifyDetailsCache.containsKey(key) || _numverifyInProgress.contains(key)) return;
    _numverifyInProgress.add(key);

    NumverifyService.fetchDetails(number).then((res) {
      if (!mounted) return;
      setState(() {
        _numverifyDetailsCache[key] = res;
        _numverifyInProgress.remove(key);
      });
    }).catchError((_) {
      _numverifyInProgress.remove(key);
    });
  }

  bool _nvIsSpam(Map<String, dynamic> data) {
    try {
      final valid = data['valid'] == true;
      final lineType = (data['line_type'] as String?)?.toLowerCase();
      final carrier = (data['carrier'] as String?)?.toLowerCase();
      if (!valid) return true;
      if (lineType == 'voip' || lineType == 'pager' || lineType == 'unknown') return true;
      if (carrier == null || carrier.isEmpty) return true;
    } catch (e) {
      return false;
    }
    return false;
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

  void _ensureNumlookup(String number) {
    final key = _normalizeNumber(number);
    if (key.isEmpty) return;
    if (_numlookupCache.containsKey(key) || _numlookupInProgress.contains(key)) return;
    _numlookupInProgress.add(key);

    NumlookupService.lookup(number).then((res) {
      if (!mounted) return;
      setState(() {
        _numlookupCache[key] = res;
        _numlookupInProgress.remove(key);
      });
    }).catchError((_) {
      _numlookupInProgress.remove(key);
    });
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