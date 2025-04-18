import 'package:flutter/material.dart';

class CallsPage extends StatefulWidget {
  const CallsPage({Key? key}) : super(key: key);

  @override
  State<CallsPage> createState() => _PhoneAppPageState();
}

class _PhoneAppPageState extends State<CallsPage> {
  bool showContacts = false;

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
                child: showContacts ? _buildContactsView() : _buildRecentLogView(),
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
            child: const Center(
              child: Text(
                "",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
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

  Widget _buildToggleButton(String title, IconData icon, bool isActive, VoidCallback onTap) {
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContactSection('Favourites', [
            ContactItem(name: 'Mumma', location: 'Mumbai, Maharashtra'),
            ContactItem(name: 'Pappa', location: 'Mumbai, Maharashtra'),
            ContactItem(name: 'Didi', location: 'Pune, Maharashtra'),
            ContactItem(name: 'Best Friend', location: 'Delhi, NCR'),
          ]),
          _buildContactSection('A', [
            ContactItem(name: 'Aarya Pawar', location: 'Mumbai, Maharashtra'),
            ContactItem(name: 'Aadit', location: 'Bangalore, Karnataka'),
            ContactItem(name: 'Abhishek', location: 'Mumbai, Maharashtra'),
            ContactItem(name: 'Abhimanyu', location: 'Delhi, NCR'),
            ContactItem(name: 'Aditi Sharma', location: 'Bengaluru, Karnataka'),
            ContactItem(name: 'Ajay Devgan', location: 'Mumbai, Maharashtra'),
            ContactItem(name: 'Akash Patel', location: 'Ahmedabad, Gujarat'),
            ContactItem(name: 'Akshay Kumar', location: 'Mumbai, Maharashtra'),
            ContactItem(name: 'Aman Singh', location: 'Chennai, Tamil Nadu'),
            ContactItem(name: 'Amit Shah', location: 'Delhi, NCR'),
          ]),
          _buildContactSection('B', [
            ContactItem(name: 'Bhavesh Joshi', location: 'Mumbai, Maharashtra'),
            ContactItem(name: 'Bharat Kumar', location: 'Jaipur, Rajasthan'),
            ContactItem(name: 'Bindu Madhavi', location: 'Hyderabad, Telangana'),
          ]),
          _buildContactSection('C', [
            ContactItem(name: 'Chirag Patel', location: 'Surat, Gujarat'),
            ContactItem(name: 'Chetan Bhagat', location: 'Mumbai, Maharashtra'),
            ContactItem(name: 'Chandrika Devi', location: 'Patna, Bihar'),
          ]),
          _buildContactSection('D', [
            ContactItem(name: 'Deepak Chahar', location: 'Mumbai, Maharashtra'),
            ContactItem(name: 'Divya Khosla', location: 'Mumbai, Maharashtra'),
          ]),
        ],
      ),
    );
  }

  Widget _buildContactSection(String title, List<ContactItem> contacts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _buildContactGroup(contacts),
      ],
    );
  }

  Widget _buildContactGroup(List<ContactItem> contacts) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: contacts.asMap().entries.map((entry) {
          final index = entry.key;
          final contact = entry.value;
          final firstLetter = contact.name.isNotEmpty ? contact.name[0] : "?";

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF333333),
                  child: Text(
                    firstLetter,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(contact.name,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                subtitle: Text(contact.location,
                    style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              ),
              if (index < contacts.length - 1)
                const Divider(color: Color(0xFF333333), height: 1, indent: 70, endIndent: 15),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentLogView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogSection('Today', [
            CallLogItem(name: 'Inshrah Khatri', time: '13:45', isOutgoing: true),
            CallLogItem(name: 'Shweta Behera', time: '12:15', isOutgoing: true),
            CallLogItem(name: 'Aarya Pawar', time: '10:30', isOutgoing: true),
            CallLogItem(name: 'Mumma', time: '09:10', isOutgoing: false),
            CallLogItem(name: 'Pappa', time: '08:37', isOutgoing: true),
            CallLogItem(name: 'Akash Patel', time: '08:15', isOutgoing: false),
            CallLogItem(name: 'Office', time: '07:45', isOutgoing: true),
            CallLogItem(name: 'Chirag Patel', time: '07:22', isOutgoing: false),
            CallLogItem(name: 'Aman Singh', time: '06:50', isOutgoing: true),
            CallLogItem(name: 'Aditi Sharma', time: '06:15', isOutgoing: false),
          ]),
          _buildLogSection('Yesterday', [
            CallLogItem(name: 'Inshrah Khatri', time: '21:45', isOutgoing: true),
            CallLogItem(name: 'Shweta Behera', time: '19:15', isOutgoing: false),
            CallLogItem(name: 'Best Friend', time: '18:30', isOutgoing: true),
            CallLogItem(name: 'Ajay Devgan', time: '17:22', isOutgoing: false),
            CallLogItem(name: 'Didi', time: '16:05', isOutgoing: true),
            CallLogItem(name: 'Bharat Kumar', time: '15:40', isOutgoing: false),
            CallLogItem(name: 'Deepak Chahar', time: '14:30', isOutgoing: true),
            CallLogItem(name: 'Amit Shah', time: '13:15', isOutgoing: false),
            CallLogItem(name: 'Chandrika Devi', time: '11:10', isOutgoing: true),
            CallLogItem(name: 'Bindu Madhavi', time: '10:05', isOutgoing: false),
          ]),
          _buildLogSection('This Week', [
            CallLogItem(name: 'Aaryan Sharma', time: 'Wed', isOutgoing: true),
            CallLogItem(name: 'Abhishek Gupta', time: 'Wed', isOutgoing: false),
            CallLogItem(name: 'Akshay Kumar', time: 'Tue', isOutgoing: true),
            CallLogItem(name: 'Chetan Bhagat', time: 'Tue', isOutgoing: false),
            CallLogItem(name: 'Divya Khosla', time: 'Mon', isOutgoing: true),
          ]),
        ],
      ),
    );
  }

  Widget _buildLogSection(String title, List<CallLogItem> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
          child: Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        _buildCallLogGroup(logs),
      ],
    );
  }

  Widget _buildCallLogGroup(List<CallLogItem> calls) {
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
          final firstLetter = call.name.isNotEmpty ? call.name[0] : "?";

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF333333),
                  child: Text(
                    firstLetter,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(call.name,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                subtitle: Row(
                  children: [
                    Icon(call.isOutgoing ? Icons.call_made : Icons.call_received,
                        color: call.isOutgoing ? Colors.green : Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text(call.time,
                        style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  ],
                ),
              ),
              if (index < calls.length - 1)
                const Divider(color: Color(0xFF333333), height: 1, indent: 70, endIndent: 15),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class ContactItem {
  final String name;
  final String location;

  ContactItem({required this.name, required this.location});
}

class CallLogItem {
  final String name;
  final String time;
  final bool isOutgoing;

  CallLogItem({required this.name, required this.time, required this.isOutgoing});
}