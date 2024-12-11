# newsews

Implementation of an Early Warnings System based on News sentiment



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