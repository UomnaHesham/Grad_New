import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String apiUrl = 'http://192.168.1.13:8080/chat'; // Update with your server IP and port

  static Future<String> getReply(String message) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": message}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'];
    } else {
      return "Error getting reply.";
    }
  }
}
