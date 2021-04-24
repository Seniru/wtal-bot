import functools
import utils

from data import data
from discord import Embed

commands = {}

def command(discord=False, tfm=False, whisper_command=False, aliases=None):

    def decorator(f):
        functools.wraps(f)
        commands[f.__name__] = { "f": f, "discord": discord, "tfm": tfm, "whisper_command": whisper_command }

        if aliases:
            for alias in aliases:
                commands[alias] = { "f": f, "discord": discord, "tfm": tfm }
        
        def wrapper(*args, **kwargs):
            return f(*args, **kwargs)

        return wrapper
    return decorator


@command(discord=True)
async def ping(args, msg, client):
    await msg.reply("Pong")

@command(discord=True, aliases=["t"])
async def tc(args, msg, client):
    await client.tfm.sendTribeMessage("[" + msg.author.nick + "] " + " ".join(args))

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

            fields[-1]["value"] += "• :{}: {}  [*`{}`*]\n".format(
                ["transgender_symbol", "female_sign", "male_sign"][member.gender],
                f"{name}`#{tag}`",
                member.room.replace("*", "\*")
            )

        await msg.channel.send(
            embed = Embed.from_dict({
                "title": "Online members from Transformice",
                "fields": fields,
                "color": 0x2987ba,
                "footer": { "text": "{} members online".format(len(tribe.members)) },
            })
        )

@command(discord=True, tfm=True, whisper_command=True)
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
        
        print(client.discord.keys)
        member = client.discord.keys[args[0]]
        verified_role = client.discord.main_guild.get_role(data["roles"]["verified"])
        await member.add_roles(verified_role, reason="Successful verification")
        await member.edit(nick=utils.get_discord_nick_format(msg.author.username), reason="Successful verification")
        del client.discord.keys[args[0]]
        await client.whisper(msg.author, "You are now verified in the discord server!")
        
        