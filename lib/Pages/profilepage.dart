import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:amitofo_chatting/Constant/constants.dart';
import 'package:amitofo_chatting/Model/model.dart';
import 'package:amitofo_chatting/Provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  TextEditingController? controllerNickname;
  TextEditingController? controllerAboutMe;
  ScrollController scrollController = ScrollController();

  String id = '';
  String nickname = '';
  String aboutMe = '';
  String photoUrl = '';
  List<String> dogImages = [];

  bool isLoading = false;
  bool loadingDialog = false;
  File? avatarImageFile;
  late final ProfileProvider profileProvider = context.read<ProfileProvider>();

  final FocusNode focusNodeNickname = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    super.initState();
    readLocal();
    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    controllerAboutMe?.dispose();
    controllerNickname?.dispose();
    super.dispose();
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

  Future<String> fetchRandomDogImage() async {
    final response =
        await http.get(Uri.parse('https://dog.ceo/api/breeds/image/random'));

    if (response.statusCode == 200) {
      String imageUrl = jsonDecode(response.body)['message'];
      if (await http
          .head(Uri.parse(imageUrl))
          .then((res) => res.statusCode == 200)) {
        return imageUrl;
      }
    }
    return fetchRandomDogImage();
  }

  Future<void> fetchRandomDogImages() async {
    const int batchSize = 12;
    List<Future<String>> futures = [];
    for (int i = 0; i < batchSize; i++) {
      futures.add(fetchRandomDogImage());
    }
    List<String> results = await Future.wait(futures);
    setState(() {
      dogImages.addAll(results);
    });
  }

  Future<File?> downloadImage(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode == 200) {
      final documentDirectory = await getApplicationDocumentsDirectory();
      final file = File('${documentDirectory.path}/downloaded_image.png');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      return null;
    }
  }

  void handleNetworkImageSelection(String imageUrl) async {
    setState(() {
      Navigator.pop(context);
      isLoading = true;
    });
    File? downloadedFile = await downloadImage(imageUrl);
    if (downloadedFile != null) {
      setState(() {
        avatarImageFile = downloadedFile;
      });
      uploadFile();
    } else {
      Fluttertoast.showToast(msg: "Failed to download image");
    }
  }

  void _scrollListener() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent) {
      setState(() {
        fetchRandomDogImages();
        Navigator.pop(context);
        openImagePickerDialog();
      });
    }
  }

  void openImagePickerDialog() {
    if (dogImages.isEmpty) {
      setState(() {
        isLoading = true;
      });
      fetchRandomDogImages().then((_) {
        setState(() {
          isLoading = false;
        });
        showImagePickerDialog();
      });
    } else {
      showImagePickerDialog();
    }
  }

  void showImagePickerDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select an Image'),
            content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return Stack(
                children: [
                  SizedBox(
                    height: 300,
                    width: double.maxFinite,
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: ClampingScrollPhysics(
                          parent: RangeMaintainingScrollPhysics(),
                        ),
                      ),
                      shrinkWrap: true,
                      controller: scrollController,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: dogImages.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            handleNetworkImageSelection(dogImages[index]);
                          },
                          child: Image.network(
                            dogImages[index],
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                      child: loadingDialog
                          ? Container(
                              color: Colors.white.withOpacity(0.8),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: ColorConstants.themeColor,
                                ),
                              ),
                            )
                          : const SizedBox.shrink()),
                ],
              );
            }),
            actions: <Widget>[
              ElevatedButton(
                onPressed: getImage,
                child: const Text('Open Gallery'),
              ),
            ],
          );
        });
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile = await imagePicker
        .pickImage(source: ImageSource.gallery)
        .catchError((err) {
      Fluttertoast.showToast(msg: err.toString());
      return null;
    });
    File? image;
    if (pickedFile != null) {
      image = File(pickedFile.path);
    }
    if (image != null) {
      setState(() {
        Navigator.pop(context);
        avatarImageFile = image;
        isLoading = true;
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
    String fileName = id;
    UploadTask uploadTask =
        profileProvider.uploadFile(avatarImageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      photoUrl = await snapshot.ref.getDownloadURL();
      UserChat updateInfo = UserChat(
        id: id,
        photoUrl: photoUrl,
        nickname: nickname,
        aboutMe: aboutMe,
      );
      profileProvider
          .updateDataFirestore(
              FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
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
        .updateDataFirestore(
            FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
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
        title: const Text(
          "Profile",
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CupertinoButton(
                  onPressed: openImagePickerDialog,
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
                                  loadingBuilder: (BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      width: 90,
                                      height: 90,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: ColorConstants.themeColor,
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
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
                  children: <Widget>[
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: ColorConstants.primaryColor,
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              left: 10, bottom: 5, top: 10),
                          child: const Text(
                            'Nickname',
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 30, right: 30),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                            primaryColor: ColorConstants.primaryColor),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Name',
                            contentPadding: EdgeInsets.all(5),
                            hintStyle:
                                TextStyle(color: ColorConstants.greyColor),
                          ),
                          controller: controllerNickname,
                          onChanged: (value) {
                            nickname = value;
                          },
                          focusNode: focusNodeNickname,
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: ColorConstants.primaryColor,
                        ),
                        Container(
                          margin: const EdgeInsets.only(
                              left: 10, top: 30, bottom: 5),
                          child: const Text(
                            'About me',
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 30, right: 30),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                            primaryColor: ColorConstants.primaryColor),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'About me',
                            contentPadding: EdgeInsets.all(5),
                            hintStyle:
                                TextStyle(color: ColorConstants.greyColor),
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
                      backgroundColor: MaterialStateProperty.all<Color>(
                          ColorConstants.primaryColor),
                      padding: MaterialStateProperty.all<EdgeInsets>(
                        const EdgeInsets.fromLTRB(30, 10, 30, 10),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
              child: isLoading
                  ? Container(
                      color: Colors.white.withOpacity(0.8),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: ColorConstants.themeColor,
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),
        ],
      ),
    );
  }
}
