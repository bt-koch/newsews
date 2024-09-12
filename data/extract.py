import config.credentials as credentials
import config.environvars as environvars
import yaml
import requests

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
    default_max_results = 100
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
            print("data for " + ric + " successfully extracted")
        else:
            print(request.text)

    def prepare_and_submit_query(ric):

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
        
        swissdox.submit_query(
            query = query,
            run_as_test = False,
            name = query_input[0]["query_name"],
            expiration_date = "2025-01-03"
        )
        
        # todo: check if query is ready to download, else sys sleep?
        # swissdox.get_data(query_input[0]["query_name"])



    query_inputs = [
        {
            "query_name": "test_query",
            "content": {
                "AND": [
                    {"OR": ["COVID", "Corona"]},
                    {"NOT": "China"},
                    {"NOT": "chin*"}
                ]
            },
            "from": "2022-12-01",
            "to": "2022-12-15",
            "languages": ["de", "fr"],
            "sources": ["ZWA", "ZWAS"]
        },
        {
            "query_name": "credit_suisse",
            "content": {
                "AND": [
                    {"OR": ["Credit Suisse", "CS", "CSGN", "CSGN:SWX", "SWX:CSGN"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "ric": "CSGN.S^F23"
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
            "ric": "UBSG.S"
        },
        {
            "query_name": "arundel",
            "content": {
                "AND": [
                    {"OR": ["Arundel", "ARON", "SWX:ARON", "ARON:SWX"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "ric": "ARONL.S"
        },
        {
            "query_name": "baloise",
            "content": {
                "AND": [
                    {"OR": ["B*loise", "BALN", "BALN:SWX", "SWX:BALN"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "ric": "BALN.S"
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
            "ric": "BCGE.S"
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
            "ric": "BCJ.S"
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
            "ric": "WKB.S"
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
            "ric": "BCVN.S"
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
            "ric": "BLKB.S"
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
            "ric": "BSKP.S"
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
            "ric": "BEKN.S"
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
            "ric": "CMBN.S"
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
            "ric": "EFGN.S"
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
            "ric": "GLKBN.S"
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
            "ric": "GRKP.S"
        },
        {
            "query_name": "hypothekarbank_lenzburg",
            "content": {
                "AND": [
                    {"OR": ["*ypothekarbank Lenzburg", "HBLN", "HBLN:SWX", "SWX:HBLN", "*anque *antonale des *risons"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "ric": "HBLN.S"
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
            "ric": "BAER.S"
        },
        {
            "query_name": "lichtensteinische_landesbank",
            "content": {
                "AND": [
                    {"OR": ["*ichtensteinisch* Landesbank", "LLBN", "LLBN:SWX", "SWX:LLBN", "*anque centrale du *iechtenstein"]}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "ric": "LLBN.S"
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
            "ric": "LUKN.S"
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
            "ric": "SGKN.S"
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
            "ric": "SQN.S"
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
            "ric": "TKBP.S"
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
            "ric": "VLRT.S"
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
            "ric": "VATN.S"
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
            "ric": "VONN.S"
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
            "ric": "VPBN.S"
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
            "ric": "ZUGER.S"
        }
    ]


