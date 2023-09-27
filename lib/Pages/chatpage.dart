import 'dart:async';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final name;
  final id;

  const ChatPage({super.key, this.name, this.id});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> _messages = [];
  final StreamController<List<Map<String, dynamic>>> _messageStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage(String text) {
    final newMessage = {
      'text': text,
      'sender': 'User', // You can change this to represent different senders
      'timestamp': DateTime.now(),
    };

    setState(() {
      _messages.add(newMessage);
      _messageStreamController.sink.add(_messages);
    });
    _messageController.clear();
  }

  @override
  void dispose() {
    _messageStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios), onPressed: (){Navigator.pop(context);},),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messageStreamController.stream,
              initialData: _messages,
              builder: (context, snapshot) {
                final messages = snapshot.data!;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isUserMessage = message['sender'] == 'User';
    
                    return ListTile(
                      title: Text(message['text']),
                      subtitle: Text(
                        "${isUserMessage ? 'You' : 'Sender'} - ${message['timestamp'].toString()}",
                      ),
                      trailing: Icon(
                        isUserMessage ? Icons.arrow_forward : Icons.arrow_back,
                        color: isUserMessage ? Colors.blue : Colors.green,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      _sendMessage(_messageController.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageWidget extends StatelessWidget {
  final String text;
  final bool isCurrentUser;

  MessageWidget({
    super.key,
    required this.text,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Material(
        borderRadius: BorderRadius.circular(10.0),
        elevation: 5.0,
        color: isCurrentUser ? Colors.blue : Colors.green,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
            ),
          ),
        ),
      ),
    );
  }
}
