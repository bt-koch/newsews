import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import data.extract
import models.llm
import models.apply_models
# import config.environvars as environvars

import pandas as pd
import numpy as np
from tqdm import tqdm

print("Prepare data...")
df = pd.read_csv(environvars.paths.path_swissdox+"swissdox.csv")
# df = df.iloc[1234:1236]
device = models.llm.select_device()
query_input = data.extract.swissdox.query_inputs

num_splits = int(np.ceil(df.shape[0] / 500))
dfs = np.array_split(df, num_splits)

tqdm.pandas()

for i in range(0, len(dfs)):
    print("Estimate sentiment for chunk "+str(i+1)+" of "+str(len(dfs))+"...")
    temp = dfs[i]
    temp["sentiment_score"] = temp.progress_apply(lambda x: models.apply_models.calculate_sentiment(
        x,
        query_input=query_input,
        device=device,
        model="finbert_german_sentiment"
    ), axis=1)
    print("Sentiment estimation of chunk "+str(i+1)+" finished, save file...")
    temp.to_csv(environvars.paths.path_preprocessed+"sentiment_scores/chunk_"+str(i+1)+".csv", index=False, sep=";")


