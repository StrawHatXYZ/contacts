import 'package:contacts/home_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_page.dart';

class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

  @override
  _RoomsPageState createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  late final String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser!.id;
  }

  Future<List<Map<String, dynamic>>> _fetchRooms() async {
    final response = await Supabase.instance.client
        .from('chat_rooms')
        .select()
        .or('user1_id.eq.$_currentUserId,user2_id.eq.$_currentUserId')
        .order('last_updated', ascending: false);
    return response;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.chat, color: Colors.black),
            SizedBox(width: 8),
            Text('Chats', style: TextStyle(color: Colors.black)),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed:() {
            Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
          },
        ),
        backgroundColor: Colors.white,
        elevation: 4,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchRooms(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rooms = snapshot.data!;
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final isUser1 = room['user1_id'] == _currentUserId;
              final otherUserName = isUser1 ? room['user2_name'] : room['user1_name'];
              final otherUserAvatar = isUser1 ? room['user2_avatar_url'] : room['user1_avatar_url'];
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: otherUserAvatar != null ? NetworkImage(otherUserAvatar) : null,
                  child: otherUserAvatar == null ? Text(otherUserName[0]) : null,
                ),
                title: Text(otherUserName),
                subtitle: Text(room['last_message'] ?? 'No messages yet'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChatPage(roomId: room['id']),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}