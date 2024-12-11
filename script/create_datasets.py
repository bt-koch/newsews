if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")

import config.environvars as environvars
import ingest.extract
import ingest.transform

import os
import re
import string
import random
import pandas as pd

# 1. Create news article datasets from API responses
step = 1

# =============================================================================.
# 1. Create news article datasets from API responses ----
# =============================================================================.

if step == 1:

    # swissdox news
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


    # refinitiv news
    path = environvars.paths.path_refinitiv
    files = [f for f in os.listdir(path) if f.startswith("dataset_newsarticles_")]
    df = []
    for file in files:
        temp = pd.read_csv(path+file, sep=";")
        temp = temp.rename(columns={"bank": "ric", "story": "content", "story_id": "content_id"})
        df.append(temp)
    df = pd.concat(df, axis=0, ignore_index=True)

    meta = pd.DataFrame([{"ric": i["ric"], "query_bank": i["query_name"]} for i in ingest.extract.swissdox.query_inputs])
    meta.to_csv(environvars.paths.path_meta+"mapping_ric.csv", sep=";")
    df = pd.merge(df, meta, on="ric", how="left")

    map = df[["content_id", "query_bank"]]
    map = map.drop_duplicates().reset_index(drop=True)
    identifiers = set()
    chars = string.ascii_letters + string.digits
    while len(identifiers) < map.shape[0]:
        id = "".join(random.choice(chars) for i in range(20))
        identifiers.add(id)
    identifiers = pd.DataFrame(identifiers, columns=["identifiers"])
    map["identifier"] = identifiers["identifiers"]
    map.to_csv(environvars.paths.path_meta+"mapping_refinitiv.csv", sep=";")

    df = pd.merge(df, map, on=["content_id", "query_bank"], how="left")
    df.to_csv(environvars.paths.path_preprocessed+"dataset_refinitiv_clean.csv", sep=";")
    # since we can expect that we only get "economic/finance" articles from refinitiv, we must not run cleaning step as in swissdox

# =============================================================================.
# 2. Sentiment Classification ----
# =============================================================================.

if step == 2:

    # sentiment scores
    path = environvars.paths.path_preprocessed+"sentiment_scores"
    files = [f for f in os.listdir(path) if re.match(r"^chunk_\d{1,3}.csv$", f)]
    df = [pd.read_csv(os.path.join(path, f), sep=";") for f in files]
    df = pd.concat(df)
    df = df[["identifier", "query_bank", "sentiment_score"]]

    meta = pd.read_csv(environvars.paths.path_preprocessed+"dataset_clean.csv", sep=";")
    meta = meta[["identifier", "pubtime"]]
    df = pd.merge(df, meta, how="left", on="identifier")

    df = df.rename(columns={"query_bank": "bank", "pubtime": "date"})
    df = df.drop_duplicates()
    df.to_csv(environvars.paths.path_results+"sentiment_scores.csv", index=False, sep=";")

    # refinitiv sentiment scores
    path = environvars.paths.path_preprocessed+"sentiment_scores_refinitiv"
    files = [f for f in os.listdir(path) if re.match(r"^chunk_\d{1,3}.csv$", f)]
    df = [pd.read_csv(os.path.join(path, f), sep=";") for f in files]
    df = pd.concat(df)
    df = df[["identifier", "query_bank", "sentiment_score"]]

    meta = pd.read_csv(environvars.paths.path_preprocessed+"dataset_refinitiv_clean.csv", sep=";")
    meta = meta[["identifier", "date"]]
    df = pd.merge(df, meta, how="left", on="identifier")

    df = df.rename(columns={"query_bank": "bank"})
    df = df.drop_duplicates()
    df.to_csv(environvars.paths.path_results+"sentiment_scores_refinitiv.csv", index=False, sep=";")




# =============================================================================.
# 3. Topic Modelling ----
# =============================================================================.

if step == 3:
    
    # translated leads
    path = environvars.paths.path_preprocessed+"translation"
    files = [f for f in os.listdir(path) if re.match(r"^chunk_\d{1,3}.csv$", f)]
    df = [pd.read_csv(os.path.join(path, f), sep=";") for f in files]
    df = pd.concat(df)
    df.to_csv(environvars.paths.path_preprocessed+"translated_leads_and_heads.csv", index=False, sep=";")

if step == 4:

    # topics
    path = environvars.paths.path_preprocessed+"topics"
    files = [f for f in os.listdir(path) if re.match(r"^chunk_\d{1,3}.csv$", f)]
    df = [pd.read_csv(os.path.join(path, f), sep=";") for f in files]
    df = pd.concat(df)
    df = df[["identifier", "topic_lead", "topic_head"]]
    df.to_csv(environvars.paths.path_results+"topics.csv", index=False, sep=";")




