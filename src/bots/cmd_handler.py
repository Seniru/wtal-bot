import asyncio
import functools
import json
import re
from datetime import datetime

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


@command(discord = True, allowed_roles = [ data["roles"]["admin"] ])
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
    admin_role = client.main_guild.get_role(data["roles"]["admin"])
    import sys
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
    await client.recruit(msg.author.username)

@command(discord=True, aliases=["t"])
async def tc(args, msg, client):
    nick, tag = utils.extract_name_and_tag((utils.get_tfm_nick_format(msg.author.nick or msg.author.name) or (msg.author.nick or msg.author.name)))
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
            mode_stats = tfm_profile.stats.modeStats
            embed["fields"] = [
                { "inline": True, "name": "Racing", "value": "<:p17:836550197366226956> Rounds played: {}\n<:p17:836550197366226956> Rounds completed: {}\n<:p17:836550197366226956> Podiums: {}\n<:p17:836550197366226956> Firsts: {}".format(
                    mode_stats[0][1],
                    mode_stats[1][1],
                    mode_stats[2][1],
                    mode_stats[3][1]
                )},
                { "inline": True, "name": "Survivor", "value": "<:sorbibor:836550196518846464> Rounds played: {}\n<:sorbibor:836550196518846464> Times shaman: {}\n<:sorbibor:836550196518846464> Killed mice: {}\n<:sorbibor:836550196518846464> Survives: {}".format(
                    mode_stats[4][1],
                    mode_stats[5][1],
                    mode_stats[6][1],
                    mode_stats[7][1]
                )},
                { "inline": True, "name": "Defilante", "value": "<:defi:836550198389768193> Rounds played: {}\n<:defi:836550198389768193> Rounds completed: {}\n<:defi:836550198389768193> Gathered points: {}".format(
                    mode_stats[8][1],
                    mode_stats[9][1],
                    mode_stats[10][1]
                )},
                { "inline": True, "name": "Shaman", "value": "<:cheese:691158951563362314> Shaman cheese: {}\n<:shaman:836550192387850251> Saves: {}/{}/{}".format(
                    tfm_profile.stats.shamanCheese,
                    tfm_profile.stats.normalModeSaves,
                    tfm_profile.stats.hardModeSaves,
                    tfm_profile.stats.divineModeSaves
                )}
            ]
        roles = json.loads(requests.get(f"https://cheese.formice.com/api/players/{fName}-{disc}").text)["tfm_roles"]
        embed["color"] = ({ 
            "admin": 0xEB1D51, "mod": 0xBABD2F, "sentinel": 0x2ECF73, "mapcrew": 0x2F7FCC, "module": 0x95D9D6, "funcorp": 0xF89F4B
        }).get(roles[0] if roles else ("admin" if disc == "0001" else 0), 0x009D9D)
        await msg.reply(embed = Embed.from_dict(embed))

@command(discord=True)
async def bday(args, msg, client):
    channel = client.main_guild.get_channel(data["channels"]["bday"])
    raw_data = ""
    for msg_id in data["data"]["bday"]:
        message = await channel.fetch_message(msg_id)
        raw_data += message.content
    raw_data = re.sub("`", "", raw_data)[20:-86]
    today = datetime.now().strftime("%-d %B")
    bdays = re.findall("{} - (.+)\n".format(today), raw_data)
    if msg is None and len(args) == 0: return
    method = msg.reply if msg else client.main_guild.get_channel(data["channels"]["staff"]).send
    await method(embed = Embed.from_dict({
        "title": "Today's birthdays :tada:",
        "color": 0xccdd33,
        "description": "No birthdays today ;c" if len(bdays) == 0 else "• {}".format("\n• ".join(bdays)),
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
async def test(args, msg, client):
    from discord_components import DiscordComponents, Button, Select, SelectOption

    await msg.reply(content="Hello", components=[Button(label="hello")])
    interaction = await client.wait_for("button_click")
    print(interaction)
    #await interaction.
    await interaction.respond(content="ur mom")


