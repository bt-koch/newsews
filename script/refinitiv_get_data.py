import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import config.environvars as environvars
import ingest.extract

import pandas as pd
import eikon as ek

ingest.extract.refinitiv.connect()

start = "2019-01-01"
end = "2024-10-31"
banks = [b["ric"] for b in ingest.extract.swissdox.query_inputs if "gsib_europe" in b["group"]]

# ================================================================================
# data necessary for annaert2013
# ================================================================================

# Credit Default Swaps
# note: no permission for bid/ask data, no further proxies for liquidity available
input_cds = []
for bank in banks:
    input_cds.append(ingest.extract.refinitiv.ric_cds(bank))
input_cds = pd.concat(input_cds, axis=0, ignore_index=True)
df = ingest.extract.refinitiv.get_cds(input_cds, start=start, end=end)
df.to_csv(environvars.paths.path_refinitiv+"cds.csv", sep=";")

# benchmark government bonds
df = ek.get_data(
    instruments=["EU2YT=RR", "EU5YT=RR", "EU10YT=RR"],
    fields=["TR.MIDYIELD.date", "TR.MIDYIELD"],
    parameters={"SDate":start, "EDate":end, "Frq":"D"}
)
df[0].to_csv(environvars.paths.path_refinitiv+"govbonds.csv", sep=";")

# corporate bond spread
# df = ek.get_data(
#     instruments=[".MERER10", ".MERER40"],
#     fields=["TR.CLOSEPRICE.date", "TR.CLOSEPRICE"],
#     parameters={"SDate":start, "EDate":end, "Frq":"D"}
# )
# df[0].to_csv(environvars.paths.path_refinitiv+"corpbonds.csv", sep=";")

# test = ek.get_data(
#     instruments=[".MERER10", ".MERER40"],
#     fields=["TR.YIELDTOMATURITY.date", "TR.YIELDTOMATURITY"],
#     parameters={"SDate":start, "EDate":end, "Frq":"D"}
# )

df = ek.get_data(
    instruments=[".MERER10", ".MERER40"],
    fields=["TR.YIELD.date", "TR.YIELD"],
    parameters={"SDate":start, "EDate":end, "Frq":"D"}
)
df[0].to_csv(environvars.paths.path_refinitiv+"corpbonds.csv", sep=";")

# stock price
df = ek.get_data(
    instruments=banks,
    fields=["TR.CLOSEPRICE.Date", "TR.CLOSEPRICE"],
    parameters={"SDate":start, "EDate":end, "Frq":"D"}
)
df[0].to_csv(environvars.paths.path_refinitiv+"stocks.csv", sep=";")

# market index
df = ek.get_data(
    instruments=[".FTEU1", ".V2TX"],
    fields=["TR.CLOSEPRICE.Date", "TR.CLOSEPRICE"],
    parameters={"SDate":start, "EDate":end, "Frq":"D"}
)
df[0].to_csv(environvars.paths.path_refinitiv+"indices.csv", sep=";")

# ================================================================================
# data necessary for cathcart2020
# ================================================================================


