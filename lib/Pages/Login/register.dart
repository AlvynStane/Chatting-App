import 'package:amitofo_chatting/Constant/constants.dart';
import 'package:amitofo_chatting/Pages/Login/login.dart';
import 'package:amitofo_chatting/Provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:localization/localization.dart';
import 'package:provider/provider.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _unameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  late bool create;
  final _formKey = GlobalKey<FormState>();

  bool isValidEmail(String email) {
    const emailPattern = r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$';
    final regExp = RegExp(emailPattern);
    return regExp.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    AuthenProvider authProvider = Provider.of<AuthenProvider>(context);
    switch (authProvider.status) {
      case Status.authenticateError:
        Fluttertoast.showToast(msg: "Register-fail".i18n());
        break;
      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: "Register-cancel".i18n());
        break;
      case Status.authenticated:
        Fluttertoast.showToast(msg: "Register-success".i18n());
        break;
      case Status.authenticateRejected:
        Fluttertoast.showToast(msg: "Register-already".i18n());
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
                  const Text('SIGN UP', style: TextStyle(fontSize: 35)),
                  const SizedBox(height: 30),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Uname-error-1'.i18n();
                      }
                      return null;
                    },
                    keyboardType: TextInputType.name,
                    controller: _unameController,
                    decoration: InputDecoration(
                        hintText: 'Textfield-username'.i18n(),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: const BorderSide()),
                        prefixIcon: const Icon(
                          Icons.person,
                        )),
                  ),
                  Container(
                    height: 15,
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email-error-1'.i18n();
                      }
                      if (!isValidEmail(value)) {
                        return 'Email-error-2'.i18n();
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    decoration: InputDecoration(
                        hintText: 'Textfield-email'.i18n(),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                            borderSide: const BorderSide()),
                        prefixIcon: const Icon(
                          Icons.email,
                        )),
                  ),
                  Container(
                    height: 15,
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Pass-error-1'.i18n();
                      }
                      if (value.length <= 3) {
                        return 'Pass-error-2'.i18n();
                      }
                      return null;
                    },
                    controller: _passwordController,
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
                    style: const TextStyle(),
                  ),
                  Container(
                    height: 15,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        authProvider
                            .registerWithEmailAndPassword(_emailController.text,
                                _passwordController.text, _unameController.text)
                            .then((isSuccess) {
                          if (isSuccess) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Login(),
                              ),
                            );
                          }
                        }).catchError((error, stackTrace) {
                          Fluttertoast.showToast(msg: error.toString());
                          authProvider.handleException();
                        });
                      }
                    },
                    child: Text('Create'.i18n()),
                  ),
                  Container(
                    height: 15,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Text-sign-up".i18n()),
                      TextButton(
                          onPressed: () {
                            authProvider.resetStatus();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Login(),
                              ),
                            );
                          },
                          style: ButtonStyle(
                              overlayColor: MaterialStateProperty.all<Color>(
                                  Colors.transparent)),
                          child: Text(
                            'Login'.i18n(),
                            style:
                                TextStyle(color: ColorConstants.primaryColor),
                          )),
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
