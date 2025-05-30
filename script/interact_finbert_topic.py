import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import config.environvars as environvars
import models.llm

import pandas as pd

pipe = models.llm.finbert_english_topic.model_initialise()


# "LABEL_0": "Analyst Update",
# "LABEL_1": "Fed | Central Banks",
# "LABEL_2": "Company | Product News",
# "LABEL_3": "Treasuries | Corporate Debt",
# "LABEL_4": "Dividend",
# "LABEL_5": "Earnings",
# "LABEL_6": "Energy | Oil",
# "LABEL_7": "Financials",
# "LABEL_8": "Currencies",
# "LABEL_9": "General News | Opinion",
# "LABEL_10": "Gold | Metals | Materials",
# "LABEL_11": "IPO",
# "LABEL_12": "Legal | Regulation",
# "LABEL_13": "M&A | Investments",
# "LABEL_14": "Macro",
# "LABEL_15": "Markets",
# "LABEL_16": "Politics",
# "LABEL_17": "Personnel Change",
# "LABEL_18": "Stock Commentary",
# "LABEL_19": "Stock Movement",


df = pd.read_csv(environvars.paths.path_preprocessed+"translated_leads.csv", sep=";")

import random
input = df.iloc[random.randint(0, df.shape[0])]["lead"]
print(input)
models.llm.finbert_english_topic.finbert_english_topic(pipe, input)


bla = pd.read_csv("/Users/belakoch/data/preprocessed_data/cs_example.csv", sep=";")
topic = bla["topic"].value_counts().reset_index()
topic