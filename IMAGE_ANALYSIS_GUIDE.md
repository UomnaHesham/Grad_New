# Image Analysis Integration Guide

## Overview
This guide explains how to integrate image analysis capabilities into your medical chatbot using Gemini Vision API.

## Features Added

### 1. Image Upload Support
- **File Upload**: Accept images via file upload (PNG, JPG, JPEG, GIF, BMP, WebP)
- **Base64 Processing**: Handle images encoded as base64 strings
- **Size Limits**: Maximum 16MB per image
- **Security**: Secure filename handling and temporary file cleanup

### 2. Gemini Vision Integration
- **Medical Image Analysis**: Specialized prompts for medical images
- **Multi-language Support**: Responds in Arabic or English
- **Intelligent Prompting**: Context-aware analysis based on image type

### 3. API Endpoints

#### `/chat` (Enhanced)
```json
POST /chat
{
  "message": "ما رأيك في هذه الأشعة؟",
  "image": "data:image/jpeg;base64,/9j/4AAQSkZJRgABA..."
}
```

#### `/upload_image`
```bash
POST /upload_image
Content-Type: multipart/form-data

image: [file]
prompt: "Is this X-ray normal?"
```

#### `/analyze_image`
```json
POST /analyze_image
{
  "image": "base64_string_here",
  "prompt": "Analyze this medicine photo"
}
```

## Implementation Examples

### 1. Python Flask Server
The enhanced chatbot now includes:
- Image processing methods in `MedicalRAGChatbot` class
- File upload handling with security checks
- Gemini Vision API integration
- Error handling and cleanup

### 2. Flutter Integration
```dart
// Add to pubspec.yaml
dependencies:
  image_picker: ^1.0.4
  http: ^1.1.0

// Use the ChatbotImageService class provided
File? image = await ChatbotImageService.pickImage();
if (image != null) {
  String response = await ChatbotImageService.analyzeImage(image, prompt: "What medicine is this?");
}
```

### 3. Web Testing
Use the provided `test_image_upload.html` file to test image uploads directly in your browser.

## Medical Image Types Supported

### 1. X-rays and Radiology
- Chest X-rays
- Bone fractures
- Joint imaging
- Dental X-rays

### 2. Laboratory Results
- Blood test reports
- Urine analysis
- Pathology reports
- Medical charts

### 3. Medications
- Pill identification
- Medicine packaging
- Prescription labels
- Drug information cards

### 4. Medical Documents
- Medical reports
- Prescriptions
- Health certificates
- Medical forms

## Usage Examples

### Example 1: X-ray Analysis
```
User uploads chest X-ray
Prompt: "Is this chest X-ray normal?"

Response: "Based on the chest X-ray image, I can see clear lung fields with no obvious abnormalities. The heart size appears normal, and there are no signs of pneumonia, fluid buildup, or other concerning findings. However, this is a preliminary analysis and you should consult with a radiologist for a definitive interpretation."
```

### Example 2: Medicine Identification
```
User uploads pill photo
Prompt: "What medicine is this?"

Response: "This appears to be a white, round tablet. Based on the visible markings, it could be a common medication like acetaminophen (paracetamol). However, for accurate identification, please consult with a pharmacist or check the original packaging, as many medications can look similar."
```

### Example 3: Lab Report Analysis
```
User uploads blood test report
Prompt: "تحليل نتائج الفحص"

Response: "بناءً على تقرير فحص الدم المرفق، يمكنني رؤية عدة قيم مختبرية. لتقديم تحليل دقيق، أحتاج إلى معرفة القيم المرجعية المحددة من المختبر. بشكل عام، من المهم مراجعة هذه النتائج مع طبيبك للحصول على تفسير شامل وخطة علاجية مناسبة."
```

## Configuration

### 1. Environment Setup
```bash
# Install required packages
pip install -r requirements.txt

# Create uploads directory
mkdir lib/uploads

# Set up Gemini API key in chatbot_rag.py
API_KEY = "your-gemini-api-key-here"
```

### 2. Server Configuration
```python
# File upload settings
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'}
MAX_FILE_SIZE = 16 * 1024 * 1024  # 16MB
```

### 3. Security Considerations
- File type validation
- Size limits enforcement
- Secure filename handling
- Temporary file cleanup
- Input sanitization

## Testing

### 1. Start the Server
```bash
# Windows
start_enhanced_chatbot.bat

# Manual start
cd lib
python chatbot_rag.py
```

### 2. Test Endpoints
```bash
# Health check
curl http://localhost:5000/health

# Test image upload
curl -X POST -F "image=@test_image.jpg" -F "prompt=Analyze this" http://localhost:5000/upload_image
```

### 3. Web Interface
Open `lib/test_image_upload.html` in your browser to test the upload functionality.

## Error Handling

### Common Issues and Solutions

1. **"No module named 'PIL'"**
   ```bash
   pip install Pillow
   ```

2. **"File too large"**
   - Reduce image size or increase MAX_FILE_SIZE limit

3. **"Invalid file type"**
   - Ensure image is in supported format (PNG, JPG, etc.)

4. **"Gemini API error"**
   - Check API key validity
   - Verify internet connection
   - Check API quotas

## Integration with Flutter App

### 1. Add Dependencies
```yaml
dependencies:
  image_picker: ^1.0.4
  http: ^1.1.0
  permission_handler: ^11.0.1
```

### 2. Request Permissions
```dart
// Add to android/app/src/main/AndroidManifest.xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### 3. Implementation
Use the provided `ChatbotImageService` class to integrate image analysis into your existing chat interface.

## Performance Optimization

### 1. Image Processing
- Resize images before upload
- Compress images to reduce bandwidth
- Use appropriate image formats

### 2. Caching
- Cache analysis results for identical images
- Implement response caching for common medical queries

### 3. Error Recovery
- Retry logic for failed uploads
- Fallback responses for API failures
- Progressive image loading

## Security Best Practices

1. **File Validation**: Always validate file types and sizes
2. **Sanitization**: Clean user inputs and filenames
3. **Temporary Storage**: Clean up uploaded files after processing
4. **API Security**: Protect API keys and implement rate limiting
5. **HTTPS**: Use HTTPS in production environments

## Next Steps

1. **Enhanced Analysis**: Add specialized models for specific medical image types
2. **Batch Processing**: Support multiple image uploads
3. **Image Annotation**: Add capability to highlight areas of interest
4. **Integration**: Connect with DICOM viewers for medical imaging
5. **Mobile Optimization**: Optimize for mobile camera integration

## Support

For issues or questions:
1. Check the server logs for error messages
2. Verify all dependencies are installed
3. Test with the provided HTML interface
4. Review the Flask server responses for debugging information
