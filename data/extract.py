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
            "dates": None,
            "languages": None
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

    def extract(ric):

        query_input = [i for i in swissdox.query_inputs if i.get("ric") == ric]

        query = swissdox.build_query(
            dates_from = query_input["from"],
            dates_to = query_input["to"],
            content = query_input["content"] 
        )

        swissdox.submit_query(
            query = query,
            run_as_test = True,
            name = query_input["name"]
        )

        swissdox.get_data(query_input["name"])



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
                    {"Credit Suisse"}
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
                    {"ubs"}
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
                    {"arundel"}
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
                    {"Baloise"}
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
                    {"Banque Cantonale de Geneve"}
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
                    {"Banque Cantonale du Jura"}
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
                    {"Banque Cantonale du Valais"}
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
                    {"Banque Cantonale Vaudoise"}
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
                    {"Basellandschaftliche Kantonalbank"}
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
                    {"Basler Kantonalbank"}
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
                    {"Berner Kantonalbank"}
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
                    {"Cembra Money Bank"}
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
                    {"EFG International"}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "ric": "EFGN.S"
        },
        {
            "query_name": "efg_international",
            "content": {
                "AND": [
                    {"EFG International"}
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
                    {"Glarner Kantonalbank"}
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
                    {"Graubuendner Kantonalbank"}
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
                    {"Hypothekarbank Lenzburg"}
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
                    {"Julius Baer"}
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
                    {"Liechtensteinische Landesbank"}
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
                    {"Luzerner Kantonalbank"}
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
                    {"St Galler Kantonalbank"}
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
                    {"Swissquote"}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "ric": "SQN.S"
        },
        {
            "query_name": "swissquote",
            "content": {
                "AND": [
                    {"Swissquote"}
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
                    {"Thurgauer Kantonalbank"}
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
                    {"Valartis"}
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
                    {"Valiant"}
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
                    {"Vontobel"}
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
                    {"VP Bank"}
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
                    {"Zuger Kantonalbank"}
                ]
            },
            "from": default_date_from,
            "to": default_date_to,
            "ric": "ZUGER.S"
        }
    ]


