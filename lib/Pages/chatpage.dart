import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:chat_bubbles/chat_bubbles.dart';

class ChatPage extends StatefulWidget {
  final name;
  final id;

  const ChatPage({super.key, this.name, this.id});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final FocusNode _focusNode = FocusNode(
    onKey: (FocusNode node, RawKeyEvent evt) {
      if (!evt.isShiftPressed && evt.logicalKey.keyLabel == 'Enter') {
        if (evt is RawKeyDownEvent) {
          if (_messageController.text.isNotEmpty) {
            _sendMessage(_messageController.text);
          }
        }
        return KeyEventResult.handled;
      } else {
        return KeyEventResult.ignored;
      }
    },
  );
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
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void dispose() {
    _messageStreamController.close();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
                    return Column(
                      crossAxisAlignment: isUserMessage
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        BubbleNormal(
                          text: message['text'],
                          isSender: isUserMessage ? true : false,
                          color: isUserMessage ? Colors.grey : Colors.green,
                          tail: true,
                        ),
                        Text(
                          DateFormat('HH:mm').format(
                              DateTime.parse(message['timestamp'].toString())),
                          style: TextStyle(fontSize: 10),
                        )
                      ],
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
                    maxLines: null,
                    autofocus: true,
                    focusNode: _focusNode,
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
