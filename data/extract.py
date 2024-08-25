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
            "sources": None,
            "dates": None,
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
                       "content_id", "content"]
    default_version = "1.2"

    @staticmethod
    def build_query(sources, dates_from, dates_to, languages, content,
                    format = default_format,
                    max_results = default_max_results,
                    columns = default_columns,
                    version = default_version):

        query = swissdox.query_template
        query["query"]["sources"] = sources
        query["query"]["dates"] = [{"from": dates_from, "to": dates_to}]
        query["query"]["languages"] = languages
        query["query"]["content"] = content
        query["result"]["format"] = format
        query["result"]["maxResults"] = max_results
        query["result"]["columns"] = columns
        query["version"] = version

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
    def download_data(query_name, headers = headers):
        download_url = swissdox.get_download_url(query_name)
        request = requests.get(
            url = download_url,
            headers = headers
        )
        if request.status_code == 200:
            fp = open(environvars.paths.path_swissdox + query_name + ".tsv.xz", "wb")
            fp.write(request.content)
            fp.close()
        else:
            print(request.text)





