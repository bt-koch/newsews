import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import config.environvars as environvars
import data.extract
import models.llm
from models.apply_models import calculate_sentiment

import pandas as pd
import numpy as np

from pandarallel import pandarallel
pandarallel.initialize(progress_bar=True)

print("Prepare data...")
df = pd.read_csv(environvars.paths.path_swissdox+"swissdox.csv")
device = -1 # to utilize parallelized computation, using "mps" this does not work
query_input = data.extract.swissdox.query_inputs

num_splits = int(np.ceil(df.shape[0] / 500))
dfs = np.array_split(df, num_splits)

for i in range(0, len(dfs)):
    print("Estimate sentiment for chunk "+str(i+1)+" of "+str(len(dfs))+"...")
    temp = dfs[i]
    temp["sentiment_score"] = temp.parallel_apply(lambda x: calculate_sentiment(
        x,
        query_input=query_input,
        device=device,
        model="finbert_german_sentiment"
    ), axis=1)
    print("Sentiment estimation of chunk "+str(i+1)+" finished, save file...")
    temp.to_csv(environvars.paths.path_preprocessed+"sentiment_scores/chunk_"+str(i+1)+".csv", index=False, sep=";")
