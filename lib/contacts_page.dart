import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Map<String, dynamic>> contacts = [];
  List<Map<String, dynamic>> filteredContacts = [];
  List<Contact>? deviceContacts;
  String username = '';

  @override
  void initState() {
    super.initState();
    _loadContactsFromLocalStorage();
    _syncContactsWithSupabase();
    _loadUsername();
  }

  Future<void> _loadContactsFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getString('contacts');
    if (contactsJson != null) {
      setState(() {
        contacts = List<Map<String, dynamic>>.from(json.decode(contactsJson));
        filteredContacts = List.from(contacts); // Add this line
      });
    }
  }

  Future<void> _syncContactsWithSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('contacts')
          .select()
          .eq('user_id', user.id)
          .order('name', ascending: true);

      final newContacts = response as List<Map<String, dynamic>>;
      
      // Merge new contacts with existing ones
      final mergedContacts = [...contacts, ...newContacts];
      
      // Remove duplicates based on phone number
      final uniqueContacts = mergedContacts.fold<List<Map<String, dynamic>>>(
        [],
        (List<Map<String, dynamic>> uniqueList, Map<String, dynamic> contact) {
          if (!uniqueList.any((c) => c['phone'] == contact['phone'])) {
            uniqueList.add(contact);
          }
          return uniqueList;
        },
      );

      setState(() {
        contacts = uniqueContacts;
        filteredContacts = List.from(contacts); // Add this line
      });

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('contacts', json.encode(contacts));
    }
  }

  Future<void> _importDeviceContacts() async {
    print('Importing device contacts');
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      if (await FlutterContacts.requestPermission(readonly: true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact permission granted')),
        );
        final deviceContacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: true,
          withThumbnail: true,
        );

        for (final contact in deviceContacts) {
          final phoneNumber = contact.phones.isNotEmpty ? contact.phones.first.number : null;
          if (phoneNumber != null) {
            //there is a contacts supabase table , if phone number with user_id already exists, skip it
            final response = await Supabase.instance.client
                .from('contacts')
                .select()
                .eq('phone', phoneNumber)
                .eq('user_id', user.id);
            if (response.isEmpty) {
              print('Inserting contact: ${contact.name.first}');
              await Supabase.instance.client.from('contacts').insert({
                'user_id': user.id,
                'name': contact.name.first,
                'phone': phoneNumber,
                'avatar_url': contact.photo,
              });
            } else {
              print('Contact already exists: ${contact.name.first}, ${contact.phones.first.number}');
            }
          }
        }

        // After successfully importing contacts
        await _syncContactsWithSupabase();

        // Reload contacts after import
      } else {
        // Handle permission denied
        print('Contact permission denied');
      }
    } catch (e) {
      print('Error importing contacts: $e');
      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import contacts: $e')),
      );
    }
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredContacts = List.from(contacts);
      } else {
        filteredContacts = contacts.where((contact) {
          final name = contact['name']?.toString().toLowerCase() ?? '';
          final phone = contact['phone']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || phone.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _loadUsername() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        username = user.userMetadata?['username'] ?? 'User';
        print('Username: $username');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search contacts...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: _filterContacts,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF4845F), width: 2),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfilePage()),
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        backgroundImage: NetworkImage('https://ui-avatars.com/api/?background=0D8ABC&color=fff&name=${Uri.encodeComponent(username)}&rounded=true'),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredContacts.isEmpty
                  ? Center(
                      child: Text(
                        'No contacts found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = filteredContacts[index];
                        return _buildContactCard(
                          contact['name'] ?? 'Unknown User',
                          contact['phone'] ?? 'No phone number',
                          contact['avatar_url'],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importDeviceContacts,
        backgroundColor: const Color(0xFFF4845F),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildContactCard(String name, String phone, dynamic avatar) {
    return Card(
      elevation: 3,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFFF0EB)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFFFF0EB), // Light orange background
                child: Icon(Icons.person, color: Color(0xFFF4845F), size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(phone, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.phone, color: Color(0xFFF4845F), size: 24),
                    onPressed: () => launch('tel:$phone'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.message, color: Color(0xFFF4845F), size: 24),
                    onPressed: () => launch('sms:$phone'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}