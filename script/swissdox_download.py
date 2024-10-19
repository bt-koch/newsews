import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import ingest.extract

query_names = [x.get("query_name") for x in ingest.extract.swissdox.query_inputs]

for qn in query_names:
    ingest.extract.swissdox.get_data(query_name = qn)
