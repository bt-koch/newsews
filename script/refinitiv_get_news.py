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

days = pd.date_range(start="2023-08-15", end="2024-11-13")

banks = [b["ric"] for b in ingest.extract.swissdox.query_inputs if "gsib_europe" in b["group"]]

df = []

for bank in banks:
    print("\nGet news articles for "+bank)
    if bank == "CSGN.S^F23":
        continue
    for day in days.strftime('%Y-%m-%d'):
        print(f"\rDay {day}", end='', flush=True)
        try:
            articles = ek.get_news_headlines(
                query="R:"+bank+" and Language:LEN",
                date_from=day+"T00:00:00",
                date_to=day+"T23:59:59",
                count=100
            )
            for i in range(0, articles.shape[0]):
                temp = pd.DataFrame([{
                    "bank": bank,
                    "date": articles.iloc[i]["versionCreated"],
                    "story": ek.get_news_story(articles.iloc[i]["storyId"]),
                    "story_id": articles.iloc[i]["storyId"]
                }])
                df.append(temp)
        except:
            print(" -> exception for "+day)
            temp = pd.DataFrame([{
                "bank": bank,
                "date": day,
                "story": None,
                "story_id": None
            }])
            df.append(temp)
    df = pd.concat(df, axis=0, ignore_index=True)
    df.to_csv(environvars.paths.path_refinitiv+"dataset_newsarticles_"+bank+".csv", sep=";")
    df = []

print("\nScript finished!")
