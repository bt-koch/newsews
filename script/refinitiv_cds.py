import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import ingest.extract
import config.environvars as environvars

import pandas as pd

ingest.extract.refinitiv.connect()

meta = ingest.extract.swissdox.query_inputs

ric_equities = {entry['query_name']: entry['ric'] for entry in meta}
ric_cds = []

for query_name, ric in ric_equities.items():
    ric_cds.append(ingest.extract.refinitiv.ric_cds(ric))

ric_cds = pd.concat(ric_cds)
ric_cds = ric_cds[ric_cds["ric_cds"].notnull()]

cds = ingest.extract.refinitiv.get_cds(ric_cds)

cds.to_csv(environvars.paths.path_refinitiv+"cds.csv", index=False, sep=";")
