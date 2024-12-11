# Step by Step Guide for Replication

Follow this step-by-step guide to replicate the results of this studies. Note that the scripts were not build bearing an
optimal workflow for replication in mind which is why some steps could be optimised resp. organised in a better way.

## Step 1: Download Data

Unfortunately, since data is confidential, used dataset cannot be shared here.
Hence, if you want to replicate this study, you need access to both the swissdox and the eikon data API.

### Retrieve Data from Swissdox

1. run `swissdox_submit.py` to submit queries defined in `ingest/extract.py` in `swissdox` class

2. run `swissdox_download.py` to download queries submitted in step 1.

### Retrieve Data from Eikon Data API

1. run `refinitiv_get_data.py` to get all data used in analysis except news articles.

2. run `refinitiv_get_news.py` to get news data sample. Either run on subsample of banks or add sleep-timers to avoid reaching the API limit.

## Step 2: Create Datasets for Sentiment Classification

1. run `create_datasets.py` with `step=1` to generate `dataset_raw.csv` (swissdox sample) amd `dataset_refinitiv_clean.csv` (refinitiv eikon sample)

2. run `clean_dataset.py` to generate `dataset_clean.csv`

## Step 3: Sentiment Classification

1. run `calculate_sentiment.py` once for swissdox sample and once for refinitiv eikon sample

2. run `create_datasets.py` with `step=2` to create `sentiment_scores.csv` and `sentiment_scores_refinitiv.csv`


## Additional files

1. `interact_finbert_sentiment.py` and `interact_finbert_topic.py` provide an easy interface to prompt the LLMs used in this study.

2. `runtime_comparison.py` was used to decide whether parallel computing or functions optimised for metal performance shaders (MPS) is quicker (MPS does not allow for parallel computing for the interfaces used in this study)