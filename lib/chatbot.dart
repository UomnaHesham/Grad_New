import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ChatBotPage extends StatefulWidget {
  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  // Get the appropriate server URL based on platform
  String getServerUrl() {
    if (kIsWeb) {
      // When running in web browser
      return "http://127.0.0.1:5000/chat";
    } else if (Platform.isAndroid || Platform.isIOS) {
      // When running on mobile devices
      return "http://192.168.1.13:5000/chat";  // Your PC's network IP address
    } else {
      // For desktop platforms
      return "http://127.0.0.1:5000/chat";
    }
  }
  Future<void> sendMessage(String text) async {
    setState(() {
      messages.add({"sender": "user", "text": text});
    });

    try {
      final serverUrl = getServerUrl();
      print("Connecting to server: $serverUrl"); // Debug info
      
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"message": text}),
      ).timeout(
        const Duration(seconds: 10), // Add timeout
        onTimeout: () {
          throw Exception("Connection timed out");
        },
      );

      print("Server response: ${response.statusCode}"); // Debug info
      
      if (response.statusCode == 200) {
        final reply = json.decode(response.body)["reply"];
        setState(() {
          messages.add({"sender": "bot", "text": reply});
        });
      } else {
        setState(() {
          messages.add({
            "sender": "bot", 
            "text": "Error: Server returned status code ${response.statusCode}"
          });
        });
      }
    } catch (e) {
      print("Error connecting to server: $e"); // Debug info
      setState(() {
        messages.add({
          "sender": "bot", 
          "text": "Connection error: ${e.toString()}. Make sure the server is running and accessible."
        });
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
