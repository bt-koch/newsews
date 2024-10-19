import data.transform
import re

class topic_modelling:

    def topic_keywords(article, query_input):

        try:

            # filter relevant content from article
            pattern = [i for i in query_input if i["query_name"] == article["query_bank"]][0]
            pattern = re.compile(pattern["regex"])
            text = article["content"]
            text = text.split("</p>")
            text = [data.transform.preprocess.remove_tags(item) for item in text]
            text = [item.lower() for item in text]
            text = [item for item in text if bool(re.search(pattern, item))]

            # preprocess relevant text from article
            text = " ".join(text)
            text = data.transform.preprocess.remove_tags(text)
            text = data.transform.preprocess.tokenize(text)
            text = data.transform.preprocess.remove_stopwords(text, language="german")
            text = data.transform.preprocess.remove_punctuation(text)
            text = data.transform.preprocess.lemmatize(text)
            text = [t[1].lower() for t in text if t[2] in ["NN", "NE"]]

            if len(text) == 0:
                return "not about "+article["query_bank"]
            
            # check if match with keywords
            pattern = ["wirtschaft", "finan(z|ce)", "bank", "m(?:a|ae|[ä])rkt", "market", "b(?:[ö]|oe)rse",
                    "aktie", "aktionär", "zins", "obligation", "hypothek", "company", "unternehmen", "invest",
                    "inflation", "rezession", "derivate", "devisen", "franken", "dollar", "euro", "(k|c)redit",
                    "debit", "immobilie", "index", "\\bs(p|m)i(-[a-z]*)?\\b", "(ö|oe)konom", "yield", "swap",
                    "coupon", "emissionspreis", "spread", "basispunkt", "konkurs", "default"]
            pattern = "|".join(pattern)
            pattern = re.compile(pattern, re.IGNORECASE)

            # TODO: maybe instead of checking for any, count matches and check if certain ratio exceeded?
            #       -> since there might still be "unwanted" matches now
            #       -> but what would be good ratio? or good decision rule?
            if any(pattern.search(item) for item in text):
                return "wirtschaft"
            else:
                return "drop"
        except:
            print(article["query_bank"])