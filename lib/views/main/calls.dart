import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    _requestPermissions();
    _setupPhoneStateListener();
  }

  Future<void> _requestPermissions() async {
    await Permission.phone.request();
    await Permission.phone.request();
    _fetchCallLogs();
  }

  void _setupPhoneStateListener() {
    PhoneState.stream.listen((event) {
      if (event == PhoneStateStatus.CALL_ENDED) {
        _fetchCallLogs(); 
      }
    });
  }

  Future<void> _fetchCallLogs() async {
    if (await Permission.phone.isGranted) {
      final Iterable<CallLogEntry> logs = await CallLog.get();
      setState(() {
        _callLogs = logs.toList();
      });
    }
  }

  Future<void> _fetchContacts() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      setState(() => _permissionDenied = true);
    } else {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      contacts.sort((a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
      setState(() {
        _contacts = contacts;
        _filteredContacts = List<Contact>.from(contacts);
      });
    }
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
      _filteredContacts = _contacts
          .where((c) =>
              c.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _filteredContacts.sort((a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 10),
              _buildFilterButtons(),
              const SizedBox(height: 10),
              Expanded(
                child: showContacts
                    ? _buildContactsView()
                    : _buildRecentLogView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Custom Search Bar
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

  // 🔹 Toggle buttons
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

  // 🔹 Contacts View
  Widget _buildContactsView() {
    if (_permissionDenied) {
      return const Center(
        child: Text("Permission denied",
            style: TextStyle(color: Colors.white)),
      );
    }

    if (_contacts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_filteredContacts.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Text("No contacts found",
            style: TextStyle(color: Colors.white.withOpacity(0.7))),
      );
    }

    final Map<String, List<Contact>> grouped = {};
    for (final c in _filteredContacts) {
      final letter =
          c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : "#";
      grouped.putIfAbsent(letter, () => []).add(c);
    }
    final sortedLetters = grouped.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedLetters.length,
      itemBuilder: (context, i) {
        final letter = sortedLetters[i];
        final contacts = grouped[letter]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...contacts.map((c) {
              final firstLetter =
                  c.displayName.isNotEmpty ? c.displayName[0] : "?";
              return Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 15.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 4),
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
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    c.phones.isNotEmpty ? c.phones.first.number : "(no number)",
                    style:
                        TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  // 🔹 Recent Log View
  Widget _buildRecentLogView() {
    if (_callLogs.isEmpty) {
      return const Center(
        child: Text("No call logs found",
            style: TextStyle(color: Colors.white)),
      );
    }

    final Map<String, List<CallLogEntry>> grouped = {};
    for (final log in _callLogs) {
      if (log.timestamp == null) continue;
      final date =
          _formatDate(DateTime.fromMillisecondsSinceEpoch(log.timestamp!));
      grouped.putIfAbsent(date, () => []).add(log);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grouped.entries
            .map((entry) => _buildLogSection(entry.key, entry.value))
            .toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildLogSection(String title, List<CallLogEntry> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
          child: Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ),
        _buildCallLogGroup(logs),
      ],
    );
  }

  Widget _buildCallLogGroup(List<CallLogEntry> calls) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: calls.asMap().entries.map((entry) {
          final index = entry.key;
          final call = entry.value;
          final name = call.name ?? call.number ?? 'Unknown';
          final firstLetter = name.isNotEmpty ? name[0] : "?";
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15, vertical: 4),
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
                        color: _getCallColor(call.callType),
                        size: 16),
                    const SizedBox(width: 4),
                    Text(
                        call.timestamp != null
                            ? _formatTime(call.timestamp!)
                            : "--:--",
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 14)),
                  ],
                ),
              ),
              if (index < calls.length - 1)
                const Divider(
                    color: Color(0xFF333333),
                    height: 1,
                    indent: 70,
                    endIndent: 15),
            ],
          );
        }).toList(),
      ),
    );
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