import asyncio
import functools
import json
import re
import math
from datetime import datetime, timedelta

import requests
import utils
from aiotfm import Packet
from data import data
from discord import Embed

from bots import translations

commands = {}

def command(discord=False, tfm=False, whisper_command=False, aliases=None, allowed_roles=None):

    def decorator(f):
        functools.wraps(f)
        commands[f.__name__] = { "f": f, "discord": discord, "tfm": tfm, "whisper_command": whisper_command, "allowed_roles": allowed_roles }

        if aliases:
            for alias in aliases:
                commands[alias] = { "f": f, "discord": discord, "tfm": tfm, "whisper_command": whisper_command, "allowed_roles": allowed_roles }
        
        def wrapper(*args, **kwargs):
            return f(*args, **kwargs)

        return wrapper
    return decorator


from .commands import ccmds

command(discord = True)(ccmds.cmds)
command(discord = True)(ccmds.cmd)
command(discord = True, allowed_roles = [ data["roles"]["admin"], data["roles"]["cmder"] ])(ccmds.ccmd)
command(discord = True, allowed_roles = [ data["roles"]["admin"], data["roles"]["cmder"] ])(ccmds.ecmd)
command(discord = True, allowed_roles = [ data["roles"]["admin"], data["roles"]["cmder"] ])(ccmds.dcmd)

from .commands import qotd as qhandler


@command(discord = True, allowed_roles = [ data["roles"]["admin"], data["roles"]["mod"] ])
async def qotd(args, msg, client):
    if len(args) > 0:
        if hasattr(qhandler, args[0]):
            await qhandler.__getattribute__(args[0])(args[1:], msg, client)

from .commands import mod

command(discord = True, allowed_roles = [ data["roles"]["admin"], data["roles"]["mod"] ])(mod.setrank)
command(discord = True, allowed_roles = [ data["roles"]["admin"], data["roles"]["mod"] ])(mod.kick)
command(discord = True, allowed_roles = [ data["roles"]["admin"], data["roles"]["mod"] ])(mod.blacklist)
command(discord = True, allowed_roles = [ data["roles"]["admin"], data["roles"]["mod"] ])(mod.whitelist)
command(discord = True, allowed_roles = [ data["roles"]["admin"], data["roles"]["mod"] ])(mod.warnings)
command(discord = True, allowed_roles = [ data["roles"]["admin"], data["roles"]["mod"] ])(mod.warn)
command(discord = True, allowed_roles = [ data["roles"]["admin"], data["roles"]["mod"] ])(mod.rwarn)
command(discord = True, allowed_roles = [ data["roles"]["admin"], data["roles"]["mod"] ])(mod.nick)

@command(discord=True)
async def ping(args, msg, client):
    await msg.reply("Pong")

@command(discord=True, allowed_roles = [ data["roles"]["admin"], data["roles"]["mod"] ] )
async def restart(args, msg, client):
    import sys
    if msg:
        await msg.reply(":hourglass_flowing_sand: | Restarting...")
    sys.exit("Restart")

@command(discord=True, allowed_roles = [data["roles"]["admin"]] )
async def room(args, msg, client):
    try:
        await client.tfm.joinRoom(" ".join(args))
        room = await client.tfm.wait_for("on_joined_room", timeout=4)
        await msg.reply(":white_check_mark: | Joined the room (name: `{}` | community: `{}`)".format(room.name, room.community))
    except Exception as e:
        await msg.reply(f":x: | {e}")

@command(discord=True, allowed_roles = [ data["roles"]["admin"], data["roles"]["event"] ])
async def setmsg(args, msg, client):
    try:
        await client.tfm.sendCP(98, Packet().writeUTF(" ".join(args)))
        await client.tfm.wait_for("on_raw_cp", lambda tc, packet: tc == 125, 2)
        await msg.reply(":white_check_mark: | Changed the message!")
    except Exception as e:
        await msg.reply(f":x: | Failed to change the message (Error: `{e}`)")

@command(tfm=True, whisper_command=True)
async def inv(args, msg, client):
    if not msg.author.username == "Finnick#7866":
        await client.recruit(msg.author.username)

@command(discord=True, aliases=["t"])
async def tc(args, msg, client):
    if len(args) == 0: return await msg.add_reaction("🤡")
    nick, _ = utils.extract_name_and_tag((utils.get_tfm_nick_format(msg.author.nick or msg.author.name) or (msg.author.nick or msg.author.name)))
    await client.tfm.sendTribeMessage(utils.normalize_msg_from_discord("[" + nick + "] " + " ".join(args), client))
    #await client.tfm.sendTribeMessage("[" + msg.author.nick + "] " + " ".join(args))

@command(discord=True, tfm=True)
async def who(args, msg, client):

    if client.client_type == "Discord": # Discord command
        tribe = await client.tfm.getTribe(False)

        fields = []
        current_rank = None
        for member in tribe.members:
            if current_rank is not member.rank.name:
                current_rank = member.rank.name
                fields.append({ "name": current_rank, "value": "", "inline": False })

            name, tag = utils.extract_name_and_tag(utils.normalize_name(member.name))

            if member.room.startswith("*") or member.room.startswith("$") or member.room.startswith("@"):
                commu, room = "xx", member.room[1:]
            else:
                commu, room = member.room[:2], member.room[3:]

            fields[-1]["value"] += "• {} {}  [*`{}`*]\n".format(
                ":united_nations:" if commu == "xx" else ":flag_{}:".format(({ "en": "gb", "ta": "lk" }).get(commu, commu)),
                f"{name}`#{tag}`",
                room
            )

        await msg.channel.send(
            embed = Embed.from_dict({
                "title": "Online members from Transformice",
                "fields": fields,
                "color": 0x2987ba,
                "footer": { "text": "{} members online".format(len(tribe.members)) },
            })
        )

@command(
    discord=True,
    tfm=True,
    whisper_command=True
)
async def verify(args, msg, client):
    if client.client_type == "Discord": # Discord command
        verified_role = client.main_guild.get_role(data["roles"]["verified"])
        admin_role = client.main_guild.get_role(data["roles"]["admin"])
        if verified_role in msg.author.roles:
            if args[0:1] == ["force"]:
                if not admin_role in msg.author.roles:
                    return await msg.reply("You are not permitted for force verification")
            else:
                return await msg.reply("You are verified already!")
        await client.send_verification_key(msg.author)
    elif client.client_type == "Transformice": # Transformice command
        if len(args) == 0:
            return await client.whisper(msg.author, "You should provide a valid verification key")
        if not client.discord.keys.get(args[0]):
            return await client.whisper(msg.author, "Your verification does not match with any keys we have!")
        
        member = client.discord.keys[args[0]]
        verified_role = client.discord.main_guild.get_role(data["roles"]["verified"])
        await member.add_roles(verified_role, reason="Successful verification")
        await member.edit(nick=utils.get_discord_nick_format(msg.author.username), reason="Successful verification")
        del client.discord.keys[args[0]]
        await client.whisper(msg.author, "You are now verified in the discord server!")
        
@command(discord=True, aliases=["p"])
async def profile(args, msg, client):

    target = None
    tribe = await client.tfm.getTribe(True)
    if len(args) == 0:
        target = tribe.get_member((utils.get_tfm_nick_format(msg.author.nick) or "").lower())
        args.append(target.name if target else (msg.author.nick or msg.author.name))
    else:
        args[0] = args[0].lower()
        if len(msg.mentions) == 1:
            target = tribe.get_member((utils.get_tfm_nick_format(msg.mentions[0].nick) or "").lower())
        else:
            target = tribe.get_member(args[0])
            if not target:
                for member in tribe.members:
                    if re.search("^{}".format(args[0]), member.name):
                        target = member                  
                        break
    
    is_tribe_member = target is not None

    if re.search(r".+?#\d+", target.name if target else args[0]):
        n = args[0]
    else:
        n = args[0] + "#0000"

    fName, disc = utils.extract_name_and_tag(utils.normalize_name(target.name if target else "{}".format(n)))
    res = requests.get(f"https://atelier801.com/profile?pr={fName}%23{disc}")
    chunk = res.text
    name = f"{fName}#{disc}"

    if res.status_code != 200 or re.search("La requête contient un ou plusieurs paramètres invalides", chunk):
        return await msg.reply("We couldn't find what you were looking for :(")

    
    a801_profile = {
        "registration": utils.search(r"Date d'inscription</span> : (.+?)</span>", chunk),
        "soulmate": utils.search(r"nom-utilisateur-scindable\">.+?>\s*(.+?)<.+?hashtag-pseudo\"> #(\d+)</span>", chunk),
        "gender": utils.search(r"Genre :.+? (\S+)\s+<br>", chunk),
        "birthday": utils.search(r"Date de naissance :</span> (.+?)</span>", chunk),
        "location": utils.search(r"Localisation :</span> (.+?)<br>", chunk),
        "tribe": utils.search(r"cadre-tribu-nom\">(.+?)</span>", chunk),
        "avatar": utils.search(r"\"(http://avatars\.atelier801\.com/\d+/[\d+_]+\.jpg)\"", chunk)
    }
    if a801_profile["avatar"]:
        a801_profile["avatar"] = re.sub(r"_\d+", "", a801_profile["avatar"])

    soulnick, soultag = a801_profile["soulmate"] or (None, None)
    tfm_profile = None
    try:
        offline = False
        await client.tfm.sendCommand(f"profile {name}")
        tfm_profile = await client.tfm.wait_for("on_profile", lambda p: p.username == name, 1)
    except asyncio.exceptions.TimeoutError:
        offline = True

    finally:
        embed = {
            "title": "{} {}".format(
                {"Masculin": ":male_sign:", "Féminin": ":female_sign:", "None": ""}[a801_profile["gender"] or "None"],
                name
            ),
            "url": f"https://atelier801.com/profile?pr={fName}%23{disc}",
            "thumbnail": {
                "url": a801_profile["avatar"] or ""
            },
            "description": """
                :{color}_circle: `{status}` {title}

                {tribe_info}

                {soulmate} {birthday} {location} :calendar: Registration date: {registration}
                {game_stats}

            """.format(
                color = "black" if offline else "green",
                status = "Offline" if offline else "Online",
                title = "" if offline else "*«`{}`»*".format(translations.get_title(tfm_profile.title, a801_profile["gender"] or "None")),
                tribe_info = ":star: Rank: {}".format(target.rank.name) if is_tribe_member else ("<:tribehouse:689470787950084154> {}".format(a801_profile["tribe"]) or ""),
                soulmate = f":revolving_hearts: Soulmate: [{soulnick}`#{soultag}`](https://atelier801.com/profile?pr={soulnick}%23{soultag})\n" if soulnick else "",
                birthday = ":birthday: Birthday: {}\n".format(a801_profile["birthday"]) if a801_profile["birthday"] else "",
                location = ":map: Location: {}\n".format(a801_profile["location"]) if a801_profile["location"] else "",
                registration = a801_profile["registration"],
                game_stats = """
                    :crossed_swords: Level: {level}
                    :sparkles: Adventure points {advPoints}

                    <:cheese:691158951563362314> Gathered cheese: {cheese}
                    <:p7:836550194380275742> Firsts: {firsts}
                    <:bootcamp:836550195683917834> Bootcamps: {bootcamps}

                """.format(
                    level = tfm_profile.level,
                    advPoints = tfm_profile.adventurePoints,
                    cheese = tfm_profile.stats.gatheredCheese,
                    firsts = tfm_profile.stats.firsts,
                    bootcamps = tfm_profile.stats.bootcamps
                ) if not offline else ""
            )
        }

        if not offline:
            pass
            #mode_stats = tfm_profile.stats.modeStats
            #print(mode_stats)
            #embed["fields"] = [
            #    { "inline": True, "name": "Racing", "value": "<:p17:836550197366226956> Rounds played: {}\n<:p17:836550197366226956> Rounds completed: {}\n<:p17:836550197366226956> Podiums: {}\n<:p17:836550197366226956> Firsts: {}".format(
            #        mode_stats[0][1],
            #        mode_stats[1][1],
            #        mode_stats[2][1],
            #        mode_stats[3][1]
            #    )},
            #    { "inline": True, "name": "Survivor", "value": "<:sorbibor:836550196518846464> Rounds played: {}\n<:sorbibor:836550196518846464> Times shaman: {}\n<:sorbibor:836550196518846464> Killed mice: {}\n<:sorbibor:836550196518846464> Survives: {}".format(
            #        mode_stats[4][1],
            #        mode_stats[5][1],
            #        mode_stats[6][1],
            #        mode_stats[7][1]
            #    )},
            #    { "inline": True, "name": "Defilante", "value": "<:defi:836550198389768193> Rounds played: {}\n<:defi:836550198389768193> Rounds completed: {}\n<:defi:836550198389768193> Gathered points: {}".format(
            #        mode_stats[8][1],
            #        mode_stats[9][1],
            #        mode_stats[10][1]
            #    )},
            #    { "inline": True, "name": "Shaman", "value": "<:cheese:691158951563362314> Shaman cheese: {}\n<:shaman:836550192387850251> Saves: {}/{}/{}".format(
            #        tfm_profile.stats.shamanCheese,
            #        tfm_profile.stats.normalModeSaves,
            #        tfm_profile.stats.hardModeSaves,
            #        tfm_profile.stats.divineModeSaves
            #    )}
            #]
        #embed["color"] = ({ 
        #    "admin": 0xEB1D51, "mod": 0xBABD2F, "sentinel": 0x2ECF73, "mapcrew": 0x2F7FCC, "module": 0x95D9D6, "funcorp": 0xF89F4B
        #}).get(roles[0] if roles else ("admin" if disc == "0001" else 0), 0x009D9D)
        await msg.reply(embed = Embed.from_dict(embed))

@command(discord=True)
async def bday(args, msg, client):
    channel = client.main_guild.get_channel(data["channels"]["bday"])
    raw_data = ""
    for msg_id in data["data"]["bday"]:
        message = await channel.fetch_message(msg_id)
        raw_data += message.content
        raw_data = re.sub("`", "", raw_data)[20:-86]
    today = datetime.now()
    yesterday = (today - timedelta(days=1)).strftime("%-d %B")
    tomorrow = (today + timedelta(days=1)).strftime("%-d %B")
    today = today.strftime("%-d %B")
    bdaysToday = re.findall("\n{} - (.+)\n".format(today), raw_data)
    bdaysYesterday = re.findall("\n{} - (.+)\n".format(yesterday), raw_data)
    bdaysTomorrow = re.findall("\n{} - (.+)\n".format(tomorrow), raw_data)
    bdayCount = len(bdaysToday) + len(bdaysYesterday) + len(bdaysTomorrow)
    if msg is None and bdayCount == 0: return
    method = msg.reply if msg else client.main_guild.get_channel(data["channels"]["staff"]).send
    await method(embed = Embed.from_dict({
        "title": "Birthdays :tada:",
        "color": 0xccdd33,
        "fields": [
            { "name": "Yesterday", "value": "No birthday" if len(bdaysYesterday) == 0 else "• {}".format("\n• ".join(bdaysYesterday)) },
            { "name": "Today", "value": "No birthday" if len(bdaysToday) == 0 else "• {}".format("\n• ".join(bdaysToday)) },
            { "name": "Tomorrow", "value": "No birthday" if len(bdaysTomorrow) == 0 else "• {}".format("\n• ".join(bdaysTomorrow)) }
        ],
        "timestamp": datetime.now().isoformat()
    }))

@command(discord=True)
async def stats(args, msg, client):
    res = json.loads(requests.get("https://cheese.formice.com/api/tribes/A%20Place%20to%20Call%20Home").text)
    position = json.loads(requests.get("https://cheese.formice.com/api/position/overall?value={}&entity=tribe".format(res["stats"]["score"]["overall"])).text)["position"]
    method = msg.reply if msg else client.main_guild.get_channel(data["channels"]["stats"]).send
    await method(content = 
    """:calendar_spiral: **Daily tribe stats `[{}]` <:tribehouse:689470787950084154> **\n> ┗ :medal: **Position:** `{}`
    > 
    > :person_running: **Rounds: **      `{}`
    > <:cheese:691158951563362314> **Cheese:**       `{}`
    > <:p7:836550194380275742> **Firsts:**          `{}`
    > <:bootcamp:836550195683917834> **Bootcamp:**  `{}`
    > 
    > <:shaman:836550192387850251> **Gathered cheese/Normal/Hard/Divine: [** `{}`/`{}`/`{}`/`{}` **]**
    """.format(
        datetime.now().strftime("%d/%m/%y"),
        position,
        res["stats"]["mouse"]["rounds"],
        res["stats"]["mouse"]["cheese"],
        res["stats"]["mouse"]["first"],
        res["stats"]["mouse"]["bootcamp"],
        res["stats"]["shaman"]["cheese"],
        res["stats"]["shaman"]["saves_normal"],
        res["stats"]["shaman"]["saves_hard"],
        res["stats"]["shaman"]["saves_divine"]
    ))
    
@command(discord=True)
async def acnh(args, msg, client):
    if len(args) < 2:
        return await msg.reply(":x: **|** Invalid format\nCorrect format: `> acnh <type> <item>`. `type` could be one of the following: \n<:rolepeppyrabbit:929048043611889684> villagers\n<:fish:960948399283249202> fish\n<:bug:961894768290443294> bugs\n<:deap_sea:961895000889770024> sea\n\n`item` is the thing you are looking for!")
    if args[0] == "villagers":
        res = requests.get(f"https://www.instafluff.tv/ACDB/Villagers/{ args[1] }.json")
        if res.status_code == 200:
            data = json.loads(res.text)
            await msg.reply(embed = Embed.from_dict({
                "title": f"Villager - { args[1] }",
                "description": "{} {} {}\n\n{}\n\n*`\"{}\"`*".format(
                    "♂️" if data["gender"] == "Male" else "♀️",
                    ":capricorn: :aquarius: :pisces: :aries: :taurus: :gemini: :cancer: :leo: :virgo: :libra: :scorpius: :sagittarius:".split(" ")[int(utils.search(r"(\d+)/(\d+)", data["birthdate"])[1]) - 1],
                    dict(zip([ "Education", "Fashion", "Fitness", "Music", "Nature", "Play"], ":books: :lipstick: :muscle: :musical_note: :leaves: :yo_yo:".split()))[data["hobby"]],
                    data["description"],
                    data["saying"],
                ),
                "fields": [
                    { "name": "Species", "value": data["species"], "inline": True },
                    { "name": "Personality", "value": data["personality"], "inline": True },
                    { "name": ":birthday: Birthday", "value": data["birthday"], "inline": True },
                    { "name": "Catchphrase", "value": data["catchPhrase"]["US-en"], "inline": True }
                ],
                "thumbnail": {
                    "url": data["icon"]
                },
                "image": {
                    "url": data["image"],
                },
                "url": f"https://animalcrossing.fandom.com/wiki/{ args[1] }",
                "color": int(data["bubbleColor"][1:], 16)
                
            }))
        else:
            await msg.reply(":x: **|** Couldn't find the villager")
    elif args[0] in ("fish", "sea", "bugs"):
        target = ("_".join(args[1:])).lower()
        print(args[0])
        print(f"https://acnhapi.com/v1/{ args[0] }/{ target }")
        res = requests.get(f"https://acnhapi.com/v1/{ args[0] }/{ target }")
        if res.status_code == 200:
            data = json.loads(res.text)
            embed = {}
            embed["title"] = "{}{} - {}".format(args[0][0].upper(), args[0][1:], " ".join(args[1:]))
            embed["url"] = f"https://animalcrossing.fandom.com/wiki/{ target }"
            embed["image"] = { "url": data["image_uri"] }
            embed["thumbnail"] = { "url": data["icon_uri"] }
            embed["description"] = "<:bells:962313051309236224> **{} bells**\n\n {}\n\n`\"{}\"`".format(data["price"], data["museum-phrase"], data["catch-phrase"])
            embed["fields"] = []
            
            seasonilty = ""
            for i in range(1, 13):
                seasonilty += ":orange_square:" if i in data["availability"]["month-array-northern"] else ":black_large_square:"
                if i % 4 == 0: seasonilty += "\n"

            embed["fields"].append({ "name": "Seasonality (Northern)", "value": seasonilty, "inline": True })
            embed["fields"].append({ "name": "Time", "value": "All day" if data["availability"]["isAllDay"] else data["availability"]["time"], "inline": True })

            if args[0] == "fish":
                embed["fields"].append({ "name": "Shadow", "value": data["shadow"], "inline": False })
                embed["fields"].append({ "name": "Price (CJ)", "value": "<:bells:962313051309236224> {}".format(data["price-cj"]), "inline": True })
                embed["color"] = 0x81f1f7
            elif args[0] == "sea":
                embed["fields"].append({ "name": "Shadow", "value": data["shadow"], "inline": False })
                embed["fields"].append({ "name": "Speed", "value": data["speed"], "inline": True })
                embed["color"] = 0x9dffb0

            elif args[0] == "bugs":
                embed["fields"].append({ "name": "Price (Flick)", "value": "<:bells:962313051309236224> {}".format(data["price-flick"]), "inline": False })
                embed["color"] = 0xc48d3f
            
            await msg.reply(embed = Embed.from_dict(embed))
        else:
            await msg.reply(":x: **|** Couldn't find the critter")


        


@command(discord=True)
async def botw(args, msg, client):
    
    if len(args) == 0:
        return await msg.reply(":x: **|** Please provide an entry")
    res = requests.get("https://botw-compendium.herokuapp.com/api/v2/entry/{}".format("_".join(args)))
    if not res.status_code == 200:
        return await msg.reply(":x: **|** Couldn't find the entry in the Compendium (`{}`)".format("_".join(args)))
    data = json.loads(res.text)["data"]

    embed = {
        "title": "{} - {}".format(data["category"], data["name"]).capitalize(),
        "description": data["description"],
        "fields": [
            { "name": ":pushpin: Common locations", "value": "• " + "\n• ".join(data["common_locations"]) if data["common_locations"] else "N/A", "inline": True },
        ],
        "image": {
            "url": data["image"]
        },
        "footer": {
            "text": "{} • ID: {}".format(data["name"], data["id"])
        }

    }
    
    if data["category"] == "monsters":
        embed["fields"].append({ "name": ":cut_of_meat: Drops", "value": ("• " + "\n• ".join(data["drops"])) if data["drops"] else "N/A", "inline": True})
        embed["color"] = 0xed611d

    elif data["category"] == "materials" or data["category"] == "creatures":
        embed["title"] += " {} :heart: x {}".format({ 
            "extra hearts": ":yellow_heart: :arrow_double_up:",
            "extra stamina": ":battery: :arrow_double_up:",
            "stamina recovery": ":battery:",
            "cold resistance": ":snowflake:",
            "shock resistance": ":zap:",
            "speed up": ":athletic_shoe:",
            "stealth up": ":ninja:",
            "attack up": ":crossed_swords:",
            "defense up": ":shield:"
        }.get(data["cooking_effect"], ""), data["hearts_recovered"])
        embed["color"] = 0x9bc133
    
    elif data["category"] == "equipment":
        embed["title"] += " {} x {}".format(":crossed_swords:" if data["attack"] > data["defense"] else ":shield:", max(data["attack"], data["defense"]))
        embed["color"] = 0x4eaac0

    elif data["category"] == "treasure":
        embed["fields"].append({ "name": ":gem: Drops", "value": ("• " + "\n• ".join(data["drops"])) if data["drops"] else "N/A", "inline": True })
        embed["color"] = 0x262820
        
    else:
        return await msg.reply(":x: **|** The category of the entry is not supported yet :smiling_face_with_tear: ")
    await msg.reply(embed = Embed.from_dict(embed))


@command(discord=True)
async def test(args, msg, client):
    from discord_components import DiscordComponents, Button, Select, SelectOption

    await msg.reply(content="Hello", components=[Button(label="hello")])
    interaction = await client.wait_for("button_click")
    print(interaction)
    #await interaction.
    await interaction.respond(content="ur mom")

