import os
import requests
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app) 

# La clave la leerá de Render por seguridad
API_KEY = os.environ.get("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")
URL = "https://integrate.api.nvidia.com/v1/chat/completions"

@app.route("/")
def home():
    return "Servidor de Chat Pete funcionando"

@app.route("/chat", methods=["POST"])
def chat():
    data = request.get_json()
    mensaje = data.get("mensaje", "")

    if not mensaje:
        return jsonify({"error": "Mensaje vacío"}), 400

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": "meta/llama-3.1-8b-instruct",
        "messages": [{"role": "user", "content": mensaje}],
        "temperature": 0.7,
        "max_tokens": 1024
    }

    try:
        response = requests.post(URL, headers=headers, json=payload, timeout=60)
        response.raise_for_status()
        respuesta_texto = response.json()["choices"][0]["message"]["content"]
        return jsonify({"respuesta": respuesta_texto})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
