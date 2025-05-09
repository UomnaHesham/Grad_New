from flask import Flask, request, jsonify

app = Flask(__name__)

# Replace this with your actual Gemini logic
def get_gemini_response(message):
    # Example dummy response (replace with Gemini logic)
    return "This is a Gemini response to: " + message

@app.route('/chat', methods=['POST'])
def chat():
    data = request.get_json()
    user_message = data.get("message")
    reply = get_gemini_response(user_message)
    return jsonify({"reply": reply})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
