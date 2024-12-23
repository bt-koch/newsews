import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import config.environvars as environvars
import ingest.extract
from models.apply_models import calculate_sentiment
from models.llm import select_device

import time
import pandas as pd
from pandarallel import pandarallel
pandarallel.initialize(progress_bar=True)

num_articles = 1000

print("Prepare data...")
df = pd.read_csv(environvars.paths.path_swissdox+"swissdox.csv")
df = df.sample(num_articles, random_state=2024)

query_input = ingest.extract.swissdox.query_inputs
device = select_device()

# Method 1: Utilize parallel computation
print("\nUtilize parallel computation...")
temp = df.copy()
start = time.time()
temp["sentiment_score"] = temp.parallel_apply(lambda x: calculate_sentiment(
        x,
        query_input=query_input,
        device=-1,
        model="finbert_german_sentiment"
    ), axis=1)
end = time.time()
runtime_pandarallel = end-start
temp.to_csv(environvars.paths.path_preprocessed+"runtime_comparison/pandarallel.csv", sep=";", index=False)
del temp

# Method 2:  leverage the GPU on MacOS device
print("\n\nUtilize MPS/GPU...")
from tqdm import tqdm
tqdm.pandas()
temp = df.copy()
start = time.time()
df["sentiment_score"] = df.progress_apply(lambda x: calculate_sentiment(
        x,
        query_input=query_input,
        device=device,
        model="finbert_german_sentiment"
    ), axis=1)
end = time.time()
runtime_mps = end-start
temp.to_csv(environvars.paths.path_preprocessed+"runtime_comparison/mps.csv", sep=";", index=False)
del temp

# save results
print("\nSave results...")
results = pd.DataFrame({
    "method": ["pandarallel", "mps"],
    "required_runtime": [runtime_pandarallel, runtime_mps],
    "num_articles": num_articles
})

results.to_csv(environvars.paths.path_preprocessed+"runtime_comparison/results.csv", sep=";", index=False)
