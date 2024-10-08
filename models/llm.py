import config.environvars as environvars

import ollama
from transformers import AutoTokenizer, AutoModelForSequenceClassification, pipeline
import torch
import numpy as np

class llama:

    def define_topic(text):
        instruction = """
        I will provide you with the content of a media article.
        Can you classify the topic of the article?
        Answer with a single keyword from the following selection: Economy, Sports, Weather, Culture, War in Ucraine
        In your response, please provide the keyword and only the keyword, no further text is necessary.
        The text might be in german, english or french.
        Here the article:
        """
        response = ollama.chat(model="llama3.1", messages=[
            {
                "role": "user",
                "content": instruction+"\n"+text
            }
        ])
        return(response["message"]["content"])
    
    def translate(text):
        instruction = """
        Translate the following text into german. Only provide the translated text:'
        """
        response = ollama.chat("llama3.1", messages=[
            {
                "role": "user",
                "content": instruction+text
            }
        ])
        return(response["message"]["content"])

class finbert_german:

    def model_initialise():
        tokenizer = AutoTokenizer.from_pretrained(environvars.paths.path_huggingface+"GermanFinBert_SC_Sentiment")
        model = AutoModelForSequenceClassification.from_pretrained(environvars.paths.path_huggingface+"GermanFinBert_SC_Sentiment")
        return tokenizer, model


def finbert_german_sentiment(text, tokenizer, model, device):
    pipe = pipeline("text-classification", model=model, tokenizer=tokenizer, device=device)
    try:
        response = pipe(text)
        result_map = {"Positiv": 1, "Neutral": 0, "Negativ": -1}
        return(result_map.get(response[0]["label"]))
    except:
        print("to do")
        return(np.nan)

    

def select_device():
    if torch.backends.mps.is_available():
        print("Apple Silicon GPU available.")
        device = torch.device("mps")
    else:
        device = torch.device("cpu")
    return(device)