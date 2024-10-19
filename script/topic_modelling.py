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
pandarallel.initialize(progress_bar=True, nb_workers=3)

df = pd.read_csv(environvars.paths.path_preprocessed+"estim_dataset.csv", sep=";")
# TODO: here use dataset_clean instead, and i can remove all cols other than the neceessary ones
# TODO: look if i can merge new identifier to translated_leads

translated_leads = pd.read_csv(environvars.paths.path_preprocessed+"translated_leads.csv", sep=";")
translated_leads = translated_leads[["content_id", "translated_text"]]

df = pd.merge(df, translated_leads, on="content_id", how="left")
df = df[["content_id", "translated_text"]]
df = df[~pd.isna(df["translated_text"])]

# num_splits = int(np.ceil(df.shape[0] / 500))
num_splits = int(np.ceil(df.shape[0] / 5))
dfs = np.array_split(df, num_splits)

dfs = dfs[0:3]

pipe = models.llm.finbert_english_topic.model_initialise()

for i in range(0, len(dfs)):
    print("Estimate topic for chunk "+str(i+1)+" of "+str(len(dfs))+"...")
    temp = dfs[i]
    temp["topic"] = temp["translated_text"].parallel_apply(lambda x: models.llm.finbert_english_topic.finbert_english_topic(pipe, x))
    print("\nTopic estimation of chunk "+str(i+1)+" finished, save file...")
    temp.to_csv(environvars.paths.path_preprocessed+"topics/chunk_"+str(i+1)+".csv", index=False, sep=";")
