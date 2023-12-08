import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:amitofo_chatting/Model/model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:localization/localization.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:amitofo_chatting/Constant/constants.dart';
import 'package:amitofo_chatting/Provider/provider.dart';

class ProfileDialog extends StatefulWidget {
  final String id;
  final String nickname;
  final String aboutMe;
  final Completer<bool> refreshCompleter;

  const ProfileDialog({
    super.key,
    required this.id,
    required this.nickname,
    required this.aboutMe,
    required this.refreshCompleter,
  });

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  ScrollController scrollController = ScrollController();
  List<String> dogImages = [];
  String photoUrl = '';

  bool loadingDialog = false;
  File? avatarImageFile;
  late final ProfileProvider profileProvider = context.read<ProfileProvider>();

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

  void handleNetworkImageSelection(String imageUrl) async {
    File? downloadedFile = await downloadImage(imageUrl);
    if (downloadedFile != null) {
      setState(() {
        avatarImageFile = downloadedFile;
      });
      uploadFile();
    } else {
      Fluttertoast.showToast(msg: "Failed to download image");
    }
    setState(() {
      Navigator.pop(context, true);
    });
  }

  void _scrollListener() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent) {
      setState(() {
        fetchRandomDogImages();
      });
    }
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
        avatarImageFile = image;
        Navigator.pop(context, true);
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
    String fileName = widget.id;
    UploadTask uploadTask =
        profileProvider.uploadFile(avatarImageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      photoUrl = await snapshot.ref.getDownloadURL();
      UserChat updateInfo = UserChat(
        id: widget.id,
        photoUrl: photoUrl,
        nickname: widget.nickname,
        aboutMe: widget.aboutMe,
      );
      profileProvider
          .updateDataFirestore(FirestoreConstants.pathUserCollection, widget.id,
              updateInfo.toJson())
          .then((data) async {
        await profileProvider.setPref(FirestoreConstants.photoUrl, photoUrl);
        Fluttertoast.showToast(msg: "Upload success");
        widget.refreshCompleter.complete(true);
      }).catchError((err) {
        Fluttertoast.showToast(msg: err.toString());
      });
    } on FirebaseException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    if (dogImages.isEmpty) {
      setState(() {
        loadingDialog = true;
      });
      fetchRandomDogImages().then((_) {
        setState(() {
          loadingDialog = false;
        });
      });
    }
    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select-image'.i18n()),
      content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
        return SizedBox(
          height: 270,
          child: Stack(
            children: [
              SizedBox(
                height: 270,
                width: double.maxFinite,
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(
                      parent: RangeMaintainingScrollPhysics(),
                    ),
                  ),
                  shrinkWrap: true,
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                          width: 300,
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
      }),
      actions: <Widget>[
        ElevatedButton(
          onPressed: storagePermission,
          child: Text('Open-gallery'.i18n()),
        ),
      ],
    );
  }
}
