# newsews

The goal of this project is an implementation of an Early Warning Indicator based on News sentiment.
The sentiment of news articles is classified using a Bidirectional Encoder Representations from Transformers (BERT)
model and the predictive performance is assessed by evaluating the predictive power of the indicator on common risk
proxies using datae for Swiss and European banks for 2022 until 2024. The results show, dependent
on the sample and risk proxy, that the news sentiment indicator has predictive power.
Some further modifications in the construction of the indicator and in the application for
forecasting are necessary to implement it in the context of an early warning system.

For futher details, please see the [final report](to do).

## About

This project was created as my Master Thesis.

## Setup

To set up your environment, create following files

1. `config/credentials.py`
```py
class swissdox:
    key = "<your-swissdox-key>"
    secret = "<your-swissdox-secret>"

class deepl:
    key = "<your-deepl-key">

class newyorktimes:
    key = "<your-nyt-key>
```

2. `config/environvars.py`
```py
class paths:
    path_data = "<your-base-path-to-store-data>"
    path_swissdox = f"{path_data}/swissdox/"
    path_huggingface = f"{path_data}/huggingface/"
    path_preprocessed = f"{path_data}/preprocessed_data/"
    path_meta = f"{path_data}/meta/"
    path_refinitiv = f"{path_data}/refinitiv/"
    path_ecb = f"{path_data}/ecb/"
    path_six = f"{path_data}/six/"
    path_snb = f"{path_data}/snb/"

    path_repo = "<your-path-where-you-cloned-this-repo-to>"
    path_results = f"{path_repo}/data/"
```

3. `config/environvars.R`
```r
path_data <- "<your-base-path-to-store-data>"
path_repo <- "<your-path-where-you-cloned-this-repo-to>"

paths <- list(
  path_data = path_data,
  path_swissdox = file.path(path_data, "swissdox"),
  path_huggingface = file.path(path_data, "huggingface"),
  path_preprocessed = file.path(path_data, "preprocessed_data"),
  path_meta = file.path(path_data, "meta"),
  path_refinitiv = file.path(path_data, "refinitiv"),
  path_ecb = file.path(path_data, "ecb"),
  path_six = file.path(path_data, "six"),
  path_snb = file.path(path_data, "snb"),

  path_repo = path_repo,
  path_results = file.path(path_repo, "data")
)

rm(path_data, path_repo)
```

## Instructions for Replication

Please see `script/README.md` for the steps necessary to replicate this study.
