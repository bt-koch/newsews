import pandas as pd
import config.environvars as environvars
import re
import nltk
import spacy

class swissdox:
    
    def read_tsv(query_name):
        df = pd.read_csv(environvars.paths.path_swissdox + query_name + ".tsv.xz", sep = "\t")
        return df
    

class preprocess:

    def remove_tags(text):
        pattern = r"</?tx>|</?p>|</?zt>|<au>.*?</au>|</?a[^>]*>|<ld>.*?</ld>|</?lg>"
        return re.sub(pattern, " ", text)

    def tokenize(text):
        return nltk.word_tokenize(text)
    
    def remove_stopwords(tokens, language):
        stop_words = set(nltk.corpus.stopwords.words(language))
        print("I probably want to extend stop word list later on")
        return [word for word in tokens if word.lower() not in stop_words]
    
    def remove_punctuation(tokens):
        punctuation = set('!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~«»')
        return [word for word in tokens if word.lower() not in punctuation]
    
    def lemmatize(tokens):
        nlp = spacy.load("de_core_news_md")
        doc = nlp(" ".join(tokens))
        return [token.lemma_ for token in doc]