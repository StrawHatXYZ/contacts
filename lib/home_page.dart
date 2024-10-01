import 'package:contacts/chat_page.dart';
import 'package:contacts/rooms_page.dart';
import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'contacts_page.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  List<Map<String, dynamic>> posts = [];

  @override
  void initState() {
    super.initState();
    _listenToPostChanges();
  }

  void _listenToPostChanges() {
    Supabase.instance.client
      .from('posts')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .listen((List<Map<String, dynamic>> data) {
        // Update the posts list and rebuild the UI
        setState(() {
          posts = data;
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user
    final user = Supabase.instance.client.auth.currentUser;
    final username = user?.userMetadata?['username'] as String? ?? 'User';

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomePage(context, username),
          const ContactsPage(),
          const RoomsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Contacts'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
        ],
        selectedItemColor: const Color(0xFFF4845F),
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildHomePage(BuildContext context, String username) {
    print('Username: $username');
    return Scaffold(
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
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
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
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _buildContactCard(
                    post['username'] ?? 'Unknown User',
                    _formatTimestamp(post['created_at']),
                    post['content'] ?? '',
                    post['phone'] ?? '',
                    post['avatar_url'] ?? 'https://via.placeholder.com/150',
                    post['user_id'] ?? '',
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewPostBottomSheet(context, username);
        },
        backgroundColor: const Color(0xFFF4845F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showNewPostBottomSheet(BuildContext context, String username) {
    String postContent = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Make A Wish",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage('https://ui-avatars.com/api/?background=0D8ABC&color=fff&name=${Uri.encodeComponent(username)}&rounded=true'),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    username,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                maxLines: 5,
                onChanged: (value) => postContent = value,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _addPost(context, username, postContent);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF4845F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Post', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addPost(BuildContext context, String username, String content) async {
    final user = Supabase.instance.client.auth.currentUser;
    final phone = user?.userMetadata?['phone'] as String? ?? '';
    try {
     final initials = username.split(' ').map((word) => word[0]).take(2).join('').toUpperCase();
    
    await Supabase.instance.client.from('posts').insert({
      'username': username,
      'content': content,
      'phone': phone,
      'user_id': user?.id,
      'avatar_url': 'https://ui-avatars.com/api/?background=0D8ABC&color=fff&name=$initials&rounded=true',
    });
      
      // Close the bottom sheet
      Navigator.pop(context);
      
      // Show success message
      _showSuccessMessage(context);
    } catch (e) {
      // Handle any errors, e.g., show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add post: $e')),
      );
    }
  }

  void _showSuccessMessage(BuildContext context) {
    OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.1,
        width: MediaQuery.of(context).size.width,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Post added successfully',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Remove the overlay after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Widget _buildContactCard(String name, String time, String message, String phone, String avatarUrl, String user_id) {
    // Get the current user's username
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentUsername = currentUser?.userMetadata?['username'] as String? ?? 'User';
    final currentUserId = currentUser?.id ?? '';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(message, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              if (name != currentUsername) // Only show icons if it's not the current user's post
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.phone, color: Color(0xFFF4845F), size: 24),
                      onPressed: () {/* TODO: Implement phone action */},
                    ),
                    IconButton(
                      icon: const Icon(Icons.message, color: Color(0xFFF4845F), size: 24),
                      onPressed: () async {
                        // Sort user IDs to ensure consistency
                        final sortedUserIds = [currentUserId, user_id]..sort();
                        final chatRoomId = Uuid().v5(Uuid.NAMESPACE_URL, sortedUserIds.join('_'));
                        
                        // Create or get the room
                        await Supabase.instance.client.from('chat_rooms').upsert({
                          'id': chatRoomId,
                          'user1_id': sortedUserIds[0],
                          'user2_id': sortedUserIds[1],
                          'user1_name': sortedUserIds[0] == currentUserId ? currentUsername : name,
                          'user2_name': sortedUserIds[1] == currentUserId ? currentUsername : name,
                          'user1_avatar_url': 'https://ui-avatars.com/api/?background=0D8ABC&color=fff&name=${Uri.encodeComponent(sortedUserIds[0] == currentUserId ? currentUsername : name)}&rounded=true',
                          'user2_avatar_url': 'https://ui-avatars.com/api/?background=0D8ABC&color=fff&name=${Uri.encodeComponent(sortedUserIds[1] == currentUserId ? currentUsername : name)}&rounded=true',
                        });

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChatPage(
                            roomId: chatRoomId,
                          )),
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown time';
    final dateTime = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}