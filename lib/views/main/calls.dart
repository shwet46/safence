import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart'; 
import 'package:url_launcher/url_launcher.dart';

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

    final List<Widget> items = [];
    final Map<String, List<Contact>> grouped = {};

    for (final c in _filteredContacts) {
      final letter =
          c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : "#";
      grouped.putIfAbsent(letter, () => []).add(c);
    }
    final sortedLetters = grouped.keys.toList()..sort();

    for (final letter in sortedLetters) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
          child: Text(
            letter,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      final contacts = grouped[letter]!;
      items.addAll(contacts.map((c) => _buildContactTile(c)));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return items[index];
      },
    );
  }

  Widget _buildContactTile(Contact c) {
    final firstLetter = c.displayName.isNotEmpty ? c.displayName[0] : "?";
    final phoneNumber = c.phones.isNotEmpty ? c.phones.first.number : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: phoneNumber != null ? () => _makePhoneCall(phoneNumber) : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        leading: c.thumbnail != null
            ? CircleAvatar(backgroundImage: MemoryImage(c.thumbnail!))
            : CircleAvatar(
                backgroundColor: const Color(0xFF333333),
                child: Text(
                  firstLetter,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
        title: Text(
          c.displayName,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          phoneNumber ?? "(no number)",
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildRecentLogView() {
    if (_callLogs.isEmpty) {
      return const Center(
          child: Text("No call logs found",
              style: TextStyle(color: Colors.white)));
    }

    final List<Widget> items = [];
    final Map<String, List<CallLogEntry>> grouped = {};

    for (final log in _callLogs) {
      if (log.timestamp == null) continue;
      final date =
          _formatDate(DateTime.fromMillisecondsSinceEpoch(log.timestamp!));
      grouped.putIfAbsent(date, () => []).add(log);
    }

    grouped.forEach((date, logs) {
      items.add(
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
          child: Text(date,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ),
      );
      items.add(Container(
        margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: logs.asMap().entries.map((entry) {
            final index = entry.key;
            final call = entry.value;
            return Column(
              children: [
                _buildCallLogTile(call),
                if (index < logs.length - 1)
                  const Divider(
                      color: Color(0xFF333333),
                      height: 1,
                      indent: 70,
                      endIndent: 15),
              ],
            );
          }).toList(),
        ),
      ));
    });

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return items[index];
      },
    );
  }

  Widget _buildCallLogTile(CallLogEntry call) {
    final name = call.name ?? call.number ?? 'Unknown';
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final phoneNumber = call.number;

    return ListTile(
      onTap: phoneNumber != null ? () => _makePhoneCall(phoneNumber) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF333333),
        child: Text(
          firstLetter,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(name,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500)),
      subtitle: Row(
        children: [
          Icon(_getCallIcon(call.callType),
              color: _getCallColor(call.callType), size: 16),
          const SizedBox(width: 4),
          Text(
              call.timestamp != null
                  ? _formatTime(call.timestamp!)
                  : "--:--",
              style: TextStyle(
                  color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
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