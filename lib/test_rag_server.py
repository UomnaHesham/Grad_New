import requests
import json

def test_rag_server():
    """Test the RAG server with sample medical questions"""
    
    server_url = "http://127.0.0.1:5000"
    
    # Test health endpoint
    print("🔍 Testing server health...")
    try:
        health_response = requests.get(f"{server_url}/health", timeout=5)
        if health_response.status_code == 200:
            health_data = health_response.json()
            print(f"✅ Server is healthy!")
            print(f"📊 Documents loaded: {health_data.get('documents_loaded', 0)}")
            print(f"🧠 Embeddings created: {health_data.get('embeddings_created', False)}")
        else:
            print(f"❌ Health check failed: {health_response.status_code}")
            return
    except Exception as e:
        print(f"❌ Cannot connect to server: {e}")
        print("Make sure the RAG server is running on port 5000")
        return
    
    print("\n" + "="*60)
    print("🧪 Testing Medical Questions")
    print("="*60)
    
    # Test questions in Arabic and English - including some that might not have exact matches
    test_questions = [
        "مرحبا",
        "ما هي أعراض السكري؟",  # Should find matches
        "كيف يمكن علاج ارتفاع ضغط الدم؟",  # Should find matches
        "What are the symptoms of flu?",  # Should find matches
        "كيف أتعامل مع مرض نادر جداً؟",  # Unlikely to find matches - should use general knowledge
        "What is the treatment for a very rare genetic disorder?",  # Should trigger general knowledge
        "شكراً",
        "How to improve sleep quality?"
    ]
    
    for i, question in enumerate(test_questions, 1):
        print(f"\n📝 سؤال {i}: {question}")
        print("-" * 40)
        
        try:
            response = requests.post(
                f"{server_url}/chat",
                headers={"Content-Type": "application/json"},
                json={"message": question},
                timeout=30
            )
            
            if response.status_code == 200:
                reply = response.json().get("reply", "No reply")
                print(f"🤖 الإجابة: {reply[:200]}...")
                if len(reply) > 200:
                    print("    [Response truncated for display]")
            else:
                print(f"❌ خطأ: {response.status_code}")
                
        except Exception as e:
            print(f"❌ خطأ في الاتصال: {e}")
    
    print(f"\n✅ اختبار الـ RAG مكتمل!")

if __name__ == "__main__":
    print("🚀 RAG Medical Chatbot Tester")
    print("="*40)
    test_rag_server()
