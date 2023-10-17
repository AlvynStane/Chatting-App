import 'dart:io';
import 'package:amitofo_chatting/Constant/firebase_constants.dart';
import 'package:amitofo_chatting/Model/message_chat.dart';
import 'package:amitofo_chatting/Pages/Login/login.dart';
import 'package:amitofo_chatting/Provider/auth_provider.dart';
import 'package:amitofo_chatting/Provider/chat_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.arguments});

  final ChatPageArguments arguments;

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  late final String currentUserId;

  List<QueryDocumentSnapshot> listMessage = [];
  int _limit = 20;
  final int _limitIncrement = 20;
  String groupChatId = "";

  File? imageFile;
  bool isLoading = false;
  String imageUrl = "";

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  late final ChatProvider chatProvider = context.read<ChatProvider>();
  late final AuthProvider authProvider = context.read<AuthProvider>();

  @override
  void initState() {
    super.initState();
    listScrollController.addListener(_scrollListener);
    readLocal();
  }

  _scrollListener() {
    if (!listScrollController.hasClients) return;
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange &&
        _limit <= listMessage.length) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void readLocal() {
    if (authProvider.getUserFirebaseId()?.isNotEmpty == true) {
      currentUserId = authProvider.getUserFirebaseId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (Route<dynamic> route) => false,
      );
    }
    String peerId = widget.arguments.peerId;
    if (currentUserId.compareTo(peerId) > 0) {
      groupChatId = '$currentUserId-$peerId';
    } else {
      groupChatId = '$peerId-$currentUserId';
    }

    chatProvider.updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      currentUserId,
      {FirestoreConstants.chattingWith: peerId},
    );
  }

  void onSendMessage(String content, int type) {
    if (content.trim().isNotEmpty) {
      textEditingController.clear();
      chatProvider.sendMessage(
          content, type, groupChatId, currentUserId, widget.arguments.peerId);
      if (listScrollController.hasClients) {
        listScrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  Widget buildItem(int index, DocumentSnapshot? document) {
    if (document != null) {
      MessageChat messageChat = MessageChat.fromDocument(document);
      if (messageChat.idFrom == currentUserId) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
              width: 200,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              margin: EdgeInsets.only(
                  bottom: isLastMessageRight(index) ? 20 : 10, right: 10),
              child: Text(
                messageChat.content,
              ),
            )
          ],
        );
      } else {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                    width: 200,
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(8)),
                    margin: const EdgeInsets.only(left: 10),
                    child: Text(
                      messageChat.content,
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
              isLastMessageLeft(index)
                  ? Container(
                      margin:
                          const EdgeInsets.only(left: 50, top: 5, bottom: 5),
                      child: Text(
                        DateFormat('dd MMM kk:mm').format(
                            DateTime.fromMillisecondsSinceEpoch(
                                int.parse(messageChat.timestamp))),
                        style: const TextStyle(
                            fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    )
                  : const SizedBox.shrink()
            ],
          ),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget buildInput() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(width: 0.5)), color: Colors.white),
      child: Row(
        children: <Widget>[
          Flexible(
            child: TextField(
              onSubmitted: (value) {
                onSendMessage(textEditingController.text, TypeMessage.text);
              },
              style: const TextStyle(fontSize: 15),
              controller: textEditingController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Type your message...',
              ),
              focusNode: focusNode,
              autofocus: true,
            ),
          ),
          Material(
            color: Colors.white,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () =>
                    onSendMessage(textEditingController.text, TypeMessage.text),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: chatProvider.getChatStream(groupChatId, _limit),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  listMessage = snapshot.data!.docs;
                  if (listMessage.isNotEmpty) {
                    return ListView.builder(
                      itemBuilder: (context, index) =>
                          buildItem(index, snapshot.data?.docs[index]),
                      padding: const EdgeInsets.all(10),
                      itemCount: snapshot.data?.docs.length,
                      reverse: true,
                      controller: listScrollController,
                    );
                  } else {
                    return const Center(child: Text("No message here yet..."));
                  }
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) ==
                currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) !=
                currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    Navigator.pop(context);
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.arguments.peerNickname),
        centerTitle: true,
      ),
      body: SafeArea(
        child: WillPopScope(
          onWillPop: onBackPress,
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  buildListMessage(),
                  buildInput(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatPageArguments {
  final String peerId;
  final String peerAvatar;
  final String peerNickname;

  ChatPageArguments(
      {required this.peerId,
      required this.peerAvatar,
      required this.peerNickname});
}
