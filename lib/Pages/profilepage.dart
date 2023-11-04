import 'dart:io';

import 'package:amitofo_chatting/Constant/constants.dart';
import 'package:amitofo_chatting/Model/model.dart';
import 'package:amitofo_chatting/Provider/profile_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController? controllerNickname;
  TextEditingController? controllerAboutMe;

  String id = '';
  String nickname = '';
  String aboutMe = '';
  String photoUrl = '';

  bool isLoading = false;
  File? avatarImageFile;
  late final ProfileProvider profileProvider = context.read<ProfileProvider>();

  final FocusNode focusNodeNickname = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    super.initState();
    readLocal();
  }

  void readLocal() {
    setState(() {
      id = profileProvider.getPref(FirestoreConstants.id) ?? "";
      nickname = profileProvider.getPref(FirestoreConstants.nickname) ?? "";
      aboutMe = profileProvider.getPref(FirestoreConstants.aboutMe) ?? "";
      photoUrl = profileProvider.getPref(FirestoreConstants.photoUrl) ?? "";
    });

    controllerNickname = TextEditingController(text: nickname);
    controllerAboutMe = TextEditingController(text: aboutMe);
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.gallery).catchError((err) {
      Fluttertoast.showToast(msg: err.toString());
      return null;
    });
    File? image;
    if (pickedFile != null) {
      image = File(pickedFile.path);
    }
    if (image != null) {
      setState(() {
        avatarImageFile = image;
        isLoading = true;
      });
      uploadFile();
    }
  }

Future uploadFile() async {
    String fileName = id;
    UploadTask uploadTask = profileProvider.uploadFile(avatarImageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();
      UserChat updateInfo = UserChat(
        id: id,
        photoUrl: photoUrl,
        nickname: nickname,
        aboutMe: aboutMe,
      );
      profileProvider
          .updateDataFirestore(FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
          .then((data) async {
        await profileProvider.setPref(FirestoreConstants.photoUrl, photoUrl);
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: "Upload success");
      }).catchError((err) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void handleUpdateData() {
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() {
      isLoading = true;
    });
    UserChat updateInfo = UserChat(
      id: id,
      photoUrl: photoUrl,
      nickname: nickname,
      aboutMe: aboutMe,
    );
    profileProvider
        .updateDataFirestore(FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
        .then((data) async {
      await profileProvider.setPref(FirestoreConstants.nickname, nickname);
      await profileProvider.setPref(FirestoreConstants.aboutMe, aboutMe);
      await profileProvider.setPref(FirestoreConstants.photoUrl, photoUrl);

      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: "Update success");
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });

      Fluttertoast.showToast(msg: err.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: ColorConstants.primaryColor),),
        centerTitle: true,
      ),
      body:Stack(
        children:[
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children:[
                CupertinoButton(
                  onPressed: getImage,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    child: avatarImageFile == null
                        ? photoUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(45),
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  width: 90,
                                  height: 90,
                                  errorBuilder: (context, object, stackTrace) {
                                    return const Icon(
                                      Icons.account_circle,
                                      size: 90,
                                      color: ColorConstants.greyColor,
                                    );
                                  },
                                  loadingBuilder:
                                      (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      width: 90,
                                      height: 90,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: ColorConstants.themeColor,
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.account_circle,
                                size: 90,
                                color: ColorConstants.greyColor,
                              )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(45),
                            child: Image.file(
                              avatarImageFile!,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                    Container(
                      margin: const EdgeInsets.only(left: 10, bottom: 5, top: 10),
                      child: const Text(
                        'Nickname',
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.primaryColor),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 30, right: 30),
                      child: Theme(
                        data: Theme.of(context).copyWith(primaryColor: ColorConstants.primaryColor),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Sweetie',
                            contentPadding: EdgeInsets.all(5),
                            hintStyle: TextStyle(color: ColorConstants.greyColor),
                          ),
                          controller: controllerNickname,
                          onChanged: (value) {
                            nickname = value;
                          },
                          focusNode: focusNodeNickname,
                        ),
                      ),
                    ),

                    // About me
                    Container(
                      margin: const EdgeInsets.only(left: 10, top: 30, bottom: 5),
                      child: const Text(
                        'About me',
                        style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.primaryColor),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 30, right: 30),
                      child: Theme(
                        data: Theme.of(context).copyWith(primaryColor: ColorConstants.primaryColor),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Fun, like travel and play PES...',
                            contentPadding: EdgeInsets.all(5),
                            hintStyle: TextStyle(color: ColorConstants.greyColor),
                          ),
                          controller: controllerAboutMe,
                          onChanged: (value) {
                            aboutMe = value;
                          },
                          focusNode: focusNodeAboutMe,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 50, bottom: 50),
                  child: TextButton(
                    onPressed: handleUpdateData,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(ColorConstants.primaryColor),
                      padding: MaterialStateProperty.all<EdgeInsets>(
                        const EdgeInsets.fromLTRB(30, 10, 30, 10),
                      ),
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}