import random
import re

from hashlib import sha256

def normalize_name(name):
    return name[0].upper() + name[1:]

def extract_name_and_tag(name):
    return name[:-5], name[-4:]

def generate_random_key(id):
    return sha256("{}{}{}".format(random.randint(100, 500), id, random.randint(900, 1000)).encode("utf-8")).hexdigest()

subscripts = re.split("", "₀₁₂₃₄₅₆₇₈₉")[1:-1]

def get_discord_nick_format(name):
    name, tag = extract_name_and_tag(normalize_name(name))
    return name + " # " + subscripts[int(tag[0])] + subscripts[int(tag[1])] + subscripts[int(tag[2])] + subscripts[int(tag[3])] # sorry but yes

def get_tfm_nick_format(nick):
    name, tag = nick[:-7], nick[-4:]
    try:
        return "{}#{}{}{}{}".format(name, subscripts.index(tag[0]), subscripts.index(tag[1]), subscripts.index(tag[2]), subscripts.index(tag[3])) # sorry again)
    except Exception:
        return None

get = lambda l, x, d: l[x:x+1] and l[x] or d

def search(pattern, str):
    res = re.search(pattern, str)
    groups = res.groups() if res else None
    if groups and len(groups) == 1:
        return groups[0]
    return groups

print(get_discord_nick_format("King_seniru#5890"))