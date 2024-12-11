import config.credentials as credentials
import config.environvars as environvars
import yaml
import requests
import eikon as ek
import pandas as pd
from pynytimes import NYTAPI
import datetime

class swissdox:
    url_base = "https://swissdox.linguistik.uzh.ch/api"
    url_query = f"{url_base}/query"
    url_status = f"{url_base}/status"
    headers = {"X-API-Key": credentials.swissdox.key, "X-API-Secret": credentials.swissdox.secret}
    query_template = {
        "query": {
            "dates": None
        },
        "result": {
            "format": None,
            "maxResults": None,
            "columns": None
        },
        "version": "None"
    }
    default_format = "TSV"
    default_max_results = 10**7
    default_date_from = "2022-01-01"
    default_date_to = "2023-06-30"
    default_columns = ["id", "pubtime", "medium_code", "medium_name", "rubric", "regional", "doctype",
                       "doctype_description", "language", "char_count", "dateline", "head", "subhead",
                       "content_id", "content"]
    default_version = "1.2"

    @staticmethod
    def build_query(dates_from, dates_to,
                    languages = None, content = None, sources = None,
                    format = default_format,
                    max_results = default_max_results,
                    columns = default_columns,
                    version = default_version):

        query = swissdox.query_template
        query["query"]["dates"] = [{"from": dates_from, "to": dates_to}]
        query["result"]["format"] = format
        query["result"]["maxResults"] = max_results
        query["result"]["columns"] = columns
        query["version"] = version

        if sources is not None:
            query["query"]["sources"] = sources
        if content is not None:
            query["query"]["content"] = content
        if languages is not None:
            query["query"]["languages"] = languages

        return yaml.dump(query)

    @staticmethod
    def submit_query(query, run_as_test, name, comment = None, expiration_date = None,
                     url_query = url_query, headers = headers):
        data = {
            "query": query,
            "test": "1" if run_as_test else "0",
            "name": name,
            "comment": comment,
            "expirationDate": expiration_date
        }

        request = requests.post(
            url = url_query,
            headers = headers,
            data = data
        )

        return request.json()
    
    @staticmethod
    def get_queries(url_status = url_status, headers = headers):
        request = requests.get(
            url = url_status,
            headers=headers
        )
        return request.json()
    
    def get_download_url(query_name):
        queries = swissdox.get_queries()
        for query in queries:
            if query["name"] == query_name:
                download_url = query["downloadUrl"]
                if download_url is None:
                    print("Download URL expired. Submit query again.")
                return download_url
        print("No query with query name " + query_name + " available.")
        return None
    
    @staticmethod
    def get_data(query_name, headers = headers):
        download_url = swissdox.get_download_url(query_name)
        request = requests.get(
            url = download_url,
            headers = headers
        )
        if request.status_code == 200:
            fp = open(environvars.paths.path_swissdox + query_name + ".tsv.xz", "wb")
            fp.write(request.content)
            fp.close()
            print("data for " + query_name + " successfully extracted")
        else:
            print(request.text)

    def prepare_and_submit_query(ric, test = False):

        query_input = [i for i in swissdox.query_inputs if i.get("ric") == ric]

        if query_input[0]["query_name"] in [x["name"] for x in swissdox.get_queries()]:
            print("Query for " + ric + " already exists.")
            return None

        query = swissdox.build_query(
            dates_from = query_input[0]["from"],
            dates_to = query_input[0]["to"],
            content = query_input[0]["content"]
        )

        validate_query = swissdox.submit_query(
            query = query,
            run_as_test = True,
            name = query_input[0]["query_name"],
            expiration_date = "2025-01-03"
        )

        if validate_query["result"] == "failed":
            print("Invalid query, see message:")
            print(validate_query)
            return query
        
        if test:
            return
        
        swissdox.submit_query(
            query = query,
            run_as_test = False,
            name = query_input[0]["query_name"],
            expiration_date = "2025-01-03"
        )

        return validate_query
        
        # todo: check if query is ready to download, else sys sleep?
        # swissdox.get_data(query_input[0]["query_name"])



    query_inputs = [
        {
            "query_name": "credit_suisse",
            "content": {
                "AND": [
                    {"OR": ["Credit Suisse", "CS", "CSGN", "CSGN:SWX", "SWX:CSGN"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "credit\\s+suisse|\\bcs(-[a-z]+)?\\b|\\b(swx:)?csgn(:swx)?\\b",
            "ric": "CSGN.S^F23",
            "group": ["swissbank", "gsib_europe"]
        },
        {
            "query_name": "ubs",
            "content": {
                "AND": [
                    {"OR": ["UBS", "UBSG", "UBSG:SWX", "SWX:UBSG"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "\\bubs(-[a-z]+)?\\b|\\b(swx:)?ubsg(:swx)?\\b",
            "ric": "UBSG.S",
            "group": ["swissbank", "gsib_europe"]
        },
        # {
        #     "query_name": "arundel",
        #     "content": {
        #         "AND": [
        #             {"OR": ["Arundel", "ARON", "SWX:ARON", "ARON:SWX"]}
        #         ]
        #     },
        #     "from": default_date_from,
        #     "to": default_date_to,
        #     "ric": "ARONL.S"
        # },
        {
            "query_name": "baloise",
            "content": {
                "AND": [
                    {"OR": ["B*loise", "BALN", "BALN:SWX", "SWX:BALN"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "b(a|â)loise|\\b(swx:)?baln(:swx)?\\b",
            "ric": "BALN.S",
            "group": "swissbank"
        },
        {
            "query_name": "kantonalbank_genf",
            "content": {
                "AND": [
                    {"OR": ["*anque *antonale de Gen*ve", "BCGE", "BCGE:SWX", "SWX:BCGE", "Kantonalbank Genf", "*enfer* Kantonalbank"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "banque\\s+cantonale\\s+\\s+de\\s+genev(e|è)ve|\\b(swx:)?bcge(-[a-z]+|:swx)?\\b|kantonalbank\\s+genf|genfer[a-z]*\\s+kantonalbank",
            "ric": "BCGE.S",
            "group": "swissbank"
        },
        {
            "query_name": "kantonalbank_jura",
            "content": {
                "AND": [
                    {"OR": ["*anque *antonale du Jura", "BCJ", "BCJ:SWX", "SWX:BCJ", "Kantonalbank Jura", "*urassische* Kantonalbank"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "banque\\s+cantobale\\s+du\\s+jura|\\b(swx:)?bcj(-[a-z]+|:swx)?\\b|kantonalbank\\s+jura|jurassische[a-z]*\\s+kantonalbank",
            "ric": "BCJ.S",
            "group": "swissbank"
        },
        {
            "query_name": "kantonalbank_wallis",
            "content": {
                "AND": [
                    {"OR": ["*anque *antonale du Valais", "WKBN", "WKBN:SWX", "SWX:WKBN", "Kantonalbank Wallis", "*alliser* Kantonalbank"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "banque\\s+cantonale\\s+du\\s+valais|\\b(swx:)?wkbn(-[a-z]+|:swx)?\\b|kantonalbank\\s+wallis|walliser[a-z]*\\s+kantonalbank",
            "ric": "WKB.S",
            "group": "swissbank"
        },
        {
            "query_name": "kantonalbank_waadt",
            "content": {
                "AND": [
                    {"OR": ["*anque *antonale du Vaudoise", "BCVN", "BCVN:SWX", "SWX:BCVN", "Kantonalbank Waadt", "*aadtländer* Kantonalbank"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "banque\\s+cantonale\\s+du\\s+vaudoise|\\b(swx:)?bcvn(-[a-z]+|:swx)?\\b|kantonalbank\\s+waadt|waadtl(ä|ae)nder[a-z]*\\s+kantonalbank",
            "ric": "BCVN.S",
            "group": "swissbank"
        },
        {
            "query_name": "kantonalbank_baselland",
            "content": {
                "AND": [
                    {"OR": ["*aselland* Kantonalbank", "BLKB", "BLKB:SWX", "SWX:BLKB", "*anque *antonale de *le-*ampagne"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "baselland[a-z]*\\s+kantonalbank|\\b(swx:)?blkb(-[a-z]+|:swx)?\\b|banque\\s+cantonale\\s+de\\s+b(â|a)le(-|\\s)campagne",
            "ric": "BLKB.S",
            "group": "swissbank"
        },
        {
            "query_name": "kantonalbank_baselstadt",
            "content": {
                "AND": [
                    {"OR": ["*asler* Kantonalbank", "BKB", "BSKP", "BSKP:SWX", "SWX:BSKP", "*anque *antonale de *le"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "basler[a-z]*\\s+kantonalbank|\\bbkb(-[a-z])?\\b|\\b(swx:)?bskp(:swx)?\\b|banque\\s+cantonale\\s+de\\s+b(â|a)le",
            "ric": "BSKP.S",
            "group": "swissbank"
        },
        {
            "query_name": "kantonalbank_bern",
            "content": {
                "AND": [
                    {"OR": ["*erner* Kantonalbank", "BEKB", "BCBE", "BEKN", "BEKN:SWX", "SWX:BEKN", "*anque *antonale *ernoise"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "berner[a-z]*\\s+kantonalbank|\\bbekb(-[a-z]*)?\\b|\\bbcbe(-[a-z]*)?\\b|\\b(swx:)?bekn(-[a-z]*|:swx)?\\b|banque\\s+cantonale\\s+bernoise",
            "ric": "BEKN.S",
            "group": "swissbank"
        },
        {
            "query_name": "cembra_money_bank",
            "content": {
                "AND": [
                    {"OR": ["Cembra Money Bank", "Cembra", "CMBN", "CMBN:SWX", "SWX:CMBN"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "cembra\\s+money\\s+bank|\\bcembra(-[a-z]*)\\b|\\b(swx:)?cmbn(-[a-z]*|:swx)?\\b",
            "ric": "CMBN.S",
            "group": "swissbank"
        },
        {
            "query_name": "efg_international",
            "content": {
                "AND": [
                    {"OR": ["EFG International", "EFGN", "EFGN:SWX", "SWX:EFGN", "EFG"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "\\befg\\s+international|\\befg(-[a-z]*)\\b|\\b(swx:)?efgn(-[a-z]*|:swx)?\\b",
            "ric": "EFGN.S",
            "group": "swissbank"
        },
        {
            "query_name": "kantonalbank_glarus",
            "content": {
                "AND": [
                    {"OR": ["*larner* Kantonalbank", "GLKB", "GLKBN", "GLKBN:SWX", "SWX:GLKBN", "*anque *antonale de *laris"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "glarner[a-z]*\\s+kantonalbank|\\bglkb(-[a-z]*)?\\b|\\b(swx:)?glkbn(-[a-z]*|:swx)?\\b|banque\\s+cantonale\\s+de\\s+glaris",
            "ric": "GLKBN.S",
            "group": "swissbank"
        },
        {
            "query_name": "kantonalbank_graubuenden",
            "content": {
                "AND": [
                    {"OR": ["*raub*ndner* Kantonalbank", "GKB", "GRKP", "GRKP:SWX", "SWX:GRKP", "*anque *antonale des *risons"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "graub(ü|ue)ndner[a-z]*\\s+kantonalbank|\\bgkb(-[a-z]*)\\b|\\b(swx:)?grkp(-[a-z]*|:swx)?|banque\\s+cantonale\\s+des\\s+grisons",
            "ric": "GRKP.S",
            "group": "swissbank"
        },
        {
            "query_name": "hypothekarbank_lenzburg",
            "content": {
                "AND": [
                    {"OR": ["*ypothekarbank Lenzburg", "HBLN", "HBLN:SWX", "SWX:HBLN"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "hypothekarbank\\s+lenzburg|\\b(swx:)?hbln(-[a-z]*|:swx)?\\b",
            "ric": "HBLN.S",
            "group": "swissbank"
        },
        {
            "query_name": "julius_baer",
            "content": {
                "AND": [
                    {"OR": ["Julius B*r", "BAER", "BAER:SWX", "SWX:BAER"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "julius\\s+b(ä|ae)r|\\b(swx:)?baer(-[a-z]*|:swx)?\\b",
            "ric": "BAER.S",
            "group": "swissbank"
        },
        {
            "query_name": "liechtensteinische_landesbank",
            "content": {
                "AND": [
                    {"OR": ["*iechtensteinisch* Landesbank", "LLBN", "LLBN:SWX", "SWX:LLBN", "*anque centrale du *iechtenstein"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "liechtensteinisch[a-z]*\\s+landesbank|\\b(swx:)?llbn(-[a-z]*|:swx)?\\b|banque\\s+centrale\\s+du\\s+liechtenstein",
            "ric": "LLBN.S",
            "group": "swissbank"
        },
        {
            "query_name": "kantonalbank_luzern",
            "content": {
                "AND": [
                    {"OR": ["*uzerner* Kantonalbank", "LUKB", "LUKN", "LUKN:SWX", "SWX:LUKN", "*anque *antonale de *ucerne"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "luzerner[a-z]*\\s+kantonalbank|\\blukb(-[a-z]*)?\\b|\\b(swx:)?lukn(-[a-z]*|:swx)?|banque\\s+cantonale\\s+de\\s+lucerne",
            "ric": "LUKN.S",
            "group": "swissbank"
        },
        {
            "query_name": "kantonalbank_stgallen",
            "content": {
                "AND": [
                    {"OR": ["S* Galler* Kantonalbank", "SGKB", "SGKN", "SGKN:SWX", "SWX:SGKN", "*anque *antonale de *aint* *all"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "(st\\.|sankt)\\s+galler[a-z]*\\s+kantonalbank|\\bsgkb(-[a-z]*)?\\b|\\b(swx:)?sgkn(-[a-z]*|:swx)?\\b|banque\\s+cantonale\\s+de\\s+saint(-|\\s+)gall",
            "ric": "SGKN.S",
            "group": "swissbank"
        },
        {
            "query_name": "swissquote",
            "content": {
                "AND": [
                    {"OR": ["*wissquote", "SQN", "SQN:SWX", "SWX:SQN"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "swissquote|\\b(swx:)?sqn(-[a-z]*|:swx)?\\b",
            "ric": "SQN.S",
            "group": "swissbank"
        },
        {
            "query_name": "kantonalbank_thurgau",
            "content": {
                "AND": [
                    {"OR": ["*hurgauer* Kantonalbank", "TKB", "TKBP", "TKBP:SWX", "SWX:TKBP", "*anque *antonale de *hurgovie"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "thurgauer[a-z]*\\s+kantonalbank|\\btkb(-[a-z]*)?\\b|\\b(swx:)?tkbp(-[a-z]*|:swx)?\\b|banque\\s+cantonale\\s+de\\s+thurgovie",
            "ric": "TKBP.S",
            "group": "swissbank"
        },
        {
            "query_name": "valartis",
            "content": {
                "AND": [
                    {"OR": ["Valartis", "VLRT", "VLRT:SWX", "SWX:VLRT"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "valartis|\\b(swx:)?vlrt(-[a-z]*|:swx)?\\b",
            "ric": "VLRT.S",
            "group": "swissbank"
        },
        {
            "query_name": "valiant",
            "content": {
                "AND": [
                    {"OR": ["Valiant", "VATN", "VATN:SWX", "SWX:VATN"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "valiant|\\b(swx:)?vatn(-[a-z]*|:swx)?\\b",
            "ric": "VATN.S",
            "group": "swissbank"
        },
        {
            "query_name": "vontobel",
            "content": {
                "AND": [
                    {"OR": ["Vontobel", "VONN", "VONN:SWX", "SWX:VONN"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "vontobel|\\b(swx:)?vonn(-[a-z]*|:swx)?\\b",
            "ric": "VONN.S",
            "group": "swissbank"
        },
        {
            "query_name": "vp_bank",
            "content": {
                "AND": [
                    {"OR": ["VP Bank", "VPBN", "VPBN:SWX", "SWX:VPBN"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "regex": "\\bvp\\s+bank|\\b(swx:)?vpbn(-[a-z]*|:swx)?\\b",
            "ric": "VPBN.S",
            "group": "swissbank"
        },
        {
            "query_name": "kantonalbank_zug",
            "content": {
                "AND": [
                    {"OR": ["*uger* Kantonalbank", "ZugerKB", "ZUGER", "ZUGER:SWX", "SWX:ZUGER", "*anque *antonale de *oug"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            # here stock ticker might match a lot of unwanted substrings...
            "regex": "zuger[a-z]*\\s+kantonalbank|zugerkb(-[a-z]*)?|\\b(swx:)?zuger(-[a-z]*|:swx)?\\b|banque\\s+cantonale\\s+de\\s+zoug",
            "ric": "ZUGER.S",
            "group": "swissbank"
        },
        {
            "query_name": "hsbc",
            "regex": "hsbc|hsba",
            "ric": "HSBA.L",
            "group": "gsib_europe"
        },
        {
            "query_name": "barclays",
            "regex": "barclays|\\bbarc\\b",
            "ric": "BARC.L",
            "group": "gsib_europe"
        },
        {
            "query_name": "bnp_paribas",
            "regex": "\\bbnp\\b",
            "ric": "BNPP.PA",
            "group": "gsib_europe"
        },
        {
            "query_name": "deutsche_bank",
            "regex": "deutsche\W+bank|\\bdb(k)?\\b",
            "ric": "DBKGn.DE",
            "group": "gsib_europe"
        },
        {
            "query_name": "groupe_credit_agricole",
            "regex": "cr[eé]dit\\W+agricole|\\bla\\W+banque\\W+verte\\b|\\baca\\b",
            "ric": "CAGR.PA",
            "group": "gsib_europe"
        },
        {
            "query_name": "ing",
            "regex": "\\bing(a)?\\b",
            "ric": "INGA.AS",
            "group": "gsib_europe"
        },
        {
            "query_name": "santander",
            "regex": "santander|\\bsan\\b",
            "ric": "SAN.MC",
            "group": "gsib_europe"
        },
        {
            "query_name": "societe_generale",
            "regex": "societ[eé]\\W+g[eé]n[eé]rale|\\bgle\\b",
            "ric": "SOGN.PA",
            "group": "gsib_europe"
        },
        {
            "query_name": "standard_chartered",
            "regex": "standard\\W+chartered|\\bstan\\b",
            "ric": "STAN.L",
            "group": "gsib_europe"
        }
    ]

class refinitiv:

    def connect():
        ek.set_app_key(credentials.refinitiv.key)

    def ric_cds(ric_equity):
        ric_cds, error = ek.get_data(ric_equity, "TR.CDSPrimaryCDSRic")
        ric_cds = ric_cds.rename(columns={"Instrument": "ric_equity", "Primary CDS RIC": "ric_cds"})
        return ric_cds

    def get_cds(ric_cds, start="2012-01-01", end="2024-10-31"):
        data = []
        for cds in ric_cds.itertuples():
            try:
                temp = ek.get_timeseries(cds.ric_cds,
                                        fields="*",
                                        start_date=start,
                                        end_date=end)
                temp.index.name = "date"
                temp.reset_index(inplace=True)
                temp = temp[["date", "CLOSE"]]
                temp = temp.rename(columns={"CLOSE": "value"})
                temp.loc[:, "ric_cds"] = cds.ric_cds
                temp.loc[:, "ric_equity"] = cds.ric_equity
                data.append(temp)
            except:
                temp = pd.DataFrame({
                    "date": [start],
                    "value": [pd.NA],
                    "ric_cds": [cds.ric_cds],
                    "ric_equity": [cds.ric_equity]
                })
                data.append(temp)
        return pd.concat(data)
    
    def get_price_to_book(ric_equity, number_of_days = -365*4):
        df, err = ek.get_data(ric_equity,
                            ["TR.H.PriceToBVPerShare.date", "TR.H.PriceToBVPerShare"],
                            {"SDate": 0, "EDate": number_of_days, "FRQ": "D"})
        df = pd.DataFrame(df)
        df.columns = ["ric_equity", "date", "value"]
        df = df.replace("NaN", pd.NA)
        return df

    def get_stockprice(ric_equity, start="2021-01-01", end="2024-10-31"):
        df = ek.get_data(ric_equity,
                        ["TR.CLOSEPRICE.Date", "TR.CLOSEPRICE"],
                        {"SDate": start, "EDate": end})
        df = pd.DataFrame(df[0])
        df.columns = ["ric_equity", "date", "value"]
        df = df.replace("NaN", pd.NA)
        return df

class newyorktimes:

    def connect():
        return NYTAPI(credentials.newyorktimes.key, parse_dates=True)
    
    def get_data(year, month):
        con = newyorktimes.connect()
        return con.archive_metadata(date = datetime.datetime(year, month, 1))
    

