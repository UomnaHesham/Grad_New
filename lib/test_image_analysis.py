#!/usr/bin/env python3
"""
Test script for Medical Chatbot Image Analysis API
This script demonstrates how to upload and analyze medical images
"""

import requests
import base64
import os
import sys
from pathlib import Path

SERVER_URL = "http://localhost:5000"

def test_server_connection():
    """Test if the server is running"""
    try:
        response = requests.get(f"{SERVER_URL}/health")
        if response.status_code == 200:
            data = response.json()
            print("✅ Server is running!")
            print(f"📊 Documents loaded: {data.get('documents_loaded', 'N/A')}")
            print(f"🖼️ Image analysis: {'Enabled' if data.get('image_analysis_enabled') else 'Disabled'}")
            return True
        else:
            print("❌ Server responded with error:", response.status_code)
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to server. Make sure it's running on http://localhost:5000")
        return False
    except Exception as e:
        print(f"❌ Error connecting to server: {e}")
        return False

def upload_image_file(image_path, prompt=""):
    """Upload an image file for analysis"""
    try:
        if not os.path.exists(image_path):
            print(f"❌ Image file not found: {image_path}")
            return None
        
        # Prepare the file upload
        with open(image_path, 'rb') as f:
            files = {'image': f}
            data = {'prompt': prompt}
            
            print(f"📤 Uploading image: {os.path.basename(image_path)}")
            if prompt:
                print(f"❓ Question: {prompt}")
            
            response = requests.post(f"{SERVER_URL}/upload_image", files=files, data=data)
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Analysis completed!")
            print("📝 Result:")
            print("-" * 50)
            print(result.get('reply', 'No response'))
            print("-" * 50)
            return result.get('reply')
        else:
            error = response.json() if response.headers.get('content-type') == 'application/json' else response.text
            print(f"❌ Error: {error}")
            return None
            
    except Exception as e:
        print(f"❌ Error uploading image: {e}")
        return None

def upload_image_base64(image_path, prompt=""):
    """Upload an image using base64 encoding"""
    try:
        if not os.path.exists(image_path):
            print(f"❌ Image file not found: {image_path}")
            return None
        
        # Convert image to base64
        with open(image_path, 'rb') as f:
            image_data = base64.b64encode(f.read()).decode('utf-8')
        
        # Prepare JSON payload
        payload = {
            'image': image_data,
            'prompt': prompt
        }
        
        print(f"📤 Uploading image (base64): {os.path.basename(image_path)}")
        if prompt:
            print(f"❓ Question: {prompt}")
        
        response = requests.post(f"{SERVER_URL}/analyze_image", json=payload)
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Analysis completed!")
            print("📝 Result:")
            print("-" * 50)
            print(result.get('reply', 'No response'))
            print("-" * 50)
            return result.get('reply')
        else:
            error = response.json() if response.headers.get('content-type') == 'application/json' else response.text
            print(f"❌ Error: {error}")
            return None
            
    except Exception as e:
        print(f"❌ Error uploading image: {e}")
        return None

def test_text_chat(message):
    """Test the regular text chat functionality"""
    try:
        payload = {'message': message}
        response = requests.post(f"{SERVER_URL}/chat", json=payload)
        
        if response.status_code == 200:
            result = response.json()
            print("💬 Chat Response:")
            print("-" * 50)
            print(result.get('reply', 'No response'))
            print("-" * 50)
            return result.get('reply')
        else:
            print(f"❌ Chat error: {response.status_code}")
            return None
            
    except Exception as e:
        print(f"❌ Error in text chat: {e}")
        return None

def main():
    print("🏥 Medical Chatbot Image Analysis Tester")
    print("=" * 50)
    
    # Test server connection
    if not test_server_connection():
        print("\n❌ Please start the chatbot server first:")
        print("   python chatbot_rag.py")
        print("   or run: start_enhanced_chatbot.bat")
        return
    
    print("\n" + "=" * 50)
    
    # Test text chat first
    print("🧪 Testing text chat...")
    test_text_chat("Hello, can you help me with medical questions?")
    
    print("\n" + "=" * 50)
    
    # Look for sample images in common directories
    sample_dirs = [
        "sample_images",
        "../sample_images", 
        "uploads",
        "test_images",
        "."
    ]
    
    sample_found = False
    
    for sample_dir in sample_dirs:
        if os.path.exists(sample_dir):
            image_files = [f for f in os.listdir(sample_dir) 
                          if f.lower().endswith(('.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'))]
            
            if image_files:
                print(f"📁 Found sample images in: {sample_dir}")
                for img_file in image_files[:3]:  # Test first 3 images
                    img_path = os.path.join(sample_dir, img_file)
                    print(f"\n🧪 Testing image upload: {img_file}")
                    
                    # Test with file upload method
                    upload_image_file(img_path, "What do you see in this medical image?")
                    
                    print("\n" + "-" * 30)
                    
                    # Test with base64 method
                    print(f"🧪 Testing base64 upload: {img_file}")
                    upload_image_base64(img_path, "Analyze this image in Arabic: ما رأيك في هذه الصورة؟")
                    
                sample_found = True
                break
    
    if not sample_found:
        print("📋 No sample images found. Here's how to test manually:")
        print("\n1. Open your web browser and go to: http://localhost:5000/upload")
        print("2. Upload any medical image (X-ray, medicine, lab report)")
        print("3. Add a question and click 'Analyze Image'")
        print("\n4. Or use this script with an image file:")
        print("   python test_image_analysis.py <path_to_image>")
        
        if len(sys.argv) > 1:
            image_path = sys.argv[1]
            if os.path.exists(image_path):
                print(f"\n🧪 Testing with provided image: {image_path}")
                upload_image_file(image_path, "Analyze this medical image")
            else:
                print(f"❌ Image file not found: {image_path}")
    
    print("\n✅ Testing completed!")
    print("\n🌐 Access the web interface at: http://localhost:5000/upload")

if __name__ == "__main__":
    main()
