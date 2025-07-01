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
      return "http://127.0.0.1:5000/chat";    } else if (Platform.isAndroid || Platform.isIOS) {
      // When running on mobile devices
      return "http://192.168.1.13:5000/chat";  // Your PC's current network IP address
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF4A90E2),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.psychology, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical AI Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Ask me anything about your health',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF57B9FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty 
              ? _buildWelcomeScreen()
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(height: 40),
          
          // Medical AI Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color(0xFF4A90E2).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology,
              size: 60,
              color: Color(0xFF4A90E2),
            ),
          ),
          SizedBox(height: 32),
          
          // Welcome Title
          Text(
            'Welcome to Medical AI',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          
          // Subtitle
          Text(
            'Ask me anything about your health, symptoms, medications, or general medical questions.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),
          
          // Suggested Questions Section
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Suggested Questions:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Suggested Question Chips
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSuggestedChip('What are the symptoms of flu?'),
              _buildSuggestedChip('How can I improve my sleep?'),
              _buildSuggestedChip('What should I eat for better health?'),
              _buildSuggestedChip('When should I see a doctor?'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedChip(String text) {
    return GestureDetector(
      onTap: () => sendMessage(text),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Color(0xFF4A90E2),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> msg) {
    bool isUser = msg["sender"] == "user";
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF4A90E2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology,
                color: Colors.white,
                size: 18,
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF4A90E2) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg["text"] ?? "",
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.grey[800],
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Ask me about your health...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    prefixIcon: Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF57B9FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4A90E2).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    sendMessage(_controller.text.trim());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
