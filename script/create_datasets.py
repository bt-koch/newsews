if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")

import config.environvars as environvars

import os
import re
import pandas as pd

# translated leads
path = environvars.paths.path_huggingface+"twitter-financial-news-topic/translation"
files = [f for f in os.listdir(path) if re.match(r"^chunk_\d{1,3}.csv$", f)]
df = [pd.read_csv(os.path.join(path, f), sep=";") for f in files]
df = pd.concat(df)
df.to_csv(environvars.paths.path_preprocessed+"translated_leads.csv", index=False, sep=";")

# sentiment scores
path = environvars.paths.path_preprocessed+"sentiment_scores"
files = [f for f in os.listdir(path) if re.match(r"^chunk_\d{1,3}.csv$", f)]
df = [pd.read_csv(os.path.join(path, f), sep=";") for f in files]
df = pd.concat(df)
df.to_csv(environvars.paths.path_preprocessed+"first_result_sentiment.csv", index=False, sep=";")
