import pandas as pd
import json
import time
from langchain_core.prompts import PromptTemplate
from langchain_community.llms import LlamaCpp
from langchain.chains import LLMChain
from data_requests import *


def format_response(text, words_per_line=10):
    words = text.split()
    formatted_text = "\n".join(" ".join(words[i:i + words_per_line]) for i in range(0, len(words), words_per_line))
    return formatted_text

def prompt_templates():
    # 🔹 Define Prompt Templates
    intro_prompt = """
    <|system|> You are a professional market analyst.
    You will receive Bitcoin's historical price data in **30-candle batches** and must observe trends in real time.
    Do NOT generate a full report.
    Instead, analyze the batch, take note of any trend, and **wait for the next batch before making final conclusions**.
    """

    batch_prompt = """
    <|system|> Here is the most recent batch of 30 candles:\n
    {MarketHistory}\n\n
    The most recent candle in this batch is:\n
    {CurrentCandle}\n\n
    
    Analyze the trend, volume, indicators and price movement.\n
    Do NOT make a final decision yet—just take note of **current conditions**.\n\n
    
    <|assistant|>
    """

    summary_prompt = """
    <|system|> You are an expert financial summarizer.\n
    Your task is to shorten the given market analysis while keeping all important details.\n
    
    Here is the full analysis:\n
    {FullAnalysis}\n\n
    
    Summarize it into a short and **actionable** market observation (max **2 sentences**).\n
    Avoid excessive details. Focus only on key **price trends** and **market movement**.\n\n
    
    <|assistant|>
    """

    live_batch_prompt = """
    <|system|> Here is the most recent batch of 30 candles: \n
    {MarketHistory}\n\n
    The most recent candle in this batch is: \n
    {CurrentCandle}\n\n
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

    hist_prompt_template = PromptTemplate(
        input_variables=["MarketHistory", "CurrentCandle"],
        template=batch_prompt
    )

    live_prompt_template = PromptTemplate(
        input_variables=["MarketHistory", "CurrentCandle", "Timeframe", "Symbol", "LatestClose"],
        template=live_batch_prompt
    )

    summary_prompt_template = PromptTemplate(
        input_variables=["FullAnalysis"],
        template=summary_prompt
    )

    return intro_prompt_template, hist_prompt_template, live_prompt_template, summary_prompt_template


def historic_context(llm, sum_llm, bar_count, timeframe, symbol, window_size, intro_prompt_template, hist_prompt_template, summary_prompt_template, PUSH = 32768, PULL = 32769, SUB = 32770):

    # Intro chain
    chain = LLMChain(llm=llm, prompt=intro_prompt_template)
    chain.invoke({})

    # Summarization Chain
    sum_chain = LLMChain(
        llm=sum_llm,
        prompt=PromptTemplate(
            input_variables=["FullAnalysis"],
            template=summary_prompt_template
        )
    )

    # 🔹 Get Data for Historical Learning Phase (Chunked)
    batches = get_hist_data_chunks(bar_count, timeframe, symbol, PUSH, PULL, SUB, window_size)
    sleep(1)

    market_history = []  # Store the first batch as history


    # 🕍 Real-Time Market Analysis Loop
    print("\n📊 Initializing Market Analysis...\n")

    observations = []
    iteration = 0

    # Intro to the context of the current market situation
    for batch in batches:
        try:
            print("batch #" + str(iteration) + "\n\n")
            # Get the next batch from the generator
            current_batch = batch
            market_history.append(current_batch)  # Append to history
            current_candle = current_batch.iloc[-1][:]  # The last candle of the batch

            # 🔹 Format Data for the Model
            formatted_candle = json.dumps(current_candle.to_dict(), indent=2)
            formatted_history = json.dumps(market_history[-1].to_dict(), indent=2)  # Only pass the latest batch
            chain = LLMChain(llm=llm, prompt=hist_prompt_template)

            # Regular batch analysis
            response = chain.invoke({
                "MarketHistory": formatted_history,
                "CurrentCandle": formatted_candle
            })

            # Summarized response from Mistral
            sum_response = sum_chain.invoke({response['text']})
            observations.append(sum_response)
            print(f"📊 Market Insight [{iteration + 1}]:\n{format_response(sum_response['text'])}\n")

            iteration += 1

        except StopIteration:
            print("⚠️ No more historical data available. Restarting generator...")
            continue  # Continue fetching new batches

    return llm, sum_llm, observations, market_history


def live_inference(llm, sum_llm, observations, market_history, batch, timeframe, symbol, live_prompt_template, summary_prompt_template):

    # Summarization Chain
    sum_chain = LLMChain(
        llm=sum_llm,
        prompt=PromptTemplate(
            input_variables=["FullAnalysis"],
            template=summary_prompt_template
        )
    )

    # Extract key information for the model to further analyze
    latest_price = batch.iloc[-1]['Close']

    # Now that we have our models in context and the live data initialized we can start inferencing on live data
    market_history.append(batch)  # Append to history
    current_candle = batch.iloc[-1][:]  # The last candle of the batch
    # 🔹 Format Data for the Model
    formatted_candle = json.dumps(current_candle.to_dict(), indent=2)

    formatted_history = json.dumps(market_history[-1].to_dict(), indent=2)  # Only pass the latest batch
    formated_timeframe = json.dumps(timeframe)
    formatted_symbol = symbol
    formatted_price = json.dumps(latest_price)
    #Here we first analyze the new rolling window
    # Create the LLM chain
    llm_chain = LLMChain(llm=llm, prompt=live_prompt_template)
    # Ask for deepseek r1 responde
    response = llm_chain.invoke({
        "MarketHistory": formatted_history,
        "CurrentCandle": formatted_candle,
        "Timeframe": formated_timeframe,
        "Symbol": formatted_symbol,
        "LatestClose": formatted_price
    })
    # Summarized response from Mistral
    sum_response = sum_chain.invoke({response['text']})
    observations.append(sum_response)
    response_return = f"📊 Live Market Insight:\n{format_response(sum_response['text'])}\n\n"
    return llm, sum_llm, observations, market_history, response_return