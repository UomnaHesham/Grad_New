# RAG-Enhanced Medical Chatbot API
# This replaces the simple Gemini-only chatbot with a RAG system

from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import numpy as np
import re
import os
import warnings
import time
import base64
import io
from typing import List, Dict, Any
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import google.generativeai as genai
import pyarabic.araby as araby
from PIL import Image
from werkzeug.utils import secure_filename

# Suppress warnings
warnings.filterwarnings('ignore')

app = Flask(__name__)
CORS(app)

# Configure upload settings
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'}
MAX_FILE_SIZE = 16 * 1024 * 1024  # 16MB max file size

# Create upload folder if it doesn't exist
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE

# Initialize Gemini model
API_KEY = "AIzaSyAmsXTtQjGlBMPthUoykwKQUeA3DLxqspE"
genai.configure(api_key=API_KEY)
gemini_model = genai.GenerativeModel("gemini-2.0-flash")

class MedicalRAGChatbot:
    def __init__(self, train_csv_path="../RAG/train.csv"):
        self.vectorizer = None
        self.embeddings = None
        self.documents = []
        self.metadata = []
        self.train_csv_path = train_csv_path
        
        # Load and initialize the RAG system
        self.load_data()
        self.create_embeddings()
    
    def allowed_file(self, filename):
        """Check if the uploaded file has an allowed extension"""
        return '.' in filename and \
               filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS
    
    def process_image_with_gemini(self, image, user_prompt=""):
        """Process image using Gemini Vision model"""
        try:
            # If no specific prompt provided, use default medical analysis prompt
            if not user_prompt or user_prompt.strip() == "":
                prompt = """أنت طبيب مختص في تحليل الصور الطبية. قم بتحليل هذه الصورة وقدم:

1. وصف ما تراه في الصورة
2. إذا كانت صورة طبية (أشعة، تحليل، دواء، إلخ) - قدم تحليل طبي مفصل
3. إذا كانت صورة دواء - اذكر اسم الدواء واستخداماته
4. إذا كانت أشعة أو فحص طبي - حدد ما إذا كانت طبيعية أم لا واشرح السبب
5. قدم نصائح طبية مناسبة إن أمكن

أجب باللغة العربية أو الإنجليزية حسب المناسب."""
            else:
                prompt = f"""أنت طبيب مختص. المريض يسأل: {user_prompt}

قم بتحليل الصورة المرفقة وأجب على سؤال المريض بشكل مفصل ومفيد."""

            # Generate content using Gemini with image
            response = gemini_model.generate_content([prompt, image])
            
            if response.text:
                return self.clean_response(response.text)
            else:
                return "عذراً، لم أتمكن من تحليل الصورة. يرجى المحاولة مرة أخرى."
                
        except Exception as e:
            print(f"Error processing image with Gemini: {e}")
            return f"حدث خطأ أثناء تحليل الصورة: {str(e)}"
    
    def analyze_image_from_base64(self, base64_string, user_prompt=""):
        """Analyze image from base64 string"""
        try:
            # Remove data URL prefix if present
            if base64_string.startswith('data:image'):
                base64_string = base64_string.split(',')[1]
            
            # Decode base64 to image
            image_data = base64.b64decode(base64_string)
            image = Image.open(io.BytesIO(image_data))
            
            # Process with Gemini
            return self.process_image_with_gemini(image, user_prompt)
            
        except Exception as e:
            print(f"Error analyzing image from base64: {e}")
            return "عذراً، لم أتمكن من قراءة الصورة. تأكد من أن الصورة بتنسيق صحيح."
    
    def analyze_image_from_file(self, file_path, user_prompt=""):
        """Analyze image from file path"""
        try:
            # Open and process the image
            image = Image.open(file_path)
            
            # Process with Gemini
            return self.process_image_with_gemini(image, user_prompt)
            
        except Exception as e:
            print(f"Error analyzing image from file: {e}")
            return "عذراً، لم أتمكن من قراءة الصورة من الملف المحدد."

    def normalize_arabic(self, text):
        """Normalize Arabic text by standardizing various forms of letters."""
        if not isinstance(text, str):
            return ""
            
        # Standardize alef forms
        text = re.sub("[إأٱآا]", "ا", text)
        # Standardize ya forms
        text = re.sub("ى", "ي", text)
        # Standardize hamza forms (but preserve ئ as it has different meaning)
        text = re.sub("ؤ", "ء", text)
        
        # Remove diacritics (tashkeel)
        text = araby.strip_tashkeel(text)
        
        return text

    def preprocess_text(self, text):
        """Enhanced preprocessing function for Arabic and English text"""
        if not isinstance(text, str):
            return ""
        
        # Apply Arabic normalization
        text = self.normalize_arabic(text)
        
        # Remove extra whitespace
        text = re.sub(r'\s+', ' ', text)
        text = text.strip()
        
        # For better TF-IDF, keep some punctuation but remove others
        text = re.sub(r'[^\w\s\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]', ' ', text)
        
        return text

    def load_data(self):
        """Load the training dataset"""
        try:
            print(f"Loading data from: {self.train_csv_path}")
            
            # Try different possible paths
            possible_paths = [
                self.train_csv_path,
                "RAG/train.csv",
                "../RAG/train.csv",
                "train.csv"
            ]
            
            df = None
            for path in possible_paths:
                if os.path.exists(path):
                    df = pd.read_csv(path)
                    print(f"✓ Data loaded from: {path}")
                    break
            
            if df is None:
                raise FileNotFoundError("Could not find train.csv file")
            
            # Preprocess the data
            df['question'] = df['question'].apply(self.preprocess_text)
            df['answer'] = df['answer'].apply(self.preprocess_text)
            
            # Create documents combining question and answer
            for _, row in df.iterrows():
                doc_text = f"Question: {row['question']}\nAnswer: {row['answer']}\nCategory: {row['label']}"
                self.documents.append(doc_text)
                self.metadata.append({
                    'question': row['question'],
                    'answer': row['answer'],
                    'label': row['label']
                })
            
            print(f"✓ Loaded {len(self.documents)} medical documents")
            
        except Exception as e:
            print(f"Error loading data: {e}")
            # Fallback with sample data
            self.create_fallback_data()

    def create_fallback_data(self):
        """Create comprehensive fallback data if CSV loading fails"""
        fallback_data = [
            {
                'question': 'ما هي أعراض السكري؟',
                'answer': 'أعراض السكري تشمل العطش الشديد، كثرة التبول خاصة ليلاً، التعب والإرهاق المستمر، فقدان الوزن غير المبرر، الجوع المفرط، بطء شفاء الجروح، تشوش الرؤية، والالتهابات المتكررة خاصة في المسالك البولية.',
                'label': 'Diabetes'
            },
            {
                'question': 'كيف يمكن علاج ارتفاع ضغط الدم؟',
                'answer': 'علاج ارتفاع ضغط الدم يشمل تغييرات في نمط الحياة مثل تقليل الملح في الطعام، ممارسة التمارين الرياضية بانتظام، الحفاظ على وزن صحي، تجنب التدخين والكحول، إدارة التوتر، وتناول الأدوية المضادة لارتفاع الضغط حسب وصفة الطبيب.',
                'label': 'Hypertension'
            },
            {
                'question': 'What are the symptoms of flu?',
                'answer': 'Flu symptoms include sudden onset of fever (usually high), chills and sweats, severe body aches and muscle pain, fatigue and weakness, dry persistent cough, sore throat, runny or stuffy nose, headache, and sometimes nausea and vomiting.',
                'label': 'Influenza'
            },
            {
                'question': 'ما هي أعراض الصداع النصفي؟',
                'answer': 'أعراض الصداع النصفي تشمل ألم شديد في جانب واحد من الرأس، الغثيان والقيء، الحساسية للضوء والصوت، تشوش الرؤية أو رؤية أضواء، وقد تسبق النوبة أعراض تحذيرية مثل تغيرات في المزاج أو الشهية.',
                'label': 'Migraine'
            },
            {
                'question': 'كيف أعالج نزلة البرد؟',
                'answer': 'علاج نزلة البرد يشمل الراحة التامة، شرب السوائل الدافئة بكثرة، الغرغرة بالماء المالح للحلق، استخدام قطرات الأنف المالحة، تناول فيتامين سي، استخدام مرطب الهواء، وتجنب المهيجات مثل الدخان.',
                'label': 'Common Cold'
            },
            {
                'question': 'What causes back pain?',
                'answer': 'Back pain can be caused by muscle strain from heavy lifting or sudden movements, poor posture, herniated discs, arthritis, osteoporosis, kidney problems, or stress. Most back pain is mechanical and improves with rest, gentle exercise, and proper ergonomics.',
                'label': 'Back Pain'
            },
            {
                'question': 'ما هي أعراض التهاب المفاصل؟',
                'answer': 'أعراض التهاب المفاصل تشمل ألم وتورم في المفاصل، تيبس خاصة في الصباح، صعوبة في الحركة، احمرار ودفء في المنطقة المصابة، وقد يصاحبها تعب عام وحمى خفيفة في بعض الأنواع.',
                'label': 'Arthritis'
            },
            {
                'question': 'كيف أتعامل مع القلق والتوتر؟',
                'answer': 'للتعامل مع القلق والتوتر: مارس تمارين التنفس العميق، احرص على النوم الكافي، مارس الرياضة بانتظام، تجنب الكافيين الزائد، مارس تقنيات الاسترخاء والتأمل، تحدث مع أشخاص تثق بهم، وإذا استمر القلق استشر مختص نفسي.',
                'label': 'Anxiety'
            }
        ]
        
        for item in fallback_data:
            # Make the document more searchable by including keywords
            doc_text = f"Question: {item['question']}\nAnswer: {item['answer']}\nCategory: {item['label']}\nKeywords: medical health symptoms treatment"
            self.documents.append(doc_text)
            self.metadata.append(item)
        
        print(f"✓ Using {len(fallback_data)} comprehensive medical fallback documents")

    def create_embeddings(self):
        """Create TF-IDF embeddings for the documents"""
        try:
            print("Creating embeddings...")
            
            # Use TF-IDF vectorizer with better settings for Arabic and English
            self.vectorizer = TfidfVectorizer(
                max_features=2000,  # Increased from 1000
                ngram_range=(1, 3),  # Include trigrams for better context
                lowercase=True,
                stop_words=None,  # Handle both Arabic and English
                min_df=1,  # Include terms that appear at least once
                max_df=0.95,  # Exclude very common terms
                sublinear_tf=True,  # Use sublinear TF scaling
                analyzer='word'
            )
            
            # Fit and transform documents
            self.embeddings = self.vectorizer.fit_transform(self.documents)
            print(f"✓ Created embeddings with shape: {self.embeddings.shape}")
            
            # Debug: Print vocabulary size
            vocab_size = len(self.vectorizer.vocabulary_)
            print(f"✓ Vocabulary size: {vocab_size}")
            
        except Exception as e:
            print(f"Error creating embeddings: {e}")

    def retrieve_relevant_documents(self, query, k=3):
        """Retrieve relevant documents for a query"""
        try:
            if self.vectorizer is None or self.embeddings is None:
                return []
            
            # Preprocess query
            processed_query = self.preprocess_text(query)
            
            # Transform query to vector
            query_vector = self.vectorizer.transform([processed_query])
            
            # Calculate cosine similarity
            similarities = cosine_similarity(query_vector, self.embeddings).flatten()
            
            # Get top k documents
            top_indices = similarities.argsort()[-k:][::-1]
            
            relevant_docs = []
            
            # More lenient similarity threshold for better retrieval
            threshold = 0.1  # Increased from 0.05
            max_similarity = similarities.max() if len(similarities) > 0 else 0
            
            print(f"🔍 Query: '{query[:50]}...'")
            print(f"📊 Max similarity found: {max_similarity:.3f}")
            
            # If max similarity is very low, reduce threshold adaptively
            if max_similarity < threshold:
                adaptive_threshold = max(0.01, max_similarity * 0.5)  # Use 50% of max similarity
                print(f"📉 Adaptive threshold: {adaptive_threshold:.3f}")
            else:
                adaptive_threshold = threshold
            
            # Get documents above adaptive threshold
            for idx in top_indices:
                if similarities[idx] >= adaptive_threshold:
                    relevant_docs.append({
                        'content': self.documents[idx],
                        'metadata': self.metadata[idx],
                        'similarity': similarities[idx]
                    })
                    print(f"✓ Retrieved doc {idx}: similarity={similarities[idx]:.3f}")
            
            # If still no documents found, take the best match if it's not completely irrelevant
            if not relevant_docs and len(top_indices) > 0:
                best_idx = top_indices[0]
                if similarities[best_idx] > 0.001:  # Very minimal threshold
                    relevant_docs.append({
                        'content': self.documents[best_idx],
                        'metadata': self.metadata[best_idx],
                        'similarity': similarities[best_idx]
                    })
                    print(f"📝 Using best available match: similarity={similarities[best_idx]:.3f}")
            
            if relevant_docs:
                print(f"✅ Retrieved {len(relevant_docs)} relevant documents")
            else:
                print("❌ No relevant documents found in knowledge base")
            
            return relevant_docs
            
        except Exception as e:
            print(f"Error retrieving documents: {e}")
            return []

    def generate_rag_response(self, query):
        """Generate response using RAG system - Retrieve documents first, then use Gemini"""
        try:
            # Step 1: Try to retrieve relevant documents
            relevant_docs = self.retrieve_relevant_documents(query, k=3)
            
            # Step 2: Determine response strategy based on document retrieval
            if relevant_docs and relevant_docs[0]['similarity'] > 0.1:
                # High confidence retrieval - use documents as primary context
                context = "معلومات طبية ذات صلة من قاعدة البيانات الطبية:\n\n"
                
                for i, doc in enumerate(relevant_docs, 1):
                    answer = doc['metadata']['answer']
                    category = doc['metadata']['label']
                    similarity = doc['similarity']
                    context += f"{i}. {answer}\n[المصدر: {category} - الدقة: {similarity:.2f}]\n\n"
                
                medical_prompt = f"""أنت طبيب مختص ومساعد طبي ذكي. استخدم المعلومات الطبية المتوفرة للإجابة على سؤال المريض.

{context}

سؤال المريض: {query}

تعليمات للإجابة:
1. استخدم المعلومات المرجعية المتوفرة أعلاه كأساس لإجابتك
2. يمكنك إضافة معلومات طبية عامة لتكملة الإجابة إذا لزم الأمر
3. قدم إجابة شاملة ومفيدة بناءً على المعلومات المتاحة
4. أجب باللغة المناسبة للسؤال (عربي أو إنجليزي)
5. كن واضحاً ومفصلاً في إجابتك الطبية

الإجابة الطبية:"""
                
                print(f"🎯 Using {len(relevant_docs)} high-confidence retrieved documents")
                
            elif relevant_docs and relevant_docs[0]['similarity'] > 0.05:
                # Medium confidence - use documents but supplement with general knowledge
                context = "معلومات طبية مرجعية (قد تكون ذات صلة):\n\n"
                
                for i, doc in enumerate(relevant_docs, 1):
                    answer = doc['metadata']['answer']
                    category = doc['metadata']['label']
                    context += f"{i}. {answer}\n[من تخصص: {category}]\n\n"
                
                medical_prompt = f"""أنت طبيب مختص ومساعد طبي ذكي. لديك بعض المعلومات المرجعية وخبرتك الطبية العامة.

{context}

سؤال المريض: {query}

تعليمات للإجابة:
1. راجع المعلومات المرجعية أعلاه - قد تكون مفيدة أو قد لا تكون مرتبطة مباشرة
2. استخدم معرفتك الطبية العامة كمصدر أساسي للإجابة
3. إذا وجدت المعلومات المرجعية مفيدة، فادمجها في إجابتك
4. إذا لم تكن المعلومات المرجعية ذات صلة، فاعتمد على معرفتك الطبية
5. قدم إجابة طبية شاملة ومفيدة

الإجابة الطبية:"""
                
                print(f"🔍 Using {len(relevant_docs)} medium-confidence documents + general knowledge")
                
            else:
                # Low or no confidence in retrieval - use Gemini's general medical knowledge
                medical_prompt = f"""أنت طبيب مختص ومساعد طبي ذكي. أجب على السؤال الطبي التالي باستخدام معرفتك الطبية الشاملة.

سؤال المريض: {query}

تعليمات للإجابة:
1. استخدم معرفتك الطبية العامة والمتخصصة
2. قدم إجابة شاملة ومفيدة ودقيقة
3. اشرح الأعراض، الأسباب، والعلاجات المناسبة إذا كان ذلك مناسباً
4. أجب باللغة المناسبة للسؤال (عربي أو إنجليزي)
5. كن واضحاً وعملياً في نصائحك الطبية

الإجابة الطبية:"""
                
                print("🧠 Using Gemini's general medical knowledge (no relevant documents found)")
            
            # Step 3: Generate response with Gemini
            response = self.gemini_generate(medical_prompt)
            
            # Step 4: Clean and validate response
            cleaned_response = self.clean_response(response)
            
            # If response is too short or empty, try fallback
            if not cleaned_response or len(cleaned_response.strip()) < 30:
                print("⚠️ Response too short, trying fallback approach")
                return self.generate_emergency_fallback(query)
            
            # Add appropriate medical disclaimer
            if relevant_docs and relevant_docs[0]['similarity'] > 0.1:
                disclaimer = "\n\n💡 هذه الإجابة مبنية على معلومات من قاعدة البيانات الطبية. للحصول على تشخيص دقيق وعلاج مناسب، يرجى استشارة طبيب مختص."
            else:
                disclaimer = "\n\n⚠️ تنبيه طبي: هذه المعلومات للاستعلام العام فقط. يرجى استشارة طبيب مختص للحصول على التشخيص والعلاج المناسب."
            
            return cleaned_response + disclaimer
            
        except Exception as e:
            print(f"❌ Error generating response: {e}")
            return self.generate_emergency_fallback(query)

    def gemini_generate(self, prompt, max_retries=3):
        """Generate text using Gemini with retry logic"""
        for attempt in range(max_retries):
            try:
                response = gemini_model.generate_content(prompt)
                if response.text:
                    return response.text.strip()
                else:
                    print(f"Empty response from Gemini on attempt {attempt + 1}")
            except Exception as e:
                print(f"Gemini error on attempt {attempt + 1}: {e}")
                if attempt < max_retries - 1:
                    time.sleep(2)  # Wait before retry
                else:
                    return "عذراً، أواجه صعوبة في توليد الاستجابة. يرجى المحاولة مرة أخرى."
        
        return "غير قادر على توليد استجابة بعد عدة محاولات."

    def clean_response(self, response):
        """Clean the response by removing unwanted formatting while preserving medical content"""
        if not response:
            return ""
        
        # Remove markdown formatting but preserve content
        response = re.sub(r'\*\*([^*]+)\*\*', r'\1', response)  # Remove **bold**
        response = re.sub(r'\*([^*]+)\*', r'\1', response)      # Remove *italic*
        
        # Remove multiple asterisks
        response = re.sub(r'\*+', '', response)
        
        # Clean up excessive whitespace
        response = re.sub(r'\n\s*\n\s*\n', '\n\n', response)  # Remove triple newlines
        response = re.sub(r'\s+', ' ', response)  # Replace multiple spaces with single space
        response = response.strip()
        
        # Only reject responses that are clearly refusing to help
        # Be more lenient with medical responses
        refusal_patterns = [
            "لا يمكنني تشخيص",
            "لا أستطيع تقديم تشخيص طبي",
            "أعتذر، لا يمكنني",
            "غير قادر على تقديم معلومات طبية"
        ]
        
        # Only reject if response is very short AND contains clear refusal
        if len(response) < 30 and any(pattern in response for pattern in refusal_patterns):
            return ""
        
        return response

    def generate_emergency_fallback(self, query):
        """Emergency fallback when Gemini fails - still try to use Gemini as medical assistant"""
        try:
            # More assertive medical assistant prompt as last resort
            simple_prompt = f"""أنت طبيب. يجب أن تجيب على هذا السؤال الطبي:

{query}

تعليمات:
- أجب دائماً بمعلومات طبية مفيدة
- لا تقل أنك لا تستطيع الإجابة
- استخدم معرفتك الطبية لتقديم إجابة مفيدة
- أجب باللغة المناسبة

إجابتك:"""
            
            response = self.gemini_generate(simple_prompt)
            if response and "غير قادر على توليد استجابة" not in response and "لا يمكنني تقديم" not in response:
                # Clean the response
                cleaned_response = self.clean_response(response)
                return cleaned_response + "\n\n⚠️ تنبيه: هذه إجابة عامة. يرجى استشارة طبيب مختص للحصول على تشخيص دقيق."
            else:
                # If Gemini completely fails, return static message with basic medical info
                return self.get_static_medical_response(query)
                
        except Exception as e:
            print(f"Error in emergency fallback: {e}")
            return self.get_static_medical_response(query)

    def get_static_medical_response(self, query):
        """Provide basic medical information when all AI fails"""
        query_lower = query.lower()
        
        # Basic medical responses for common questions
        if any(word in query_lower for word in ['حمى', 'fever', 'حرارة']):
            return """أعراض الحمى تشمل:
• ارتفاع درجة حرارة الجسم فوق 38°م
• القشعريرة والرعشة
• التعرق
• الصداع
• آلام العضلات
• فقدان الشهية
• التعب والإرهاق

العلاج:
• الراحة وشرب السوائل
• خافضات الحرارة مثل الباراسيتامول
• الكمادات الباردة

⚠️ يرجى استشارة طبيب إذا استمرت الحمى أكثر من 3 أيام أو تجاوزت 39°م."""
        
        elif any(word in query_lower for word in ['صداع', 'headache', 'رأس']):
            return """أسباب الصداع الشائعة:
• التوتر والإجهاد
• قلة النوم
• الجفاف
• الجوع
• مشاكل العين
• التهاب الجيوب الأنفية

العلاج:
• الراحة في مكان هادئ
• شرب الماء
• مسكنات الألم حسب الحاجة
• تطبيق كمادات باردة أو دافئة

⚠️ استشر طبيب إذا كان الصداع شديد أو مستمر."""
        
        else:
            return """أواجه صعوبة في توليد إجابة محددة لسؤالك حالياً.

للحصول على معلومات طبية دقيقة، يرجى:
1. استشارة طبيب مختص
2. زيارة أقرب مركز صحي
3. الاتصال بالخط الساخن للاستشارات الطبية

⚠️ هذا النظام للاستعلام العام وليس بديلاً عن الاستشارة الطبية."""

    def get_static_fallback_response(self):
        """Static fallback when all else fails"""
        return """عذراً، أواجه صعوبة في توليد استجابة مناسبة حالياً. 

يرجى:
1. إعادة صياغة السؤال بطريقة أخرى
2. استشارة طبيب مختص للحصول على إجابة دقيقة
3. زيارة أقرب مركز صحي

⚠️ تذكير: هذا النظام للاستعلام العام فقط وليس بديلاً عن الاستشارة الطبية المتخصصة."""

# Initialize the RAG chatbot
rag_chatbot = MedicalRAGChatbot()

# Flask routes
@app.route("/", methods=["GET"])
def home():
    return "✅ RAG-Enhanced Medical Chatbot API is running!"

@app.route("/upload", methods=["GET"])
def upload_page():
    """Serve the image upload interface"""
    try:
        # Serve the HTML file for image upload
        html_path = os.path.join(os.path.dirname(__file__), 'image_upload_interface.html')
        if os.path.exists(html_path):
            with open(html_path, 'r', encoding='utf-8') as f:
                return f.read()
        else:
            return """
            <h1>Image Upload Interface Not Found</h1>
            <p>The image upload interface file is missing. Please check that 'image_upload_interface.html' exists in the lib folder.</p>
            <p><a href="/health">Check Server Health</a></p>
            """
    except Exception as e:
        return f"<h1>Error</h1><p>Failed to load upload interface: {str(e)}</p>"

@app.route("/chat", methods=["POST", "GET"])
def chat():
    try:
        if request.method == "POST":
            data = request.get_json()
            user_input = data.get("message", "").strip()
            
            # Check if there's an image in the request
            image_data = data.get("image", "")
            if image_data:
                # Handle image analysis
                print("🖼️ Processing image with user query...")
                response = rag_chatbot.analyze_image_from_base64(image_data, user_input)
                return jsonify({"reply": response})
                
        else:  # GET method, for testing in browser
            user_input = request.args.get("message", "").strip()

        if not user_input:
            return jsonify({"reply": "يرجى إدخال رسالة."}), 400

        # Handle greetings and gratitude
        user_lower = user_input.lower()
        
        if any(greeting in user_lower for greeting in ['hello', 'hi', 'مرحبا', 'السلام عليكم', 'أهلا']):
            greeting_response = """مرحباً بك في مساعد الصحة الذكي! 👋

أنا هنا لمساعدتك في الأسئلة الطبية والصحية. يمكنك سؤالي عن:
• الأعراض والحالات الطبية
• العلاجات والأدوية
• النصائح الصحية العامة
• تحليل الصور الطبية (أشعة، أدوية، فحوصات)
• متى يجب زيارة الطبيب

كيف يمكنني مساعدتك اليوم؟"""
            return jsonify({"reply": greeting_response})
        
        if any(thanks in user_lower for thanks in ['thank you', 'thanks', 'شكرا', 'شكراً']):
            thanks_response = "على الرحب والسعة! أتمنى لك دوام الصحة والعافية. لا تتردد في سؤالي عن أي شيء آخر. 😊"
            return jsonify({"reply": thanks_response})

        # Log the user input for debugging
        print(f"🔍 Processing query: {user_input}")
        
        # Always generate RAG-enhanced response using Gemini
        response = rag_chatbot.generate_rag_response(user_input)
        
        # Ensure we always have a response
        if not response or response.strip() == "":
            response = "عذراً، لم أتمكن من توليد إجابة مناسبة. يرجى إعادة صياغة السؤال أو استشارة طبيب مختص."
        
        print(f"✅ Generated response: {response[:100]}...")
        return jsonify({"reply": response})

    except Exception as e:
        print(f"Error in chat endpoint: {e}")
        error_response = "عذراً، حدث خطأ في النظام. يرجى المحاولة مرة أخرى."
        return jsonify({"reply": error_response}), 500

@app.route("/upload_image", methods=["POST"])
def upload_image():
    """Handle image upload via file upload"""
    try:
        # Check if image file is in the request
        if 'image' not in request.files:
            return jsonify({"error": "لم يتم إرفاق صورة"}), 400
        
        file = request.files['image']
        user_prompt = request.form.get('prompt', '')
        
        # Check if file is selected
        if file.filename == '':
            return jsonify({"error": "لم يتم اختيار ملف"}), 400
        
        # Check if file type is allowed
        if not rag_chatbot.allowed_file(file.filename):
            return jsonify({"error": f"نوع الملف غير مدعوم. الأنواع المدعومة: {', '.join(ALLOWED_EXTENSIONS)}"}), 400
        
        # Save the uploaded file
        filename = secure_filename(file.filename)
        timestamp = str(int(time.time()))
        filename = f"{timestamp}_{filename}"
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(file_path)
        
        print(f"🖼️ Image uploaded: {filename}")
        
        # Analyze the image
        response = rag_chatbot.analyze_image_from_file(file_path, user_prompt)
        
        # Clean up - remove the uploaded file after processing
        try:
            os.remove(file_path)
        except:
            pass  # Don't worry if file removal fails
        
        return jsonify({"reply": response})
        
    except Exception as e:
        print(f"Error in upload_image endpoint: {e}")
        return jsonify({"error": "حدث خطأ أثناء معالجة الصورة"}), 500

@app.route("/analyze_image", methods=["POST"])
def analyze_image():
    """Handle image analysis via base64 data"""
    try:
        data = request.get_json()
        
        if not data or 'image' not in data:
            return jsonify({"error": "يرجى إرفاق صورة"}), 400
        
        image_data = data.get('image', '')
        user_prompt = data.get('prompt', '')
        
        if not image_data:
            return jsonify({"error": "بيانات الصورة فارغة"}), 400
        
        print(f"🖼️ Analyzing image with prompt: {user_prompt[:50]}...")
        
        # Analyze the image
        response = rag_chatbot.analyze_image_from_base64(image_data, user_prompt)
        
        return jsonify({"reply": response})
        
    except Exception as e:
        print(f"Error in analyze_image endpoint: {e}")
        return jsonify({"error": "حدث خطأ أثناء تحليل الصورة"}), 500

@app.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "documents_loaded": len(rag_chatbot.documents),
        "embeddings_created": rag_chatbot.embeddings is not None,
        "image_analysis_enabled": True,
        "upload_folder": app.config['UPLOAD_FOLDER'],
        "allowed_extensions": list(ALLOWED_EXTENSIONS)
    })

@app.route("/debug", methods=["GET", "POST"])
def debug_retrieval():
    """Debug endpoint to test document retrieval"""
    try:
        if request.method == "POST":
            data = request.get_json()
            query = data.get("query", "").strip()
        else:
            query = request.args.get("query", "").strip()
        
        if not query:
            return jsonify({
                "error": "Please provide a query",
                "total_documents": len(rag_chatbot.documents),
                "sample_documents": [doc[:100] + "..." for doc in rag_chatbot.documents[:3]]
            })
        
        # Test document retrieval
        relevant_docs = rag_chatbot.retrieve_relevant_documents(query, k=5)
        
        result = {
            "query": query,
            "total_documents": len(rag_chatbot.documents),
            "retrieved_documents": len(relevant_docs),
            "documents": []
        }
        
        for doc in relevant_docs:
            result["documents"].append({
                "question": doc['metadata']['question'],
                "answer": doc['metadata']['answer'][:200] + "...",
                "category": doc['metadata']['label'],
                "similarity": round(doc['similarity'], 3)
            })
        
        return jsonify(result)
        
    except Exception as e:
        return jsonify({"error": str(e)})

if __name__ == "__main__":
    print("🚀 Starting RAG-Enhanced Medical Chatbot...")
    print(f"📊 Loaded {len(rag_chatbot.documents)} medical documents")
    print("🌐 Server starting on http://0.0.0.0:5000")
    print("\n📱 Available endpoints:")
    print("   • Main API: http://localhost:5000")
    print("   • Image Upload Interface: http://localhost:5000/upload")
    print("   • Health Check: http://localhost:5000/health")
    print("   • Chat API: http://localhost:5000/chat")
    print("   • Debug: http://localhost:5000/debug")
    print("\n🖼️ Image analysis features enabled!")
    print("   • Upload medical images via web interface")
    print("   • Support for X-rays, medicines, lab reports")
    print("   • Arabic and English analysis")
    app.run(debug=True, host='0.0.0.0', port=5000)
