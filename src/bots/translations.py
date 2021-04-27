import requests
import zlib
import re

import utils

translation_string = zlib.decompress(requests.get("http://transformice.com/langues/tfz_en").content).decode("utf-8")

def get_translation(key):
	return utils.get(re.findall(r"-\n{}=(.+?)\n-".format(key), translation_string), 0, "")

def get_title(title_id, gender=None):
	title = get_translation(f"T_{title_id}")
	
	if re.search(r"\(.+\|.+\)", title):
		male, female = re.match(r"\((.+?)\|(.+?)\)", title).groups()
		print(male, female)
		title = re.sub(r"\(.+\)", female if gender == "Féminin" else male, title)

	return title
