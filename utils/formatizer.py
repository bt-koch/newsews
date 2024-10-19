def print_article(article, content_length=1000):

    meta = "\033[4m"+article["medium_name"]+", "+article["pubtime"][:9]+" ("+article["doctype_description"]+")\033[0m\n\n"

    head = "\033[1m"+article["head"]+"\033[0m"
    if article["subhead"] == article["subhead"]:
        subhead = "\n\033[3m"+article["subhead"]+"\033[0m\n"
    else:
        subhead = "\n"

    if content_length == -1:
        content = "\n"+article["content"]+"\n"
    else:
        content = "\n"+article["content"][:content_length]+"...\n"

    print(meta+head+subhead+content)