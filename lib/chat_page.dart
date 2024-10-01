import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String roomId;

  const ChatPage({Key? key, required this.roomId}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  String? currentUserId;
  String? otherUserId;
  String? otherUsername;
  String? otherUserAvatarUrl;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messagesStream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomId)
        .order('created_at', ascending: true)
        .map((event) => event.map((e) => e as Map<String, dynamic>).toList());
    
    _listenToMessages();
    _fetchChatRoomDetails();
    
    // Add this line to scroll to the bottom when new messages are added
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _fetchChatRoomDetails() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('chat_rooms')
        .select()
        .eq('id', widget.roomId)
        .single();

    setState(() {
      currentUserId = user.id;
      if (currentUserId == response['user1_id']) {
        otherUserId = response['user2_id'];
        otherUsername = response['user2_name'];
        otherUserAvatarUrl = response['user2_avatar_url'];
      } else {
        otherUserId = response['user1_id'];
        otherUsername = response['user1_name'];
        otherUserAvatarUrl = response['user1_avatar_url'];
      }
    });
  }

  void _listenToMessages() {
    _messagesStream.listen((messages) {
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageContent = _messageController.text.trim();
    _messageController.clear(); // Clear the input field immediately

    final newMessage = {
      'room_id': widget.roomId,
      'sender_id': currentUserId,
      'content': messageContent,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Optimistically add the message to the local list
    final optimisticMessage = Map<String, dynamic>.from(newMessage)
      ..['id'] = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    setState(() {
      _messages.add(optimisticMessage);
    });

    try {
      // Send the message to Supabase
      final response = await Supabase.instance.client
          .from('messages')
          .insert(newMessage)
          .select()
          .single();
      
      // Update the chat room's last message and timestamp
      await Supabase.instance.client
          .from('chat_rooms')
          .update({
            'last_message': messageContent,
            'last_updated': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.roomId);

      print('Message sent successfully');
      
      // Update the local message with the actual data from the server
      setState(() {
        final index = _messages.indexWhere((m) => m['id'] == optimisticMessage['id']);
        if (index != -1) {
          _messages[index] = response;
        }
      });
    } catch (e) {
      print('Error sending message: $e');
      String errorMessage = 'Failed to send message. Please try again.';
      if (e is PostgrestException) {
        errorMessage = 'Database error: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      
      // Remove the optimistically added message if there was an error
      setState(() {
        _messages.removeWhere((m) => m['id'] == optimisticMessage['id']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: otherUserAvatarUrl != null 
                ? NetworkImage(otherUserAvatarUrl!)
                : AssetImage('assets/default_avatar.png') as ImageProvider,
              radius: 20,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherUsername ?? 'Loading...',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
                Text(
                  'Online',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: ListView.builder(
                itemCount: _messages.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isCurrentUser = message['sender_id'] == currentUserId;
                  return _buildMessageItem(message, isCurrentUser, index);
                },
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message, bool isCurrentUser, int index) {
    return Column(
      crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (index == 0 || _shouldShowDateSeparator(index))
          _buildDateSeparator(message['created_at']),
        _buildMessageBubble(message, isCurrentUser),
      ],
    );
  }

  Widget _buildDateSeparator(String dateString) {
    final date = DateTime.parse(dateString).toLocal();
    final formattedDate = DateFormat('MMMM d').format(date);
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          formattedDate,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ),
    );
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;
    final currentDate = DateTime.parse(_messages[index]['created_at']).toLocal();
    final previousDate = DateTime.parse(_messages[index - 1]['created_at']).toLocal();
    return !isSameDay(currentDate, previousDate);
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isCurrentUser) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentUser ? Color(0xFFF4845F) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message['content'],
                  style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black, fontSize: 20,fontStyle: FontStyle.normal),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(DateTime.parse(message['created_at']).toLocal()),
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF4845F),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
}
