import 'package:amitofo_chatting/Pages/Login/login.dart';
import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _unameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  late bool create;
  final _formKey = GlobalKey<FormState>();

  void showErrorSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
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
                      return 'Please enter email/username';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.name,
                  controller: _unameController,
                  decoration: InputDecoration(
                      hintText: 'Enter Username Here',
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
                      return 'Please enter email/username';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  controller: _phoneController,
                  decoration: InputDecoration(
                      hintText: 'Enter Phone Number Here',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: const BorderSide()),
                      prefixIcon: const Icon(
                        Icons.phone,
                      )),
                ),
                Container(
                  height: 15,
                ),
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email/username';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  decoration: InputDecoration(
                      hintText: 'Enter Email Here',
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
                      return 'Please enter email/username';
                    }
                    return null;
                  },
                  controller: _passwordController,
                  obscureText: _obscureText,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Enter Password Here',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(11),
                      borderSide: const BorderSide(),
                    ),
                    prefixIcon: const Icon(
                      Icons.lock,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
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
                  onPressed: () {},
                  child: const Text('Create'),
                ),
                Container(
                  height: 15,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Login()));
                        },
                        style: ButtonStyle(
                            overlayColor: MaterialStateProperty.all<Color>(
                                Colors.transparent)),
                        child: const Text(
                          'Sign in here',
                          style: TextStyle(color: Colors.blue),
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
