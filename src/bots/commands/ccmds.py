import aiomysql
import utils

from discord import Embed
from data import data

async def cmds(args, msg, client):
    """Lists all the custom commands
    """
    async with client.db.acquire() as conn:
        cur = await conn.cursor()
        await cur.execute("SELECT name FROM CustomCommands;")
        r = await cur.fetchall()
        await msg.reply(embed = Embed.from_dict({
            "title": "Available custom commands",
            "description": "• " + "\n• ".join(map(lambda c: c[0], r)),
            "color": 0x2987ba
        }))

async def cmd(args, msg, client):
    """Displays information about a custom command

    Args:
        command (string): The command
    """
    async with client.db.acquire() as conn:
        cur = await conn.cursor(aiomysql.DictCursor)
        cmd_name = utils.get(args, 0, "")
        await cur.execute(
            "SELECT * FROM CustomCommands \
            WHERE name LIKE %s;"
        , [cmd_name])
        cmd = await cur.fetchone()
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
    async with client.db.acquire() as conn:
        cur = await conn.cursor(aiomysql.DictCursor)
        try:
            await cur.execute(
                "INSERT INTO CustomCommands \
                VALUES (%s, %s, %s, %s);",
                [name, compiler, source, msg.author.id]
            )
            await conn.commit()
            await msg.reply(":white_check_mark: | Created the command")
        except Exception as e:
            if e.args[0] == 1062:
                await msg.reply("Command **{}** already exists! Please use `> ecmd` to overwrite it!".format(name))


async def dcmd(args, msg, client):
    """Deletes a custom command

    Args:
        command (string): Command name
    """
    cmd_name = utils.get(args, 0, "")
    admin_role = client.main_guild.get_role(data["roles"]["admin"])

    async with client.db.acquire() as conn:
        cur = await conn.cursor(aiomysql.DictCursor)
        await cur.execute("SELECT * FROM CustomCommands \
            WHERE name LIKE %s;",
            [ cmd_name ]
        )
        cmd = await cur.fetchone()
        if not (cmd and (cmd["author"] == str(msg.author.id) or (admin_role in msg.author.roles))):
            return await msg.reply(":x: You are not the author of the specified command or the command doesn't exist!")
        await cur.execute("DELETE FROM CustomCommands \
            WHERE name LIKE %s;",
            [ cmd_name ]
        )
        await conn.commit()
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
    admin_role = client.main_guild.get_role(data["roles"]["admin"])
    
    async with client.db.acquire() as conn:
        cur = await conn.cursor(aiomysql.DictCursor)
        await cur.execute("SELECT * FROM CustomCommands \
            WHERE name LIKE %s;",
            [ name ]
        )
        cmd = await cur.fetchone()
        if not (cmd and (cmd["author"] == msg.author.id or (admin_role in msg.author.roles))):
            return await msg.reply(":x: You are not the author of the specified command or the command doesn't exist!")

        await cur.execute("UPDATE CustomCommands \
            SET runner=%s, source=%s \
            WHERE name LIKE %s",
            [ compiler, source, name ]
        )

        await conn.commit()
        await msg.reply(":white_check_mark: | Editted the command")
