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
```

2. `config/environvars.py`
```py
class paths:
    path_data = "<your-base-path-to-store-data>"
    path_swissdox = f"{path_data}/swissdox/"
    path_huggingface = f"{path_data}/huggingface/"
    path_preprocessed = f"{path_data}/preprocessed_data/"
```