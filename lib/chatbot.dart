import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatBotPage extends StatefulWidget {
  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];

  Future<void> sendMessage(String text) async {
    setState(() {
      messages.add({"sender": "user", "text": text});
    });

    final response = await http.post(
      Uri.parse("http://127.0.0.1:5000/chat"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"message": text}),
    );

    if (response.statusCode == 200) {
      final reply = json.decode(response.body)["reply"];
      setState(() {
        messages.add({"sender": "bot", "text": reply});
      });
    } else {
      setState(() {
        messages.add({"sender": "bot", "text": "Failed to get response."});
      });
    }

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Medical ChatBot")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (_, index) {
                final msg = messages[index];
                return Container(
                  alignment: msg["sender"] == "user" ? Alignment.centerRight : Alignment.centerLeft,
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: msg["sender"] == "user" ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(10),
                    child: Text(msg["text"] ?? "", style: TextStyle(color: msg["sender"] == "user" ? Colors.white : Colors.black)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: "Type your message"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      sendMessage(_controller.text.trim());
                    }
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
