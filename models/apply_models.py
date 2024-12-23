from ingest.transform import preprocess
from models.llm import finbert_german_sentiment
from models.llm import finbert_english_sentiment
from re import compile, search
from numpy import nanmean, isnan

def calculate_sentiment(article, query_input, device, model, silent=True):
    if not silent:
        print("Calculate sentiment for article "+article["content_id"])
    pattern = [i for i in query_input if i["query_name"] == article["query_bank"]][0]
    pattern = compile(pattern["regex"])

    text = article["content"]
    if type(text) == float:
        return float("nan")
    text = text.split("</p>")
    text = [preprocess.text.remove_tags(item) for item in text]
    text = [item for item in text if bool(search(pattern, item.lower()))]

    text = [sentence.strip() for t in text for sentence in t.split('.') if len(sentence) > 0]
    text = [t for t in text if len(t) > 0]

    if len(text) == 0:
        return float("nan")

    if (model == "finbert_german_sentiment"):
        model_initialise = finbert_german_sentiment.model_initialise()
        result = [finbert_german_sentiment.finbert_german_sentiment(
            item,
            tokenizer=model_initialise[0],
            model=model_initialise[1],
            device=device
        ) for item in text]
        # with warnings.catch_warnings():
        #     warnings.simplefilter("ignore", category=RuntimeWarning)
        result = nanmean(result)
    elif (model == "finbert_english_sentiment"):
        model_initialise = finbert_english_sentiment.model_initialise()
        result = [finbert_english_sentiment.finbert_english_sentiment(
            item,
            tokenizer=model_initialise[0],
            model=model_initialise[1],
            device=device
        ) for item in text]
        result = nanmean(result)
    else:
        print("No model called "+model+" available. Return None.")
        result = None
    
    return(result)