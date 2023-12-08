import 'package:amitofo_chatting/Constant/constants.dart';
import 'package:amitofo_chatting/Pages/Login/register.dart';
import 'package:amitofo_chatting/Pages/home.dart';
import 'package:amitofo_chatting/Provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:localization/localization.dart';
import 'package:provider/provider.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  bool isValidEmail(String email) {
    const emailPattern = r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$';
    final regExp = RegExp(emailPattern);
    return regExp.hasMatch(email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AuthenProvider authProvider = Provider.of<AuthenProvider>(context);
    switch (authProvider.status) {
      case Status.authenticateError:
        Fluttertoast.showToast(msg: "Sign-in-fail".i18n());
        break;
      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: "Sign-in-cancel".i18n());
        break;
      case Status.authenticated:
        Fluttertoast.showToast(msg: "Sign-in-success".i18n());
        break;
      default:
        break;
    }
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(top: 120),
        child: Center(
          child: Form(
            key: _formKey,
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('SIGN IN', style: TextStyle(fontSize: 35)),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email-error-1'.i18n();
                      }
                      if (!isValidEmail(value)) {
                        return 'Email-error-2'.i18n();
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Textfield-email'.i18n(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(),
                      ),
                      prefixIcon: const Icon(
                        Icons.email,
                      ),
                    ),
                  ),
                  Container(
                    height: 11,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Pass-error-1'.i18n();
                      }
                      if (value.length <= 3) {
                        return 'Pass-error-2'.i18n();
                      }
                      return null;
                    },
                    obscureText: _obscureText,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: 'Textfield-password'.i18n(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(15),
                    child: SizedBox(
                      height: 40,
                      width: 90,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            authProvider
                                .signInWithEmailAndPassword(
                                    _emailController.text,
                                    _passwordController.text)
                                .then((isSuccess) {
                              if (isSuccess) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomePage(),
                                  ),
                                );
                              }
                            }).catchError((error, stackTrace) {
                              Fluttertoast.showToast(msg: error.toString());
                              authProvider.handleException();
                            });
                          }
                        },
                        child: Text('Sign-in'.i18n()),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      authProvider.handleSignIn().then((isSuccess) {
                        if (isSuccess) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        } else {
                          setState(() {});
                        }
                      }).catchError((error, stackTrace) {
                        Fluttertoast.showToast(msg: error.toString());
                        authProvider.handleException();
                      });
                    },
                    style: ButtonStyle(
                      overlayColor:
                          MaterialStateProperty.all<Color>(Colors.transparent),
                    ),
                    child: Text(
                      'Text-button-sign-in'.i18n(),
                      style:
                          const TextStyle(color: ColorConstants.primaryColor),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Text-sign-in".i18n()),
                      TextButton(
                        onPressed: () {
                          authProvider.resetStatus();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Register(),
                            ),
                          );
                        },
                        style: ButtonStyle(
                          overlayColor: MaterialStateProperty.all<Color>(
                              Colors.transparent),
                        ),
                        child: Text(
                          'Create-account'.i18n(),
                          style: TextStyle(color: ColorConstants.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
