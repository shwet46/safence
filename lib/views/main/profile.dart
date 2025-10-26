import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safence/providers/firebase_auth_provider.dart';
import 'package:safence/components/auth_popup.dart';
import 'package:safence/utils/constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _username = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final ok = await showAuthPopup(context);
              if (ok == true) setState(() {});
            },
            child: const Text('Sign in / Create account'),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Constants.darkThemeBg,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => context.read<FirebaseAuthProvider>().signOut(),
            icon: const Icon(Icons.logout, color: Colors.white70),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          _username.text = data?['username'] ?? user.displayName ?? '';
          _email.text = data?['email'] ?? user.email ?? '';

          final displayName = _username.text.isNotEmpty ? _username.text : (user.displayName ?? 'No name');
          final emailText = _email.text.isNotEmpty ? _email.text : (user.email ?? 'No email');

          String initials() {
            final parts = displayName.split(' ');
            if (parts.isEmpty) return '';
            if (parts.length == 1) return parts.first.characters.first.toUpperCase();
            return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: const Color(0xFF0F0F0F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: const Color(0xFF2A2A2A),
                          child: Text(initials(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(emailText, style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8952D4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            ),
                            icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                            label: const Text('Edit', style: TextStyle(color: Colors.white)),
                            onPressed: () => _showEditSheet(context, user.uid, displayName, emailText),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Card(
                  color: const Color(0xFF0F0F0F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Account', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person, color: Colors.white70),
                          title: Text(displayName, style: const TextStyle(color: Colors.white)),
                          subtitle: const Text('Username', style: TextStyle(color: Colors.white38)),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.email, color: Colors.white70),
                          title: Text(emailText, style: const TextStyle(color: Colors.white)),
                          subtitle: const Text('Email', style: TextStyle(color: Colors.white38)),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showEditSheet(context, user.uid, displayName, emailText),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit profile'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8952D4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.read<FirebaseAuthProvider>().signOut(),
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    label: const Text('Sign out', style: TextStyle(color: Colors.white70)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF222222), padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, String uid, String currentName, String currentEmail) {
    final nameController = TextEditingController(text: currentName == 'No name' ? '' : currentName);
    final emailController = TextEditingController(text: currentEmail == 'No email' ? '' : currentEmail);
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F0F0F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: controller,
                children: [
                  Center(child: Container(width: 40, height: 4, color: Colors.white12)),
                  const SizedBox(height: 12),
                  const Text('Edit profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Username',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF222222),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF222222),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: StatefulBuilder(builder: (context, setStateSB) {
                      return ElevatedButton(
                        onPressed: saving ? null : () async {
                          setStateSB(() => saving = true);
                          try {
                            await FirebaseFirestore.instance.collection('users').doc(uid).set({
                              'username': nameController.text.trim(),
                              'email': emailController.text.trim(),
                              'updatedAt': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              await user.updateDisplayName(nameController.text.trim());
                              if (emailController.text.trim().isNotEmpty && emailController.text.trim() != user.email) {
                                try {
                                  await user.updateEmail(emailController.text.trim());
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email update failed: $e')));
                                }
                              }
                            }
                            if (mounted) Navigator.of(context).pop();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          } finally {
                            setStateSB(() => saving = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8952D4)),
                        child: saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save changes'),
                      );
                    }),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}