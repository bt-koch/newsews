import credentials
import yaml
import requests

class swissdox:
    url_base = "https://swissdox.linguistik.uzh.ch/api"
    url_query = f"{url_base}/query"
    url_status = f"{url_base}/status"
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
    default_format = "TSV"
    default_max_results = 100
    default_columns = ["id", "pubtime", "medium_code", "medium_name", "rubric", "regional", "doctype",
                       "doctype_description", "language", "char_count", "dateline", "head", "subhead",
                       "article_link", "content_id", "content"]
    default_version = "1.2"

    def build_query(sources, dates_from, dates_to, languages, #content,
                    format = default_format,
                    max_results = default_max_results,
                    columns = default_columns,
                    version = default_format):

        query = swissdox.query_template
        query["query"]["sources"] = sources
        query["query"]["dates"]["from"] = dates_from
        query["query"]["dates"]["to"] = dates_to
        query["query"]["languages"] = languages
        #query["query"]["content"] = content
        query["result"]["format"] = format
        query["result"]["maxResults"] = max_results
        query["result"]["columns"] = columns
        query["result"]["version"] = version

        return(yaml.dump(query))


