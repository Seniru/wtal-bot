import re
import utils

from discord import Embed

async def blacklist(args, msg, client):
    if len(args) == 0:
        return await msg.reply(embed = Embed.from_dict({
            "title": ":skull: Blacklist",
            "description": "• " + "\n• ".join(client.mod_data["blacklist"])
        }))
    target = args[0]
    client.mod_data["blacklist"][target] = True
    # todo: Kick them for the tribe
    await client.update_mod_data()
    await msg.reply(":skull: | Blacklisted {}!".format(target))
    await client.tfm.sendTribeMessage("{} has been blacklisted! Please do not invite them.".format(args[0]))
    await kick([target], None, client)

async def whitelist(args, msg, client):
    if len(args) != 0 or client.mod_data["blacklist"].get(args[0]):
        del client.mod_data["blacklist"][args[0]]
        await client.update_mod_data()
        return await msg.reply(":angel: | Whitelisted {}".format(args[0]))
    await msg.reply(":x: | `\"{}\"` is not in the blacklist".format(args[0]))

async def warnings(args, msg, client):
    if client.client_type == "Discord":
        if len(args) != 0 and (warns := client.mod_data["warnings"].get(args[0])):
            return await msg.reply(embed = Embed.from_dict({
                "title": "Warnings of {}".format(args[0]),
                "description": "• " + "\n• ".join(warns),
                "color": 0x2987ba,
                "footer": {
                    "text": "Total warnings: {}".format(len(warns))
                }
            }))
        await msg.reply(":angel: | No warnings for {}".format(args[0]))

async def kick(args, msg, client):

    if len(args) < 1:
        return await msg.reply(":x: | Invalid syntax (`> kick [target]`)")

    from aiotfm import Packet

    name = args[0]
    tribe = await client.tfm.getTribe()
    if tribe.get_member(name.lower()):
        await client.tfm.sendCP(104, Packet().writeUTF(name))
        if msg: return await msg.reply(":skull: | Kicked {}!".format(name))
    if msg: await msg.reply(":grimacing: | That person is not even in the tribe, what do you think??")

async def setrank(args, msg, client):

    if len(args) < 2:
        return await msg.reply(":x: | Invalid syntax (`> setrank [target] [rank]`)")

    from aiotfm import Packet

    name, rank = args[0], " ".join(args[1:])
    tribe = await client.tfm.getTribe()
    if not tribe.get_member(name.lower()):
        return await msg.reply(":x: | Couldn't find the member `{}`".format(name))
    for r in tribe.ranks:
        if r.name == rank:
            await client.tfm.sendCP(112, Packet().writeUTF(name).write8(r.id))
            return await msg.reply(":white_check_mark: | Changed the rank of {} to {}".format(name, rank))
    return await msg.reply(":x: Couldn't find the specified role (role: {})".format(rank))

async def nick(args, msg, client):

    if len(args) < 2:
        return await msg.reply(":x: | Invalid syntax (`> nick [@member|id] [nick]`)")

    id = re.match(r"(<@!)?(\d+)>?", args[0])
    id = int(id[2]) if id else None
    if not id:
        return await msg.reply(":x: | Invalid syntax (`> nick [@member|id] [nick]`)")

    member = client.main_guild.get_member(id)
    if not member:
        return await msg.reply(":x: | Couldn't find that member.")

    newnick = utils.get_discord_nick_format(args[1])
    if not newnick:
        return await msg.reply(":x: | The nickname format is not supported")

    try:
        await member.edit(nick=newnick)
        await msg.add_reaction("✅")
    except Exception as e:
        await msg.reply(":x: | {}".format(e))
