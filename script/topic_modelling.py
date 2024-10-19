import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import config.environvars as environvars
import models.llm

import numpy as np
import pandas as pd
from pandarallel import pandarallel
pandarallel.initialize(progress_bar=True)

df = pd.read_csv(environvars.paths.path_preprocessed+"dataset_clean.csv", sep=";")

translated_leads = pd.read_csv(environvars.paths.path_preprocessed+"translated_leads_and_heads.csv", sep=";")
translated_leads = translated_leads[["identifier", "translated_lead", "translated_head"]]

df = pd.merge(df, translated_leads, on="identifier", how="left")
df = df[["identifier", "translated_lead", "translated_head"]]

num_splits = int(np.ceil(df.shape[0] / 500))
dfs = np.array_split(df, num_splits)

pipe = models.llm.finbert_english_topic.model_initialise(device=-1)

for i in range(0, len(dfs)):
    print("Estimate topic for chunk "+str(i+1)+" of "+str(len(dfs))+"...")
    temp = dfs[i]
    print("...estimate lead...")
    temp["topic_lead"] = temp["translated_lead"].parallel_apply(lambda x: models.llm.finbert_english_topic.finbert_english_topic(pipe, x) if isinstance(x, str) else x)
    print("\n...estimate head...")
    temp["topic_lead"] = temp["translated_head"].parallel_apply(lambda x: models.llm.finbert_english_topic.finbert_english_topic(pipe, x) if isinstance(x, str) else x)
    print("\nTopic estimation of chunk "+str(i+1)+" finished, save file...")
    temp.to_csv(environvars.paths.path_preprocessed+"topics/chunk_"+str(i+1)+".csv", index=False, sep=";")
