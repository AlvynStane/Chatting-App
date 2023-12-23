import 'dart:io';
import 'package:amitofo_chatting/Constant/constants.dart';
import 'package:amitofo_chatting/Model/date_util.dart';
import 'package:amitofo_chatting/Model/model.dart';
import 'package:amitofo_chatting/Pages/Login/login.dart';
import 'package:amitofo_chatting/Pages/full_image.dart';
import 'package:amitofo_chatting/Provider/provider.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool isShowSticker = false;
  String imageUrl = "";

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  late final ChatProvider chatProvider = context.read<ChatProvider>();
  late final AuthenProvider authProvider = context.read<AuthenProvider>();

  @override
  void initState() {
    focusNode.addListener(onFocusChange);
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

  void onFocusChange() {
    if (focusNode.hasFocus) {
      setState(() {
        isShowSticker = false;
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

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile = await imagePicker
        .pickImage(source: ImageSource.gallery)
        .catchError((err) {
      Fluttertoast.showToast(msg: err.toString());
      return null;
    });
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      if (imageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadFile();
      }
    }
  }

  void getSticker() {
    if (isShowSticker) {
      focusNode.requestFocus();
      setState(() {
        isShowSticker = !isShowSticker;
      });
    } else {
      focusNode.unfocus();
      setState(() {
        isShowSticker = !isShowSticker;
      });
    }
  }

  Future<void> storagePermission() async {
    if (await Permission.storage.status.isGranted) {
      getImage();
    } else {
      var status = await Permission.storage.request();
      if (status == PermissionStatus.granted) {
        getImage();
      } else if (status == PermissionStatus.permanentlyDenied) {
        await openAppSettings();
      }
    }
  }

  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadTask = chatProvider.uploadFile(imageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, TypeMessage.image);
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
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

  Future<bool> onBackPress() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      chatProvider.updateDataFirestore(
        FirestoreConstants.pathUserCollection,
        currentUserId,
        {FirestoreConstants.chattingWith: null},
      );
      Navigator.pop(context);
    }
    return Future.value(false);
  }

  bool isSameDate(int index) {
    if (index > 0) {
      final DateTime prevTime = DateTime.parse(
          listMessage[index - 1].get(FirestoreConstants.timestamp));
      final DateTime currentTime =
          DateTime.parse(listMessage[index].get(FirestoreConstants.timestamp));
      return DateUtil.isSameDate(currentTime, prevTime);
    } else {
      return true;
    }
  }

  bool isSameTime(int index) {
    if (index > 0) {
      final DateTime prevTime = DateTime.parse(
          listMessage[index - 1].get(FirestoreConstants.timestamp));
      final DateTime currentTime =
          DateTime.parse(listMessage[index].get(FirestoreConstants.timestamp));
      return DateUtil.isSameDate(currentTime, prevTime) &&
          prevTime.hour == currentTime.hour &&
          prevTime.minute == currentTime.minute;
    } else {
      return true;
    }
  }

  Widget buildChat(bool sender, int index, MessageChat message) {
    DateTime messageTime = DateTime.parse(message.timestamp).toLocal();
    return Align(
      alignment: sender ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            sender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          message.type == TypeMessage.text
              ? BubbleNormal(
                  text: message.content,
                  isSender: sender,
                  color: sender
                      ? ColorConstants.greyColor2
                      : ColorConstants.greyColor,
                  tail: true,
                )
              : message.type == TypeMessage.image
                  ? MaterialButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullPhotoPage(
                              url: message.content,
                            ),
                          ),
                        );
                      },
                      child: Material(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        clipBehavior: Clip.hardEdge,
                        child: Container(
                          decoration: BoxDecoration(
                            color: sender
                                ? ColorConstants.greyColor2
                                : ColorConstants.greyColor,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                          ),
                          width: 200,
                          height: 200,
                          child: Image.network(
                            fit: BoxFit.contain,
                            message.content,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Center(
                                child: CircularProgressIndicator(
                                  color: ColorConstants.themeColor,
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, object, stackTrace) {
                              return Material(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: Image.asset(
                                  'images/img_not_available.jpeg',
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                            width: 200,
                            height: 200,
                          ),
                        ),
                      ),
                    )
                  : Image.asset(
                      'images/${message.content}.gif',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
          if (!isSameTime(index) || index == 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                DateFormat.Hm().format(messageTime),
                style:
                    const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget buildItem(int index, DocumentSnapshot? document) {
    if (document != null) {
      MessageChat messageChat = MessageChat.fromDocument(document);

      if (messageChat.idFrom == currentUserId) {
        return buildChat(true, index, messageChat);
      } else {
        return buildChat(false, index, messageChat);
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget buildInput() {
    return Stack(
      children: [
        Container(
          height: 50,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(width: 0.5),
            ),
            // borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Row(
            children: <Widget>[
              Material(
                shape: const CircleBorder(side: BorderSide.none),
                color: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: storagePermission,
                  color: ColorConstants.primaryColor,
                ),
              ),
              Material(
                shape: const CircleBorder(side: BorderSide.none),
                color: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: ColorConstants.primaryColor,
                  onPressed: getSticker,
                ),
              ),
              Expanded(
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
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Material(
              shape: const CircleBorder(
                  side: BorderSide(width: 2, color: ColorConstants.themeColor)),
              color: ColorConstants.themeColor,
              child: IconButton(
                icon: const Icon(Icons.send_rounded),
                color: Colors.white,
                onPressed: () =>
                    onSendMessage(textEditingController.text, TypeMessage.text),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDateHeader(DateTime dateTime) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.black87,
          ),
          height: 20,
          width: 130,
          child: Center(
            child: Text(
              DateUtil.dateWithDayFormat(dateTime),
              style: const TextStyle(
                color: ColorConstants.greyColor,
                fontSize: 12.0,
              ),
            ),
          ),
        ),
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
                      itemBuilder: (context, index) {
                        final DateTime currentTime = DateTime.parse(
                            listMessage[index]
                                .get(FirestoreConstants.timestamp));
                        if (index < listMessage.length - 1) {
                          final DateTime nextTime = DateTime.parse(
                              listMessage[index + 1]
                                  .get(FirestoreConstants.timestamp));
                          if (!DateUtil.isSameDate(nextTime, currentTime)) {
                            return Column(
                              children: [
                                buildDateHeader(currentTime),
                                buildItem(index, snapshot.data?.docs[index]),
                              ],
                            );
                          }
                        } else {
                          return Column(
                            children: [
                              buildDateHeader(currentTime),
                              buildItem(index, snapshot.data?.docs[index]),
                            ],
                          );
                        }
                        return buildItem(index, snapshot.data?.docs[index]);
                      },
                      itemCount: snapshot.data?.docs.length,
                      reverse: true,
                      controller: listScrollController,
                    );
                  } else {
                    return const Center(child: Text("No message here yet..."));
                  }
                } else {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ColorConstants.themeColor,
                    ),
                  );
                }
              },
            )
          : const Center(
              child: CircularProgressIndicator(
                color: ColorConstants.themeColor,
              ),
            ),
    );
  }

  Widget buildSticker() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
            border: Border(
                top: BorderSide(color: ColorConstants.greyColor2, width: 0.5)),
            color: Colors.white),
        padding: const EdgeInsets.all(5),
        height: 180,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                buildStickerButton('mimi1'),
                buildStickerButton('mimi2'),
                buildStickerButton('mimi3'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                buildStickerButton('mimi4'),
                buildStickerButton('mimi5'),
                buildStickerButton('mimi6'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                buildStickerButton('mimi7'),
                buildStickerButton('mimi8'),
                buildStickerButton('mimi9'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStickerButton(String stickerName) {
    return TextButton(
      onPressed: () => onSendMessage(stickerName, TypeMessage.sticker),
      child: Image.asset(
        'images/$stickerName.gif',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
    );
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
                  isShowSticker ? buildSticker() : const SizedBox.shrink(),
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
