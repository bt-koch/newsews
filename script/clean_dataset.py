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
df = pd.read_csv(environvars.paths.path_preprocessed+"dataset_raw.csv")
df = df[df["language"] == "de"]
query_input = ingest.extract.swissdox.query_inputs

print("start with rubric assignment...")
df["assigned_rubric"] = df.parallel_apply(lambda x: models.rule_based_models.pattern_matching.assign_rubric(x), axis=1)
df.to_csv(environvars.paths.path_preprocessed+"assigned_rubric.csv", sep=";", index=False)
print("\nfinished")

df.loc[df["assigned_rubric"].str.startswith("not about"), "assigned_rubric"] = "drop"
rubric = df["assigned_rubric"].value_counts().reset_index()
print("I keep "+str(round(rubric.iloc[0]["count"] / (rubric.iloc[0]["count"]+rubric.iloc[1]["count"]), 2))+" of articles")

df = df[df["assigned_rubric"] == "wirtschaft"]
df = df[["content", "query_bank"]]
df = df.drop_duplicates()
df.to_csv(environvars.paths.path_preprocessed+"dataset_clean.csv", sep=";", index=False)
