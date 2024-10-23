if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")

import config.environvars as environvars
import ingest.transform

import os
import re
import string
import random
import pandas as pd

# swissdox data
path = environvars.paths.path_swissdox
files = [f for f in os.listdir(path) if f.endswith(".tsv.xz")]
df = []
for file in files:
    temp = ingest.transform.swissdox.read_tsv(file.removesuffix(".tsv.xz"))
    temp["query_bank"] = file.removesuffix(".tsv.xz")
    df.append(temp)
df = pd.concat(df, axis=0, ignore_index=True)

map = df[["content_id", "query_bank"]]
map = map.drop_duplicates().reset_index(drop=True)
identifiers = set()
chars = string.ascii_letters + string.digits
while len(identifiers) < map.shape[0]:
    id = "".join(random.choice(chars) for i in range(15))
    identifiers.add(id)
identifiers = pd.DataFrame(identifiers, columns=["identifiers"])
map["identifier"] = identifiers["identifiers"]
map.to_csv(environvars.paths.path_meta+"mapping.csv", sep=";")

df = pd.merge(df, map, on=["content_id", "query_bank"], how="left")
df.to_csv(environvars.paths.path_preprocessed+"dataset_raw.csv", sep=";")


# translated leads
path = environvars.paths.path_preprocessed+"translation"
files = [f for f in os.listdir(path) if re.match(r"^chunk_\d{1,3}.csv$", f)]
df = [pd.read_csv(os.path.join(path, f), sep=";") for f in files]
df = pd.concat(df)
df.to_csv(environvars.paths.path_preprocessed+"translated_leads_and_heads.csv", index=False, sep=";")


# sentiment scores
path = environvars.paths.path_preprocessed+"sentiment_scores"
files = [f for f in os.listdir(path) if re.match(r"^chunk_\d{1,3}.csv$", f)]
df = [pd.read_csv(os.path.join(path, f), sep=";") for f in files]
df = pd.concat(df)
df.to_csv(environvars.paths.path_preprocessed+"first_result_sentiment.csv", index=False, sep=";")
