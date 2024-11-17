import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import config.environvars as environvars
import ingest.extract
import models.llm
from models.apply_models import calculate_sentiment

import pandas as pd
import numpy as np

from pandarallel import pandarallel
pandarallel.initialize(progress_bar=True)

datasource = "refinitiv" # either "swissdox" or "refinitiv"

if datasource == "swissdox":
    file_news = "dataset_clean.csv"
    model = "finbert_german_sentiment"
    folder = "sentiment_scores/"
elif datasource == "refinitiv":
    file_news = "dataset_refinitiv_clean.csv"
    model = "finbert_english_sentiment"
    folder = "sentiment_scores_refinitiv/"
else:
    sys.exit("datasource = "+datasource+" is not accepted input.")


print("Prepare data...")
df = pd.read_csv(environvars.paths.path_preprocessed+file_news, sep=";")
df = df[["identifier", "query_bank", "content"]]
device = -1 # to utilize parallelized computation, using "mps" this does not work
query_input = ingest.extract.swissdox.query_inputs

num_splits = int(np.ceil(df.shape[0] / 500))
dfs = np.array_split(df, num_splits)

for i in range(0, len(dfs)):
    print("Estimate sentiment for chunk "+str(i+1)+" of "+str(len(dfs))+"...")
    temp = dfs[i]
    temp["sentiment_score"] = temp.parallel_apply(lambda x: calculate_sentiment(
        x,
        query_input=query_input,
        device=device,
        model=model
    ), axis=1)
    print("\nSentiment estimation of chunk "+str(i+1)+" finished, save file...")
    temp.to_csv(environvars.paths.path_preprocessed+folder+"chunk_"+str(i+1)+".csv", index=False, sep=";")
