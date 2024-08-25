import pandas as pd
import config.environvars as environvars

class swissdox:
    
    def read_tsv(query_name):
        df = pd.read_csv(environvars.paths.path_swissdox + query_name + ".tsv.xz", sep = "\t")
        return df