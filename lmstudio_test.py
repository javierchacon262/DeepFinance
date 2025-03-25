import requests
from time import sleep

# URL del endpoint de chat/completions
url = "http://localhost:1234/v1/chat/completions"

# Payload para el endpoint de chat
payload = {
    "messages": [
        {"role": "system", "content": "Eres un analista financiero experto en identificar soportes y resistencias."},
        {"role": "user", "content": (
            "Analiza los siguientes datos del mercado y proporciona un razonamiento detallado: "
            "Soportes detectados: 100, 105, 110. Resistencia detectada: 120. "
            "Clustering indica acumulación cerca de 110. ¿Qué podrías inferir? "
            "Describe las posibles implicaciones para el precio y estrategias que podrías considerar."
        )}
    ],
    "max_tokens": 4096,
    "temperature": 0.5,
    "top_p": 0.9,
    "stop": ["\n"]
}

# Enviar solicitud POST
response = requests.post(url, json=payload, timeout=300)
sleep(30)

# Manejo de la respuesta
if response.status_code == 200:
    result = response.json()
    if "choices" in result and len(result["choices"]) > 0:
        reasoning = result["choices"]
        print("Razonamiento del modelo:")
        print(reasoning)
    else:
        print("No se generó texto en la respuesta.")
else:
    print(f"Error: {response.status_code}")
    print(response.text)