import credentials

class swissdox:
    url_base = "https://swissdox.linguistik.uzh.ch/api"
    url_api = f"{url_base}/query"
    headers = {"X-API-Key": credentials.swissdox.key, "X-API-Secret": credentials.swissdox.secret}
    query_template = {
        "query": {
            "sources": None,
            "dates": {"from": None, "to": None},
            "languages": None,
            "content": None
        },
        "result": {
            "format": None,
            "maxResults": None,
            "columns": None
        },
        "version": "None"
    }

