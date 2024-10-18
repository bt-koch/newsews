import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import models.llm
device = models.llm.select_device()
model_initialise = models.llm.finbert_german_sentiment.model_initialise()

input="""
Dieser Text enthält keine relevanten Informationen, aber beinhaltet einige
negative Stichworte wie schlecht oder kritisch.
"""
models.llm.finbert_german_sentiment.finbert_german_sentiment(
            input,
            tokenizer=model_initialise[0],
            model=model_initialise[1],
            device=device
        )

input="""
Dieser Text ist nicht relevant für die Bank, beinhaltet aber aussagelos
schlechte Stichwörter wie fallender Aktienkurs oder geringerer erwarteter Gewinn.
"""
models.llm.finbert_german_sentiment.finbert_german_sentiment(
            input,
            tokenizer=model_initialise[0],
            model=model_initialise[1],
            device=device
        )

input="""
Dieser Text ist relevant für die Bank, diese ist betroffen von
fallenden Aktienkursen oder geringeren erwarteten Gewinne.
"""
models.llm.finbert_german_sentiment.finbert_german_sentiment(
            input,
            tokenizer=model_initialise[0],
            model=model_initialise[1],
            device=device
        )

##################################################################################
# Demo of pretty nuanced ability to understand context
##################################################################################

# Input 1: we expect negative sentiment
# result: negative
input="""
Diese Neuigkeiten über die schlechte Entwicklung der allgemeinen Wirtschaftslage
hat einen beträchtlichen Einfluss auf die Credit Suisse.
"""
models.llm.finbert_german_sentiment.finbert_german_sentiment(
            input,
            tokenizer=model_initialise[0],
            model=model_initialise[1],
            device=device
        )

# Input 2: exactly the same text but one letter more such that we expect neutral
# result: neutral
input="""
Diese Neuigkeiten über die schlechte Entwicklung der allgemeinen Wirtschaftslage
hat keinen beträchtlichen Einfluss auf die Credit Suisse.
"""
models.llm.finbert_german_sentiment.finbert_german_sentiment(
            input,
            tokenizer=model_initialise[0],
            model=model_initialise[1],
            device=device
        )

# Input 3: minimal adjustment such that we expect positive sentiment
# result: positive
input="""
Diese Neuigkeiten über die schlechte Entwicklung der allgemeinen Wirtschaftslage
hat einen beträchtlich vorteilhaften Einfluss auf die Credit Suisse.
"""
models.llm.finbert_german_sentiment.finbert_german_sentiment(
            input,
            tokenizer=model_initialise[0],
            model=model_initialise[1],
            device=device
        )