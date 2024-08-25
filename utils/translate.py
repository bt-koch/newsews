import deepl
import config.credentials as credentials

def translate_text(text, target_language, source_language = None):
    translator = deepl.Translator(credentials.deepl.key)
    translation = translator.translate_text(text, target_lang = target_language, source_lang = source_language)
    return translation.text
