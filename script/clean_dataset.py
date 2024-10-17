import sys
import os
if os.path.basename(os.getcwd()) == "script":
    os.chdir("../")
sys.path.append(os.getcwd())

import data.extract
import models.llm
import models.apply_models
import config.environvars as environvars

import pandas as pd
import numpy as np
# import pickle
from tqdm import tqdm
import re
# import gensim

print("Prepare data...")
df = pd.read_csv(environvars.paths.path_swissdox+"swissdox.csv")
df = df[df["language"] == "de"]
query_input = data.extract.swissdox.query_inputs

# # bsp 1 ---------------------------------------------------------------------------------

# article = df.iloc[5555]

# pattern = [i for i in query_input if i["query_name"] == article["query_bank"]][0]
# pattern = re.compile(pattern["regex"])

# text = article["content"]
# text = text.split("</p>")
# text = [data.transform.preprocess.remove_tags(item) for item in text]
# text = [item.lower() for item in text]
# text = [item for item in text if bool(re.search(pattern, item))]

# # bsp 2 ---------------------------------------------------------------------------------

# article = df.iloc[11111]

# pattern = [i for i in query_input if i["query_name"] == article["query_bank"]][0]
# pattern = re.compile(pattern["regex"])

# text = article["content"]
# text = text.split("</p>")
# text = [data.transform.preprocess.remove_tags(item) for item in text]
# text = [item.lower() for item in text]
# text = [item for item in text if bool(re.search(pattern, item))]

# text = " ".join(text)
# text = data.transform.preprocess.remove_tags(text)
# text = data.transform.preprocess.tokenize(text)
# text = data.transform.preprocess.remove_stopwords(text, language="german")
# text = data.transform.preprocess.remove_punctuation(text)
# text = data.transform.preprocess.lemmatize(text)
# text = [t[1] for t in text if t[2] in ["NN", "NE"]]
# print(type(text))

# dictionary = gensim.corpora.Dictionary([text])
# corpus = [dictionary.doc2bow(text)]
# num_topics = 2
# lda_model = gensim.models.ldamodel.LdaModel(corpus, num_topics=num_topics, id2word=dictionary)

# # Get topic names for all topics
# topic_names = {}
# num_top_words = 10

# for topic_id in range(num_topics):
#     top_words = lda_model.show_topic(topic_id, num_top_words)
#     topic_name = " ".join([word for word, _ in top_words])
#     topic_names[topic_id] = topic_name

# # Display topic names
# for topic_id, name in topic_names.items():
#     print(f"Topic {topic_id}: {name}")

# # Get document topic distribution
# for i, doc in enumerate(corpus):
#     topic_distribution = lda_model.get_document_topics(doc)
#     print(f"\nDocument {i + 1} Topic Distribution: {topic_distribution}")


###########################

df["rubric_cleaned"] = df["rubric"].astype(str)
df["rubric_cleaned"] = df["rubric_cleaned"].str.lower()

df.loc[df["rubric_cleaned"].str.startswith("wirtschaft"), "rubric_cleaned"] = "wirtschaft"
df.loc[df["rubric_cleaned"].str.startswith("markets"), "rubric_cleaned"] = "markets"
df.loc[df["rubric_cleaned"].str.startswith("finanz"), "rubric_cleaned"] = "finanz"
df.loc[df["rubric_cleaned"].str.startswith("invest"), "rubric_cleaned"] = "invest"
df.loc[df["rubric_cleaned"].str.startswith("company"), "rubric_cleaned"] = "company"
df.loc[df["rubric_cleaned"].str.startswith("anlagen"), "rubric_cleaned"] = "anlagen"
df.loc[df["rubric_cleaned"].str.startswith("geld"), "rubric_cleaned"] = "geld"
df.loc[df["rubric_cleaned"].str.startswith("unternehmen"), "rubric_cleaned"] = "unternehmen"

df.loc[df["rubric_cleaned"].str.startswith("news"), "rubric_cleaned"] = "news"
df.loc[df["rubric_cleaned"].str.startswith("meinung"), "rubric_cleaned"] = "meinung"
df.loc[df["rubric_cleaned"].str.startswith("schweiz"), "rubric_cleaned"] = "schweiz"
df.loc[df["rubric_cleaned"].str.startswith("politik"), "rubric_cleaned"] = "politik"
df.loc[df["rubric_cleaned"].str.startswith("municipality"), "rubric_cleaned"] = "municipality"
df.loc[df["rubric_cleaned"].str.startswith("sport"), "rubric_cleaned"] = "sport"
df.loc[df["rubric_cleaned"].str.startswith("leben"), "rubric_cleaned"] = "leben"
df.loc[df["rubric_cleaned"].str.startswith("community"), "rubric_cleaned"] = "community"


keywords_wirtschaft = ["wirtschaft", "finanz", "bank", "geld", "m(?:a|ae|[ä])rkt", "market", "b(?:[ö]|oe)rse", "aktie", "zins", "obligation", "hypothek", "company", "unternehmen", "invest",
                       "inflation", "derivate", "devisen", "franken", "dollar", "immobilie", "euro", "credit", "\\bcs(-[a-z]*)?\\b", "\\bubs(-[a-z]*)?\\b", "snb", "jordan"]
pattern = "|".join(keywords_wirtschaft)
regex = re.compile(pattern, re.IGNORECASE)
df["rubric_cleaned"] = df["rubric_cleaned"].apply(lambda text: "wirtschaft" if regex.search(text) else text)

keywords_ukraine = ["ukraine", "russland", "putin"]
pattern = "|".join(keywords_ukraine)
regex = re.compile(pattern, re.IGNORECASE)
df["rubric_cleaned"] = df["rubric_cleaned"].apply(lambda text: "ukrainekrieg" if regex.search(text) else text)

keywords_sport = ["sport", "fussball", "ski", "tennis", "federer", "djokovic"]
pattern = "|".join(keywords_sport)
regex = re.compile(pattern, re.IGNORECASE)
df["rubric_cleaned"] = df["rubric_cleaned"].apply(lambda text: "sport" if regex.search(text) else text)

keywords_energie = ["energie"]
pattern = "|".join(keywords_energie)
regex = re.compile(pattern, re.IGNORECASE)
df["rubric_cleaned"] = df["rubric_cleaned"].apply(lambda text: "energie" if regex.search(text) else text)

rubric = df["rubric_cleaned"].value_counts().reset_index()
rubric.head(n = 15)

df[df["rubric_cleaned"] == "ukrainekrieg"].iloc[0]["content"]

# should i filter articles only based on condition?

article = df.iloc[12345]
def topic_keywords(article, num_topics=2, num_top_words=20):

    try:

        # filter relevant content from article
        pattern = [i for i in query_input if i["query_name"] == article["query_bank"]][0]
        pattern = re.compile(pattern["regex"])
        text = article["content"]
        text = text.split("</p>")
        text = [data.transform.preprocess.remove_tags(item) for item in text]
        text = [item.lower() for item in text]
        text = [item for item in text if bool(re.search(pattern, item))]

        # preprocess relevant content from article
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
        pattern = ["wirtschaft", "finan(z|ce)", "bank", "geld", "m(?:a|ae|[ä])rkt", "market", "b(?:[ö]|oe)rse",
                "aktie", "aktionär", "zins", "obligation", "hypothek", "company", "unternehmen", "invest", "inflation",
                "derivate", "devisen", "franken", "dollar", "immobilie", "euro", "(k|c)redit", "\\bcs(-[a-z]*)?\\b",
                "\\bubs(-[a-z]*)?\\b", "\\bsnb(-[a-z]*)?\\b", "index", "\\bsmi(-[a-z]*)?\\b", "(ö|oe)konom",
                "rezession", "yield", "swap", "coupon", "emissionspreis", "spread", "basispunkt", "venture",
                "kunde", "business"]
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

#####################################################################
# SUGGESTED APPROACH                                                #
# (I)  keep all articles with assigned rubric related (obviously)   #
#      to wirtschaft (wirtschaft, finanz, company, ...) always      #
# (II) for all other articles, apply topic_keywords()               #
#####################################################################

df.loc[:, "rubric_test"] = df["rubric_cleaned"].apply(lambda x: "wirtschaft" if x == "wirtschaft" else "to test")

# df_test = df.sample(n=1000)

# from tqdm import tqdm
# tqdm.pandas()

# df_test["rubric_test2"] = df_test.progress_apply(lambda x: topic_keywords(x), axis=1)
# df_test.to_csv(environvars.paths.path_preprocessed+"topic_filter_test.csv", sep=";", index=False)

df_test = pd.read_csv(environvars.paths.path_preprocessed+"topic_filter_test.csv", sep=";")
df_test = df_test[["content", "rubric_test", "rubric_test2", "query_bank"]]

article=df_test.iloc[13] # ok
article=df_test.iloc[20] # ok?

# rubric = df["rubric_test"].value_counts().reset_index()
# rubric



