import pandas as pd
import json
import time
from langchain_core.prompts import PromptTemplate
from langchain_community.llms import LlamaCpp
from langchain.chains import LLMChain
from langchain.memory import ConversationBufferMemory
from data_requests import *
import matplotlib.pyplot as plt

bar_count       = 60
window_size     = 30
timeframes      = [1, 5, 15, 60, 240, 1440]
symbols         = ['BTCUSD', 'US2000', 'USTEC', 'GBPUSD', 'GBPJPY', 'GBPNOK']
PUSH, PULL, SUB = 32768, 32769, 32770

# 🔹 Cargar el modelo en GPU (ajusta el path del modelo)
llm = LlamaCpp(
    model_path="./models/DeepSeek-R1-Distill-Llama-8B-Q4_K_M.gguf",
    n_gpu_layers=-1,
    n_ctx=16384,
    temperature=0.65,
    top_p=0.7,
    max_tokens=2048,
    verbose=False,
    n_threads=1,
    n_batch=512,
    n_gqa=32

)

#mistral-7b-instruct-v0.2.Q4_K_M.gguf

sum_llm = LlamaCpp(
    model_path="./models/mistral-7b-instruct-v0.2.Q4_K_M.gguf",
    n_gpu_layers=-1,
    n_ctx=16384,
    temperature=0.65,
    top_p=0.6,
    max_tokens=128,
    verbose=False,
    n_threads=1,
    n_batch=512,
    n_gqa=32

)


def format_response(text, words_per_line=10):
    words = text.split()
    formatted_text = "\n".join(" ".join(words[i:i + words_per_line]) for i in range(0, len(words), words_per_line))
    return formatted_text

SRLevels = get_market_data_sr(symbols[-1])


# 🔹 Define Prompt Templates
intro_prompt = """
<|system|> You are a professional market analyst.
You will receive GBPNOK's historical price data in **30-candle batches** and must observe trends in real time and compare with the 20 EMA, the 14 RSI and the most important support and resistance levels, you can use them to picture the high probability zones in the chart.
Do NOT generate a full report.
Instead, analyze the batch, take note of any trend, and **wait for the next batch before making final conclusions**.
"""

batch_prompt = """
<|system|> Here is the most recent batch of 30 candles:\n
{MarketHistory}\n\n
The most recent candle in this batch is:\n
{CurrentCandle}\n\n
The most important support and resistance levels are: you can use them to picture the high probability zones in the chart.\n
{SRLevels}\n\n


Analyze the trend, volume, indicators and price movement.\n
Do NOT make a final decision yet, just take note of **current conditions**.\n\n

<|assistant|>
"""

summary_prompt = """
<|system|> You are an expert financial summarizer.\n
Your task is to shorten the given market analysis while keeping all important details.\n

Here is the full analysis:\n
{FullAnalysis}\n\n

You get to decide now: Summarize the analysis into only 1 short and **actionable** market position (only 3 options: **BUY**, **SELL**, **WAIT**).\n
Avoid excessive details. Focus only on key **price trends** and **market movement**.\n\n

<|assistant|>
"""

live_batch_prompt = """
<|system|> Here is the most recent batch of 30 candles: \n
{MarketHistory}\n\n
The most recent candle in this batch is: \n
{CurrentCandle}\n\n
The most important support and resistance levels are: you can use them to picture the high probability zones in the chart.\n
{SRLevels}\n\n

Inside market history we have some indicators for you (last two columns):\n
RSI period 14\n
EMA period 20\n\n
I have some context for you to have a better understanding of the candles:\n
- Timeframe: {Timeframe}\n
- Symbol: {Symbol}\n
- Latest Close Price: {LatestClose}\n\n

## Question: \n
## Analyze the trend, volume, indicators, price movement and context.\n
## What position would you take in this situation?\n\n

<|assistant|>
"""


# 🔹 Initialize LangChain Components
intro_prompt_template = PromptTemplate(
    template=intro_prompt
)

prompt_template = PromptTemplate(
    input_variables=["MarketHistory", "CurrentCandle", "SRLevels"],
    template=batch_prompt
)

live_prompt_template = PromptTemplate(
    input_variables=["MarketHistory", "CurrentCandle", "SRLevels", "Timeframe", "Symbol", "LatestClose"],
    template=live_batch_prompt
)

# Summarization Chain
sum_chain = LLMChain(
    llm=sum_llm,
    prompt=PromptTemplate(
        input_variables=["FullAnalysis"],
        template=summary_prompt
    )
)

chain = LLMChain(
    llm=llm,
    prompt=intro_prompt_template
)
response = chain.invoke({})

# 🔹 Get Data for Historical Learning Phase (Chunked)
batches = get_hist_data_chunks(bar_count, timeframes[3], symbols[-1], PUSH, PULL, SUB, window_size)
sleep(1)

market_history = []  # Store the first batch as history


# 🕍 Real-Time Market Analysis Loop
print("\n📊 Initializing Market Analysis...\n")
print(intro_prompt)

observations = []
iteration = 0

# Intro to the context of the current market situation
for batch in batches:
    try:
        print("batch #" + str(iteration) + "\n\n")
        # Get the next batch from the generator
        # Log Returns
        current_batch = batch
        market_history.append(current_batch)  # Append to history
        current_candle = current_batch.iloc[-1][:]  # The last candle of the batch

        # 🔹 Format Data for the Model
        formatted_candle = json.dumps(current_candle.to_dict(), indent=2)
        formatted_history = json.dumps(market_history[-1].to_dict(), indent=2)  # Only pass the latest batch
        formatted_SRL     = json.dumps(SRLevels, indent=3)
        chain = LLMChain(llm=llm, prompt=prompt_template)

        # Regular batch analysis
        response = chain.invoke({
            "MarketHistory": formatted_history,
            "CurrentCandle": formatted_candle,
            "SRLevels": formatted_SRL,
        })

        # Summarized response from Mistral
        sum_response = sum_chain.invoke({response['text']})
        observations.append(sum_response)
        print(f"📊 Market Insight [{iteration + 1}]:\n{format_response(sum_response['text'])}\n")

        iteration += 1

    except StopIteration:
        print("⚠️ No more historical data available. Restarting generator...")
        continue  # Continue fetching new batches

# Initialize rolling deque buffer
rolling_window = deque(maxlen=window_size)

# After initializing the context for the models to reason from the market situation we can now
# call the initializer of the rolling window
batch, rolling_window = init_live_data_rolling(rolling_window, window_size, timeframes[3], symbols[-1], PUSH, PULL, SUB)

# Extract key information for the model to further analyze
latest_price = batch.iloc[-1]['Close']

# Now that we have our models in context and the live data initialized we can start inferencing on live data
while True:
    market_history.append(batch)  # Append to history
    current_candle = batch.iloc[-1][:]  # The last candle of the batch

    # 🔹 Format Data for the Model
    formatted_candle = json.dumps(current_candle.to_dict(), indent=2)
    formatted_history = json.dumps(market_history[-1].to_dict(), indent=2)  # Only pass the latest batch
    formatted_SRL = json.dumps(SRLevels, indent=3)
    formated_timeframe = json.dumps(timeframes[3])
    formatted_symbol = symbols[-1]
    formatted_price = json.dumps(latest_price)

    #Here we first analyze the new rolling window
    # Create the LLM chain
    llm_chain = LLMChain(llm=llm, prompt=live_prompt_template)

    # Ask for deepseek r1 responde
    response = llm_chain.invoke({
        "MarketHistory": formatted_history,
        "CurrentCandle": formatted_candle,
        "SRLevels": formatted_SRL,
        "Timeframe": formated_timeframe,
        "Symbol": formatted_symbol,
        "LatestClose": formatted_price
    })

    # Summarized response from Mistral
    sum_response = sum_chain.invoke({response['text']})
    observations.append(sum_response)
    print(f"📊 Live Market Insight:\n{format_response(sum_response['text'])}\n\n")


    # Here we update the rolling window asking to the server for the last candle only
    batch, rolling_window = update_rolling_window(rolling_window, timeframes[3], symbols[-1], PUSH, PULL, SUB)
    print("\n\n Last 5 candles on the rolling window:\n\n")
    print(batch.tail())
    print("\n\n")
    sleep(60)

