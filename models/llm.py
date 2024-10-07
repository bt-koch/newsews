import ollama

def define_topic(text):
    instruction = """
    I will provide you with the content of a media article.
    Can you classify the topic of the article?
    Answer with a single keyword from the following selection: Economy, Sports, Weather, Culture, War in Ucraine
    In your response, please provide the keyword and only the keyword, no further text is necessary.
    The text might be in german, english or french.
    Here the article:
    """
    response = ollama.chat(model="llama3.1", messages=[
        {
            "role": "user",
            "content": instruction+"\n"+text
        }
    ])
    return(response["message"]["content"])


