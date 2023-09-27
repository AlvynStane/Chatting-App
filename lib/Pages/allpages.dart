import 'package:amitofo_chatting/Pages/firstpage.dart';
import 'package:amitofo_chatting/Pages/secondpage.dart';
import 'package:flutter/material.dart';

class AllPages extends StatefulWidget {
  const AllPages({super.key});

  @override
  State<AllPages> createState() => _AllPagesState();
}

class _AllPagesState extends State<AllPages> {
  final List items = const [
    FirstPage(),
    SecondPage(),
  ];
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatting App'),
      ),
      body: items.elementAt(_current),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _current,
        onTap: (int index) {
            setState(() {
              _current = index;
            });
          }
      ),
    );
  }
}
