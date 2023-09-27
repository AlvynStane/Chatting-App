import 'package:amitofo_chatting/Pages/chatpage.dart';
import 'package:flutter/material.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  List<Map<String, dynamic>> mow = [
    {"name": "Charlie", "message": "Hello!"},
    {"name": "Herry", "message": "World!"},
    {"name": "July", "message": "Sup!"},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: mow.length,
        itemBuilder: (context, index) {
          return InkWell(
            child: ListTile(
              title: Text(mow[index]["name"]),
              subtitle: Text(mow[index]["message"]),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    name: mow[index]["name"],
                    id: mow[index],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
