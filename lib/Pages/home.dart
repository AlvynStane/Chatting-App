import 'dart:async';
import 'package:amitofo_chatting/Constant/constants.dart';
import 'package:amitofo_chatting/Model/model.dart';
import 'package:amitofo_chatting/Pages/Login/login.dart';
import 'package:amitofo_chatting/Pages/chatpage.dart';
import 'package:amitofo_chatting/Pages/profilepage.dart';
import 'package:amitofo_chatting/Provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();
  final StreamController<bool> btnClearController = StreamController<bool>();

  int _limit = 20;
  final int _limitIncrement = 20;
  final String _textSearch = "";
  bool isLoading = false;

  late final String currentUserId;
  late final AuthProvider authProvider = context.read<AuthProvider>();
  late final HomeProvider homeProvider = context.read<HomeProvider>();

  final List<PopupChoice> choices = [
    PopupChoice(title: 'Profile', icon: Icons.person_2),
    PopupChoice(title: 'Log Out', icon: Icons.logout),
  ];

  @override
  void initState() {
    super.initState();
    if (authProvider.getUserFirebaseId()?.isNotEmpty == true) {
      currentUserId = authProvider.getUserFirebaseId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (Route<dynamic> route) => false,
      );
    }
    listScrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    super.dispose();
    btnClearController.close();
  }

  void scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  void onSelectedChoices(PopupChoice choice) {
    if (choice.title == 'Profile') {
      Navigator.push(context,
          MaterialPageRoute(builder: ((context) => const ProfilePage())));
    } else {
      handleSignOut();
    }
  }

  Future<void> handleSignOut() async {
    authProvider.handleSignOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home Page',
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        actions: [buildAction()],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: homeProvider.getStreamFireStore(
                        FirestoreConstants.pathUserCollection,
                        _limit,
                        _textSearch),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.hasData) {
                        if ((snapshot.data?.docs.length ?? 0) > 0) {
                          return ListView.builder(
                            padding: const EdgeInsets.all(10),
                            itemBuilder: (context, index) =>
                                buildItem(context, snapshot.data?.docs[index]),
                            itemCount: snapshot.data?.docs.length,
                            controller: listScrollController,
                          );
                        } else {
                          return const Center(
                            child: Text(
                              "No users",
                              style:
                                  TextStyle(color: ColorConstants.primaryColor),
                            ),
                          );
                        }
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot? document) {
    if (document != null) {
      UserChat userChat = UserChat.fromDocument(document);
      if (userChat.id == currentUserId) {
        return const SizedBox.shrink();
      } else {
        return Container(
          margin: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: ColorConstants.greyColor2,
          ),
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    arguments: ChatPageArguments(
                      peerId: userChat.id,
                      peerAvatar: userChat.photoUrl,
                      peerNickname: userChat.nickname,
                    ),
                  ),
                ),
              );
            },
            style: ButtonStyle(
              shape: MaterialStateProperty.all<OutlinedBorder>(
                const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
            child: Row(
              children: [
                Material(
                  borderRadius: const BorderRadius.all(Radius.circular(25)),
                  clipBehavior: Clip.hardEdge,
                  child: userChat.photoUrl.isNotEmpty
                      ? Image.network(
                          userChat.photoUrl,
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                          loadingBuilder: (BuildContext context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: 50,
                              height: 50,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, object, stackTrace) {
                            return const Icon(
                              Icons.account_circle,
                              size: 50,
                            );
                          },
                        )
                      : const Icon(
                          Icons.account_circle,
                          size: 50,
                        ),
                ),
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(left: 20),
                    child: Column(
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: const EdgeInsets.fromLTRB(10, 0, 0, 5),
                          child: Text(
                            'Nickname: ${userChat.nickname}',
                            maxLines: 1,
                            style:
                                const TextStyle(color: ColorConstants.primaryColor),
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: Text(
                            'About me: ${userChat.aboutMe}',
                            maxLines: 1,
                            style:
                                const TextStyle(color: ColorConstants.primaryColor),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget buildAction() {
    return PopupMenuButton(
        onSelected: onSelectedChoices,
        itemBuilder: (context) {
          return choices.map((choice) {
            return PopupMenuItem(
              value: choice,
              child: Row(
                children: [
                  Icon(choice.icon, color: ColorConstants.primaryColor),
                  Text(choice.title,
                      style: const TextStyle(color: ColorConstants.primaryColor)),
                ],
              ),
            );
          }).toList();
        });
  }
}
