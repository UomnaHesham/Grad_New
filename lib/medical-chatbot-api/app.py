from flask import Flask, request, jsonify
from flask_cors import CORS  # Import CORS

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Replace this with your actual Gemini logic
def get_gemini_response(message):
    return f"This is a Gemini response to: {message}"

@app.route('/chat', methods=['POST'])
def chat():
    data = request.get_json()  # Get the JSON data sent in the request
    user_message = data.get("message")
    if user_message:
        reply = get_gemini_response(user_message)
        return jsonify({"reply": reply})
    else:
        return jsonify({"error": "No message provided."}), 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
