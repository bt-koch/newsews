import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import models.llm
import config.environvars as environvars

import pandas as pd
import numpy as np
from tqdm import tqdm

print("Prepare data...")
df = pd.concat([
    pd.read_csv(environvars.paths.path_huggingface+"twitter-financial-news-topic/topic_train.csv"),
    pd.read_csv(environvars.paths.path_huggingface+"twitter-financial-news-topic/topic_valid.csv")
    ])
tqdm.pandas()

dfs = np.array_split(df, 200)

for i in range(0, len(dfs)):
    print("Translate chunk "+str(i+1)+" of "+str(len(dfs))+"...")
    temp = dfs[i]
    temp["translated_text"] = temp["text"].progress_apply(models.llm.llama.translate)
    print("Translation of chunk "+str(i+1)+" finished, save file...")
    temp.to_csv(environvars.paths.path_huggingface+"twitter-financial-news-topic/translation/chunk_"+str(i+1)+".csv",
                index=False, sep=";")

print("Script finished!")
