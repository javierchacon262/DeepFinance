from langchain_core.prompts import PromptTemplate
from langchain_community.llms import LlamaCpp
from langchain.chains import LLMChain
import time

start = time.time()
# Ruta al modelo GGUF
MODEL_PATH = "./models/DeepSeek-R1-Distill-Llama-8B-Q4_K_M.gguf"

# Inicializar el modelo local con LlamaCpp
llm = LlamaCpp(
    model_path=MODEL_PATH,  # Ruta al archivo del modelo GGUF
    temperature=0.7,        # Controla la creatividad de las respuestas
    max_tokens=4096,         # Límite de tokens generados
    n_ctx=8192,             # Contexto máximo (ajusta según capacidad de RAM)
    n_threads=6             # Ajusta según los núcleos de CPU disponibles
)

# Definir un prompt personalizado para LangChain
prompt = PromptTemplate(
    input_variables=["query"],
    template="Eres un asistente de análisis financiero. Responde de manera detallada: {query}"
)

# Crear una cadena con LangChain
chain = LLMChain(llm=llm, prompt=prompt)

# Hacer una pregunta al modelo
query = "Analiza la tendencia del mercado con los siguientes niveles: Soportes en 105, 110, 115. Resistencias en 120 y 125."
response = chain.run(query)

# Mostrar la respuesta generada
print("\nRespuesta del modelo:\n", response)
end = time.time()
time_elapsed = end - start
print(time_elapsed)