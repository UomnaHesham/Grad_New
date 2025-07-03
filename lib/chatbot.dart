import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class ChatBotPage extends StatefulWidget {
  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  List<Map<String, dynamic>> messages = [];
  File? _selectedImage;
  // Get the appropriate server URL based on platform
  String getServerUrl() {
    if (kIsWeb) {
      // When running in web browser
      return "http://127.0.0.1:5000/chat";
    } else if (Platform.isAndroid || Platform.isIOS) {
      // When running on mobile devices - Update this IP to match your computer's IP
      return "http://192.168.1.13:5000/chat";
    } else {
      // For desktop platforms
      return "http://127.0.0.1:5000/chat";
    }
  }

  // Get upload server URL
  String getUploadServerUrl() {
    if (kIsWeb) {
      return "http://127.0.0.1:5000/upload_image";
    } else if (Platform.isAndroid || Platform.isIOS) {
      return "http://192.168.1.13:5000/upload_image";
    } else {
      return "http://127.0.0.1:5000/upload_image";
    }
  }

  Future<void> sendMessage(String text) async {
    setState(() {
      messages.add({"sender": "user", "text": text, "hasImage": false});
      // Add typing indicator
      messages.add({"sender": "bot", "text": "🤔 جاري البحث في قاعدة البيانات الطبية...", "isTyping": true});
    });

    try {
      final serverUrl = getServerUrl();
      print("Connecting to RAG server: $serverUrl"); // Debug info
      
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"message": text}),
      ).timeout(
        const Duration(seconds: 30), // Increased timeout for RAG processing
        onTimeout: () {
          throw Exception("انتهت مهلة الاتصال - يرجى المحاولة مرة أخرى");
        },
      );

      print("RAG server response: ${response.statusCode}"); // Debug info
      
      // Remove typing indicator
      setState(() {
        messages.removeWhere((msg) => msg["isTyping"] == true);
      });
      
      if (response.statusCode == 200) {
        final reply = json.decode(response.body)["reply"];
        setState(() {
          messages.add({"sender": "bot", "text": reply, "hasImage": false});
        });
      } else {
        setState(() {
          messages.add({
            "sender": "bot", 
            "text": "خطأ: الخادم أرجع رمز الحالة ${response.statusCode}\nيرجى التأكد من تشغيل خادم RAG الطبي.",
            "hasImage": false,
          });
        });
      }
    } catch (e) {
      print("Error connecting to RAG server: $e"); // Debug info
      // Remove typing indicator on error
      setState(() {
        messages.removeWhere((msg) => msg["isTyping"] == true);
        messages.add({
          "sender": "bot", 
          "text": "خطأ في الاتصال: ${e.toString()}\n\nتأكد من:\n• تشغيل خادم RAG الطبي\n• توفر ملف البيانات (train.csv)\n• الاتصال بالشبكة",
          "hasImage": false,
        });
      });
    }

    _controller.clear();
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        
        // Show image preview and ask for question
        _showImagePreviewDialog();
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار الصورة: ${e.toString()}');
    }
  }

  // Show image source selection dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اختر مصدر الصورة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceButton(
                    icon: Icons.camera_alt,
                    label: 'التقاط صورة',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: _buildImageSourceButton(
                    icon: Icons.photo_library,
                    label: 'من المعرض',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Color(0xFF4A90E2).withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Color(0xFF4A90E2), size: 30),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Color(0xFF4A90E2),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show image preview dialog
  void _showImagePreviewDialog() {
    if (_selectedImage == null) return;

    TextEditingController imageQuestionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📷 تحليل الصورة الطبية'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: imageQuestionController,
                decoration: InputDecoration(
                  labelText: 'سؤالك عن الصورة (اختياري)',
                  hintText: 'مثال: هل هذه الأشعة طبيعية؟',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.help_outline),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedImage = null;
              });
              Navigator.pop(context);
            },
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendImageMessage(imageQuestionController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4A90E2),
              foregroundColor: Colors.white,
            ),
            child: Text('تحليل الصورة'),
          ),
        ],
      ),
    );
  }

  // Send image message
  Future<void> _sendImageMessage(String question) async {
    if (_selectedImage == null) return;

    // Add user message with image
    setState(() {
      messages.add({
        "sender": "user",
        "text": question.isEmpty ? "تم إرفاق صورة للتحليل..." : question,
        "image": _selectedImage,
        "hasImage": true,
      });
      // Add typing indicator
      messages.add({
        "sender": "bot",
        "text": "🔍 جاري تحليل الصورة الطبية...",
        "isTyping": true,
      });
    });

    try {
      final uploadUrl = getUploadServerUrl();
      print("Uploading image to: $uploadUrl");

      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      
      // Add image file
      request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
      
      // Add prompt if provided
      if (question.isNotEmpty) {
        request.fields['prompt'] = question;
      }

      // Send request with timeout
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception("انتهت مهلة رفع الصورة - يرجى المحاولة مرة أخرى");
        },
      );
      
      var response = await http.Response.fromStream(streamedResponse);

      // Remove typing indicator
      setState(() {
        messages.removeWhere((msg) => msg["isTyping"] == true);
      });

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          messages.add({
            "sender": "bot",
            "text": result["reply"] ?? "تم تحليل الصورة بنجاح",
            "hasImage": false,
          });
        });
      } else {
        final error = json.decode(response.body);
        setState(() {
          messages.add({
            "sender": "bot",
            "text": "خطأ في تحليل الصورة: ${error["error"] ?? "خطأ غير معروف"}",
            "hasImage": false,
          });
        });
      }
    } catch (e) {
      print("Error uploading image: $e");
      // Remove typing indicator on error
      setState(() {
        messages.removeWhere((msg) => msg["isTyping"] == true);
        messages.add({
          "sender": "bot",
          "text": "خطأ في رفع الصورة: ${e.toString()}\n\nتأكد من:\n• تشغيل خادم التحليل\n• جودة الاتصال بالشبكة",
          "hasImage": false,
        });
      });
    } finally {
      // Clear selected image
      setState(() {
        _selectedImage = null;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
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
                  'RAG Medical AI Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Powered by Medical Knowledge Base',
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
            'Welcome to RAG Medical AI',
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
            'Advanced medical assistant powered by Retrieval-Augmented Generation. Ask about symptoms, treatments, medications, or upload medical images for AI analysis in Arabic or English.',
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
              _buildSuggestedChip('ما هي أعراض السكري؟'),
              _buildSuggestedChip('كيف يمكن علاج ارتفاع ضغط الدم؟'),
              _buildSuggestedChip('What are the symptoms of flu?'),
              _buildSuggestedChip('ما هي أسباب الصداع النصفي؟'),
              _buildSuggestedChip('How to improve sleep quality?'),
              _buildSuggestedChip('متى يجب زيارة الطبيب؟'),
            ],
          ),
          SizedBox(height: 30),
          
          // Image Upload Feature Highlight
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF4A90E2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_a_photo,
                  color: Color(0xFF4A90E2),
                  size: 40,
                ),
                SizedBox(height: 12),
                Text(
                  '📷 رفع الصور الطبية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A90E2),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'يمكنك رفع صور الأشعة، الأدوية، التحاليل، أو أي صور طبية للحصول على تحليل ذكي',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: Icon(Icons.upload, size: 20),
                  label: Text('رفع صورة الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
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

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    bool isUser = msg["sender"] == "user";
    bool isTyping = msg["isTyping"] == true;
    bool hasImage = msg["hasImage"] == true;
    File? imageFile = msg["image"] as File?;
    
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
                color: isTyping ? Colors.orange : Color(0xFF4A90E2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTyping ? Icons.search : Icons.psychology,
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
                color: isUser ? Color(0xFF4A90E2) : (isTyping ? Colors.orange.withOpacity(0.1) : Colors.white),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show image if present
                  if (hasImage && imageFile != null) ...[
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: 200,
                        maxHeight: 200,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          imageFile,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (msg["text"] != null && msg["text"].toString().isNotEmpty) 
                      SizedBox(height: 8),
                  ],
                  // Show typing indicator or text
                  if (isTyping) 
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            msg["text"]?.toString() ?? "",
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (msg["text"] != null && msg["text"].toString().isNotEmpty)
                    Text(
                      msg["text"].toString(),
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.grey[800],
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                ],
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
            // Image upload button
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF4A90E2).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Color(0xFF4A90E2).withOpacity(0.3)),
              ),
              child: IconButton(
                icon: Icon(Icons.add_a_photo, color: Color(0xFF4A90E2), size: 20),
                onPressed: _showImageSourceDialog,
                tooltip: 'رفع صورة طبية',
              ),
            ),
            SizedBox(width: 12),
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
                    hintText: 'اسأل عن صحتك أو ارفع صورة طبية...',
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
