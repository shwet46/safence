import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactDetailPage extends StatelessWidget {
  final Contact contact;
  const ContactDetailPage({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    final name = contact.displayName;
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((s) => s.characters.first).take(2).join().toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        title: Text(name.isNotEmpty ? name : 'Contact'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFF222222),
              backgroundImage: contact.photo == null ? null : MemoryImage(contact.photo!),
              child: contact.photo == null ? Text(initials, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)) : null,
            ),
            const SizedBox(height: 12),
            Text(name.isNotEmpty ? name : 'No name', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (contact.phones.isNotEmpty) ...[
              const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(bottom:8.0), child: Text('Phone numbers', style: TextStyle(color: Colors.white70)))) ,
              ...contact.phones.map((p) => _buildPhoneTile(context, p)),
            ],
            if (contact.emails.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(bottom:8.0), child: Text('Emails', style: TextStyle(color: Colors.white70)))) ,
              ...contact.emails.map((e) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email, color: Colors.white70),
                      title: Text(e.address, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(e.label.toString(), style: const TextStyle(color: Colors.white38)),
                    )),
            ],
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check),
              label: const Text('Done'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8952D4),
                foregroundColor: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneTile(BuildContext context, Phone phone) {
    final number = phone.number;
    final rawLabel = phone.label.toString();
    final labelText = (rawLabel.toLowerCase() == 'mobile') ? '' : rawLabel;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.phone, color: Colors.white70),
      title: Text(number, style: const TextStyle(color: Colors.white)),
      subtitle: Text(labelText, style: const TextStyle(color: Colors.white38)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _launchTel(number),
            icon: const Icon(Icons.call, color: Color(0xFF8952D4)),
          ),
          IconButton(
            onPressed: () => _launchSms(number),
            icon: const Icon(Icons.message, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Future<void> _launchTel(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchSms(String number) async {
    final uri = Uri(scheme: 'sms', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}