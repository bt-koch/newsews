import pandas as pd
import config.environvars as environvars
import re
import nltk
from HanTa import HanoverTagger as ht

class swissdox:
    
    def read_tsv(query_name):
        df = pd.read_csv(environvars.paths.path_swissdox + query_name + ".tsv.xz", sep = "\t")
        return df
    
    # def remove_duplicates(tsv):
    #     # todo: remove duplicates: according to content_id?
    #     # or is duplication sign of more reach/relevancy? they appeared in different sources...
    #     return

class preprocess:

    class text:

        def remove_tags(text):
            pattern = r"</?tx>|</?p>|</?zt>|<au>.*?</au>|</?a[^>]*>|</?ld>|</?lg>|<nt>.*?</nt>|</?span>|<?/strong>|<?/h\\d+>"
            return re.sub(pattern, " ", text)

        def tokenize(text):
            return nltk.word_tokenize(text)
        
        def remove_stopwords(tokens, language):
            stop_words = set(nltk.corpus.stopwords.words(language))
            # print("I probably want to extend stop word list later on")
            return [word for word in tokens if word.lower() not in stop_words]
        
        def remove_punctuation(tokens):
            punctuation = set('!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~«»–')
            return [word for word in tokens if word.lower() not in punctuation]
        
        def lemmatize(tokens):
            tagger = ht.HanoverTagger('morphmodel_ger.pgz')
            return tagger.tag_sent(tokens)
        
    class sentiment:

        def aggregate(dataframe):
            dataframe["date"] = pd.to_datetime(dataframe["date"], utc=True).dt.normalize()
            df = dataframe.groupby(["date", "bank"]).mean(numeric_only=True).reset_index()
            df = df.sort_values(by=["bank", "date"]).reset_index()
            return df
        
        def add_moving_average(dataframe, window_length=5):
            df = dataframe.sort_values(by=["bank", "date"]).reset_index()
            df["moving_average"] = df["sentiment_score"].rolling(window=window_length, min_periods=window_length).mean()
            return df

