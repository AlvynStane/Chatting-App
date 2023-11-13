import 'dart:async';
import 'package:amitofo_chatting/Constant/constants.dart';
import 'package:amitofo_chatting/Pages/Login/login.dart';
import 'package:amitofo_chatting/Pages/home.dart';
import 'package:amitofo_chatting/Provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      checkSignedIn(context.read<AuthenProvider>());
    });
  }

  void checkSignedIn(AuthenProvider authProvider) async {
    bool isLoggedIn = await authProvider.isLoggedIn();
    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) => const HomePage()),
      );
    } else {
      int maxRetryCount = 3;
      int retryCount = 0;
      const retryDelay = Duration(seconds: 1);

      Timer.periodic(retryDelay, (timer) async {
        isLoggedIn = await authProvider.isLoggedIn();
        if (isLoggedIn || retryCount >= maxRetryCount) {
          timer.cancel();
          if (isLoggedIn) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => const HomePage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => const Login()),
            );
          }
        }
        retryCount++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: ColorConstants.themeColor),
        ),
      ),
    );
  }
}
