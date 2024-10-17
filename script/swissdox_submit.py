import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import data.extract

rics = [x.get("ric") for x in data.extract.swissdox.query_inputs]

for r in rics:
    data.extract.swissdox.prepare_and_submit_query(ric=r)
