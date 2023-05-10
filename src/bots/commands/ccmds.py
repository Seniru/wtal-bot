import utils

from discord import Embed
from data import data

async def cmds(args, msg, client):
    """Lists all the custom commands
    """
    await msg.reply(embed = Embed.from_dict({
        "title": "Available custom commands",
        "description": "• " + "\n• ".join(client.ccmds.keys()),
        "color": 0x2987ba
    }))

async def cmd(args, msg, client):
    """Displays information about a custom command

    Args:
        command (string): The command
    """
    cmd_name = utils.get(args, 0, "")
    cmd = client.ccmds.get(cmd_name)
    if not cmd:
        return await msg.reply(":x: | Cannot find that command")
    await msg.reply(embed = Embed.from_dict({
        "title": "Custom command info",
        "fields": [
            { "name": "Author", "value": "<@!{}>".format(cmd["author"]) },
            { "name": "Source", "value": "[{source}]({source})".format(source = cmd["source"])}
        ],
        "color": 0x2987ba
    }))

async def ccmd(args, msg, client):
    """Creates a new custom command

    Args:
        name (string): Command name
        compiler (string): Language used to run the program
        source (string): Link to the code
    """
    if len(args) < 3:
        return await msg.reply(":x: Failed to create the command. Please supply all the arguments\nFormat: `> ccmd <name> <compiler> <source>`")
    name, compiler, source = args[0], args[1], args[2]
    if len(name) > 10:
        return await msg.reply(":x: Command name should be less than or equal to 10 characters")
    if client.ccmds.get(name):
        return await msg.reply("Command **{}** already exists! Please use `> ecmd` to overwrite it!".format(name))

    client.ccmds[name] = { "runner": compiler, "source": source, "author": str(msg.author.id) } # stringified id for backward compatibility
    await client.update_ccmds()
    await msg.reply(":white_check_mark: | Created the command")


async def dcmd(args, msg, client):
    """Deletes a custom command

    Args:
        command (string): Command name
    """
    cmd_name = utils.get(args, 0, "")
    cmd = client.ccmds.get(cmd_name)
    admin_role = client.main_guild.get_role(data["roles"]["admin"])
    if not (cmd and (cmd["author"] == str(msg.author.id) or (admin_role in msg.author.roles))):
        return await msg.reply(":x: You are not the author of the specified command or the command doesn't exist!")
    client.ccmds.pop(cmd_name)
    await client.update_ccmds()
    await msg.reply(":white_check_mark: | Deleted the command")

async def ecmd(args, msg, client):
    """Edits a custom command

    Args:
        name (string): Command name
        compiler (string): Language used to run the program
        source (string): Link to the code
    """
    if len(args) < 3:
        return await msg.reply(":x: Failed to edit the command. Please supply all the arguments\nFormat: `> ecmd <name> <compiler> <source>`")
    name, compiler, source = args[0], args[1], args[2]
    cmd = client.ccmds.get(name)

    admin_role = client.main_guild.get_role(data["roles"]["admin"])
    if not (cmd and (cmd["author"] == str(msg.author.id) or (admin_role in msg.author.roles))):
        return await msg.reply(":x: You are not the author of the specified command or the command doesn't exist!")
    

    client.ccmds[name] = { "runner": compiler, "source": source, "author": str(msg.author.id) } # stringified id for backward compatibility
    await client.update_ccmds()
    await msg.reply(":white_check_mark: | Editted the command")