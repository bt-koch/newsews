import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import config.environvars as environvars
import ingest.extract
import models.rule_based_models

import pandas as pd
from pandarallel import pandarallel
pandarallel.initialize(progress_bar=True)

print("Prepare data...")
df = pd.read_csv(environvars.paths.path_swissdox+"swissdox.csv")
df = df[df["language"] == "de"]
query_input = ingest.extract.swissdox.query_inputs

print("start with topic assignment...")
df["assigned_topic"] = df.parallel_apply(lambda x: models.rule_based_models.topic_keywords(x), axis=1)
df.to_csv(environvars.paths.path_preprocessed+"assigned_topic.csv", sep=";", index=False)
print("\nfinished")

df.loc[df["assigned_topic"].str.startswith("not about"), "assigned_topic"] = "drop"
rubric = df["assigned_topic"].value_counts().reset_index()
print("I keep "+str(round(rubric.iloc[0]["count"] / (rubric.iloc[0]["count"]+rubric.iloc[1]["count"]), 2))+" of articles")

df = df[df["assigned_topic"] == "wirtschaft"]
df = df[["content", "query_bank"]]
df = df.drop_duplicates()
df.to_csv(environvars.paths.path_preprocessed+"estim_dataset.csv", sep=";", index=False)
