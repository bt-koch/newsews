import data.transform
import models.llm

import re
import numpy as np

def calculate_sentiment(article, query_input, device, model):
    print("Calculate sentiment for article "+article["content_id"])
    pattern = [i for i in query_input if i["query_name"] == article["query_bank"]][0]
    pattern = re.compile(pattern["regex"])

    text = article["content"]
    text = text.split("</p>")
    text = [data.transform.preprocess.remove_tags(item) for item in text]
    text = [item.lower() for item in text]
    text = [item for item in text if bool(re.search(pattern, item))]

    if (model == "finbert_german_sentiment"):
        model_initialise = models.llm.finbert_german_sentiment.model_initialise()
        result = [models.llm.finbert_german_sentiment.finbert_german_sentiment(
            item,
            tokenizer=model_initialise[0],
            model=model_initialise[1],
            device=device
        ) for item in text]
        result = np.nanmean(result)
    else:
        print("No model called "+model+" available. Return None.")
        result = None
    
    return(result)