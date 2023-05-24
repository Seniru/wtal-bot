import discord
import random
import re

from hashlib import sha256
from w3lib.html import replace_entities

def normalize_name(name):
    return name[0].upper() + name[1:]

def extract_name_and_tag(name):
    return ((name[:-5], name[-4:]) if "#" in name else (name, ""))


def generate_random_key(id):
    return sha256("{}{}{}".format(random.randint(100, 500), id, random.randint(900, 1000)).encode("utf-8")).hexdigest()


subscripts = re.split("", "₀₁₂₃₄₅₆₇₈₉")[1:-1]


def get_discord_nick_format(name):
    name, tag = extract_name_and_tag(normalize_name(name))
    return "{}{}".format(name,
        ((" # " + subscripts[int(tag[0])] + subscripts[int(tag[1])] + subscripts[int(tag[2])] + subscripts[int(tag[3])])  # sorry but yes
        if tag else ""))


def get_tfm_nick_format(nick):
    try:
        name, tag = nick[:-7], nick[-4:]
        # sorry again
        return "{}#{}{}{}{}".format(name, subscripts.index(tag[0]), subscripts.index(tag[1]), subscripts.index(tag[2]), subscripts.index(tag[3]))
    except Exception:
        return None


def get(l, x, d): return l[x:x+1] and l[x] or d


def search(pattern, str):
    res = re.search(pattern, str)
    groups = res.groups() if res else None
    if groups and len(groups) == 1:
        return groups[0]
    return groups


def normalize_msg_from_discord(msg, discord):
    def _helper(match):
        if match[1] == "@" or match[1] == "@!":  # user mentions
            if member := discord.main_guild.get_member(int(match[2])):
                return f"@{ member.nick or member.name }"
        elif match[1] == "@&":  # role mentions
            if role := discord.main_guild.get_role(int(match[2])):
                return f"@{ role.name }"
        elif match[1] == "#":  # channel mentions
            if channel := discord.main_guild.get_channel(int(match[2])):
                return f"#{ channel.name }"
    return re.sub(r"<(@|@!|@&|#)(\d+)>", _helper, msg)


def normalize_msg_from_tc(msg, discord):
    def _helper(match):
        g = match.group()
        mention_type = match[2]
        if mention_type == "@":  # user mentions / naughty mentions
            if g in ("@here", "@everyone"):
                return f"@|{ match[3] }"
            else:
                print("here" in match[3] or "everyone" in match[3])
                if "here" in match[3] or "everyone" in match[3]:
                    return f"@|{ match[3] }"
                elif member := discord.search_member(match[3], True):
                    return f"<@!{ member.id }>"
        elif mention_type == "<@&":  # role mentions (raw)
            if role := discord.main_guild.get_role(int(match[4])):
                return f"@{ role.name }"
        return g

    res = re.sub(r"(here|everyone|(@|<@&)((\d+)>|(.+?)#?(\d*)\b))", _helper, replace_entities(msg))
    return re.sub(r"@here", "@|here", re.sub(r"@everyone", "@|everyone", res))

class MockInteraction(discord.Interaction):
    def __init__(self, interaction, client):
        self.interaction = interaction
        for attr in interaction.__slots__:
            if attr.startswith("_"):
                continue
            self.__setattr__(attr, interaction.__getattribute__(attr))
        self.author = client.main_guild.get_member(interaction.user.id)
        self.member = self.author
        self.reply = interaction.response.send_message
        self.options = interaction.data.get("options", [])
        self.content = []
        if get(self.options, 0, None):
            for option in self.options if not self.options[0].get("options") else self.options[0]["options"]:
                if option.get("value") and option["value"]:
                    self.content.append(str(option["value"]))
        self.content = " ".join(self.content)
        # splitting args after joining to avoid having empty string args
        self.args = self.content.split(" ")
