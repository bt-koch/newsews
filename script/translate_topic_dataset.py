import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import models.llm
import config.environvars as environvars

import pandas as pd
from tqdm import tqdm

print("Prepare data...")
df = pd.concat([
    pd.read_csv(environvars.paths.path_huggingface+"twitter-financial-news-topic/topic_train.csv"),
    pd.read_csv(environvars.paths.path_huggingface+"twitter-financial-news-topic/topic_valid.csv")
    ])
tqdm.pandas()

print("Begin with translation...")
df['translated_text'] = df['text'].progress_apply(models.llm.llama.translate)
print("Translation finished!")

print("Save file...")
df.to_csv(environvars.paths.path_huggingface+"twitter-financial-news-topic/topic_translated.csv", index=False, sep=";")

print("Script finished!")
