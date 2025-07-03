// Image Upload Integration for Flutter
// Add this to your existing chatbot.dart file

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ChatbotImageService {
  static const String baseUrl = 'http://localhost:5000'; // Change to your server URL
  
  // Pick image from gallery or camera
  static Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }
  
  // Upload image and get analysis
  static Future<String> analyzeImage(File imageFile, {String prompt = ''}) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload_image'));
      
      // Add image file
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      
      // Add prompt if provided
      if (prompt.isNotEmpty) {
        request.fields['prompt'] = prompt;
      }
      
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['reply'] ?? 'تم تحليل الصورة بنجاح';
      } else {
        var errorResponse = json.decode(response.body);
        return 'خطأ: ${errorResponse['error'] ?? 'فشل في تحليل الصورة'}';
      }
    } catch (e) {
      print('Error analyzing image: $e');
      return 'حدث خطأ أثناء تحليل الصورة. تأكد من اتصالك بالإنترنت.';
    }
  }
  
  // Alternative method using base64 encoding
  static Future<String> analyzeImageBase64(File imageFile, {String prompt = ''}) async {
    try {
      // Convert image to base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      
      // Create request body
      Map<String, dynamic> requestBody = {
        'image': base64Image,
        'prompt': prompt,
      };
      
      // Send POST request
      final response = await http.post(
        Uri.parse('$baseUrl/analyze_image'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['reply'] ?? 'تم تحليل الصورة بنجاح';
      } else {
        var errorResponse = json.decode(response.body);
        return 'خطأ: ${errorResponse['error'] ?? 'فشل في تحليل الصورة'}';
      }
    } catch (e) {
      print('Error analyzing image with base64: $e');
      return 'حدث خطأ أثناء تحليل الصورة. تأكد من اتصالك بالإنترنت.';
    }
  }
}

// Example usage in your chat widget:
/*
class ChatMessage {
  final String text;
  final bool isUser;
  final File? imageFile;
  final DateTime timestamp;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    this.imageFile,
    required this.timestamp,
  });
}

// In your chat widget:
FloatingActionButton(
  onPressed: () async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 150,
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('التقاط صورة'),
              onTap: () async {
                Navigator.pop(context);
                File? image = await ChatbotImageService.pickImage(source: ImageSource.camera);
                if (image != null) {
                  _handleImageUpload(image);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('اختيار من المعرض'),
              onTap: () async {
                Navigator.pop(context);
                File? image = await ChatbotImageService.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  _handleImageUpload(image);
                }
              },
            ),
          ],
        ),
      ),
    );
  },
  child: Icon(Icons.add_a_photo),
)

void _handleImageUpload(File imageFile) async {
  // Add user message with image
  setState(() {
    _messages.add(ChatMessage(
      text: 'تم إرفاق صورة للتحليل...',
      isUser: true,
      imageFile: imageFile,
      timestamp: DateTime.now(),
    ));
  });
  
  // Show typing indicator
  setState(() {
    _isTyping = true;
  });
  
  // Get analysis from chatbot
  String analysis = await ChatbotImageService.analyzeImage(imageFile);
  
  // Add bot response
  setState(() {
    _isTyping = false;
    _messages.add(ChatMessage(
      text: analysis,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  });
}
*/
