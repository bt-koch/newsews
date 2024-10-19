import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")

import config.environvars as environvars

import pandas as pd
import random
import string

df = pd.read_csv(environvars.paths.path_swissdox+"swissdox.csv")
df = df[["content_id", "query_bank"]]
df = df.drop_duplicates().reset_index(drop=True)

identifiers = set()
chars = string.ascii_letters + string.digits
while len(identifiers) < df.shape[0]:
    id = "".join(random.choice(chars) for i in range(15))
    identifiers.add(id)
identifiers = pd.DataFrame(identifiers, columns=["identifiers"])
df["identifier"] = identifiers["identifiers"]

df.to_csv(environvars.paths.path_meta+"mapping.csv")
