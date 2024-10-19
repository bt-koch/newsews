import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import ingest.extract

rics = [x.get("ric") for x in ingest.extract.swissdox.query_inputs]

for r in rics:
    ingest.extract.swissdox.prepare_and_submit_query(ric=r)
