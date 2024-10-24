import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import ingest.transform
import models.llm
import config.environvars as environvars

import pandas as pd
import numpy as np
from pandarallel import pandarallel
pandarallel.initialize(progress_bar=True)

print("Prepare data...")
df = pd.read_csv(environvars.paths.path_preprocessed+"dataset_clean.csv", sep=";")

df["lead"] = df["content"].str.extract(r"<ld>(.*?)</ld>")
df["lead"] = df["lead"].apply(lambda x: ingest.transform.preprocess.text.remove_tags(x) if isinstance(x, str) else x)

df = df[["identifier", "lead", "head"]]
df = df.drop_duplicates()

dfs = np.array_split(df, 200)

for i in range(0, len(dfs)):
    print("Translate chunk "+str(i+1)+" of "+str(len(dfs))+"...")
    temp = dfs[i]
    print("...translate lead...")
    temp["translated_lead"] = temp["lead"].parallel_apply(models.llm.llama.translate)
    print("\n...translate head...")
    temp["translated_head"] = temp["head"].parallel_apply(models.llm.llama.translate)
    print("Translation of chunk "+str(i+1)+" finished, save file...")
    temp.to_csv(environvars.paths.path_preprocessed+"/translation/chunk_"+str(i+1)+".csv", index=False, sep=";")

