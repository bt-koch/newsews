import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import config.environvars as environvars
import models.llm

import pickle
import pandas as pd
from tqdm import tqdm

with open(environvars.paths.path_swissdox+"cs_sentiment_randomsample.pkl", "rb") as file:
    df = pickle.load(file)

translated_leads = pd.read_csv(environvars.paths.path_preprocessed+"translated_leads.csv", sep=";")
translated_leads = translated_leads[["content_id", "translated_text"]]

df_topic = pd.merge(df, translated_leads, on="content_id", how="left")
df_topic = df_topic[["content_id", "translated_text"]]
df_topic = df_topic[~pd.isna(df_topic["translated_text"])]

tqdm.pandas()

print("start with topic classification...")

pipe = models.llm.finbert_english_topic.model_initialise()
df_topic["topic"] = df_topic["translated_text"].progress_apply(lambda x: models.llm.finbert_english_topic.finbert_english_topic(pipe, x))

print("topic classification finished! Save results...")

result = pd.merge(df, df_topic, on="content_id", how="left")
result.to_csv(environvars.paths.path_preprocessed+"cs_example.csv", sep=";", index=False)

print("script finished!")