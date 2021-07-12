import asyncio
import json
import os
import random
import re
from datetime import datetime, timedelta

import discord
import requests
import utils
from data import data

from bots.cmd_handler import commands

WANDBOX_ENDPOINT = "https://wandbox.org/api"

intents = discord.Intents.default()
intents.members = True

class Discord(discord.Client):

    def __init__(self):
        
        super().__init__(intents = intents)
        self.client_type = "Discord"
        self.keys = {}
        self.main_guild = None
        self.data_channel = None
        self.ccmds = {}
        
    async def on_ready(self):
        print("[INFO][DISCORD] Client is ready!")
        self.main_guild = self.get_guild(data["guild"])
        self.data_channel = self.get_guild(data["data_guild"]).get_channel(data["channels"]["data"])

        self.ccmds = await self.data_channel.fetch_message(data["data"]["ccmds"])
        self.ccmds = json.loads(self.ccmds.content[7:-3])

        self.questions = await self.data_channel.fetch_message(data["data"]["qotd"])
        self.questions = json.loads(self.questions.content[7:-3])

        self.mod_data = await self.data_channel.fetch_message(data["data"]["mod"])
        self.mod_data = json.loads(self.mod_data.content[7:-3])

        await self.start_period_tasks()


    async def on_message(self, message):
        
        # temporary code
        if (str(message.channel.id) == os.getenv("GRAVEYARD")) and (self.main_guild.get_role(data["roles"]["mafia_dead"]) in message.author.roles):
            await self.get_channel(int(os.getenv("MEDIUM_CHAT"))).send(":speaking_head: **[**<@{}>**]** `{}`".format(message.author.id, message.content))

        if message.content.startswith(">"):
            content = re.match(r"^>\s*((.|\n)*)", message.content).group(1)
            args = re.split(r"\s+", content)

            if args[0] in commands and commands[args[0]]["discord"]:
                cmd = commands[args[0]]
                if cmd["allowed_roles"]:
                    for role in cmd["allowed_roles"]:
                        if self.main_guild.get_role(role) in message.author.roles:
                            break
                    else:
                        return await message.reply(embed = discord.Embed.from_dict({
                            "title": ":x: Missing permissions",
                            "description": "You need 1 of the following roles to use this command: \n{}".format(
                                ", ".join(list(map(lambda role: "<@&{}>".format(role), cmd["allowed_roles"])))
                            ),
                            "color": 0xcc0000
                        }))

                await cmd["f"](args[1:], message, self)
            elif args[0] in self.ccmds:

                ccmd = self.ccmds[args[0]]
                code = requests.get(ccmd["source"]).content.decode("utf-8")

                stdin = content[len(args[0]) + 1:]

                res = requests.post(WANDBOX_ENDPOINT + "/compile.json",
                    data = json.dumps({ "compiler": ccmd["runner"], "code": code, "stdin": "{}\n{}".format(message.author.id, f"'{stdin}'" if stdin else "''") }),
                    headers = { "content-Type": "application/json" }
                )

                if res.status_code != 200:
                    return await message.reply(":x: | We encountered an internal error. Please try again soon!")

                res = json.loads(res.content.decode("utf-8"))

                if res["status"] != "0":
                    return await message.reply(embed = discord.Embed.from_dict({
                        "title": ":x: Error in the command",
                        "description": "Contact the author of this command to fix it\n\n**Error log**:\n ```\n{}```".format((res["program_error"] or "")),
                        "color": 0xcc0000

                    }))

                res = json.loads(res["program_output"])
                if not res:
                    return await message.reply(":x: | An error occured while running the command. Please ask the author of this command to fix the output format.")

                await message.reply(embed = discord.Embed.from_dict(res))

        elif self.user.id in message.raw_mentions:
            fact = requests.get("https://uselessfacts.jsph.pl/random.md?language=en", headers = { "User-Agent": "Seniru" }).text
            await message.reply(embed = discord.Embed.from_dict({
                "title": "{}! Wanna hear a fact? :bulb:".format(random.choice([
                    "Hi", "Hello", "Howdy", "Hola", "Yo", "Wassup", "Hola", "Namasthe", "Hi there", "Greetings",
                    "What's going on", "How's everything", "Good to see you", "Great to see you", "Nice to see you",
                    "Saluton", "What's new", "How are you feeling today","Hey there"
                ])),
                "description": fact,
                "color": 0x2987ba
            }))

    async def on_member_join(self, member):
        error = False
        try:
            await self.send_verification_key(member)
        except discord.errors.Forbidden:
            error = True
        finally:
            await self.get_channel(data["channels"]["lobby"]).send(member.mention)
            await self.get_channel(data["channels"]["lobby"]).send(embed = discord.Embed.from_dict({
                "title": "Welcome!",
                "description": "Welcome to the APTCH server (ﾉ◕ヮ◕)ﾉ*:･ﾟ✧\n" 
                    + ("We have sent you a DM to verify you in order to give you the best experience!" if not error
                    else "Please turn DMs on for server member and type > verify to get yourself verified ;3"),
                "color": 0x0066ff
            }))

    async def on_member_update(self, before, after):

        if (not before) or (not after): return

        verified_role = self.main_guild.get_role(data["roles"]["verified"])

        if not verified_role in after.roles:
            return

        normalized_nick = utils.get_tfm_nick_format(after.nick) or ""
        tribe = await self.tfm.getTribe(True)
        tribe_member = tribe.get_member(normalized_nick.lower())
        rank_role = self.main_guild.get_role(data["ranks"].get("Passer-by" if not tribe_member else tribe_member.rank.name))

        if not rank_role:
            return await self.get_channel(data["channels"]["tribe_chat"]).send("<@!522972601488900097> The tribe rank @{} does not exist in Discord!".format(tribe_member.rank.name))
        if rank_role in after.roles:
            return # No need to add if the role is already there

        rank_roles = tuple(discord.utils.get(self.main_guild.roles, name=n) for n in data["ranks"].keys())
       
        for role in rank_roles:
            if role in after.roles:
                await after.remove_roles(role)

        await after.add_roles(rank_role)

    async def send_verification_key(self, member):
        key = utils.generate_random_key(member.id)
        await member.send(f"Here's your verification key! `{key}\n`Whisper the following to Wtal#5272 (`/c Wtal#5272`) to get verified\n")
        await member.send(f"```verify  {key}```")     
        self.keys[key] = member

    async def update_ccmds(self):
        cmd_data = await self.data_channel.fetch_message(data["data"]["ccmds"])
        await cmd_data.edit(content = """
        ```json
        {}
        ```
        """.format(json.dumps(self.ccmds)))

    async def update_qotd(self):
        qotd_data = await self.data_channel.fetch_message(data["data"]["qotd"])
        await qotd_data.edit(content = """
        ```json
        {}
        ```
        """.format(json.dumps(self.questions)))

    async def update_mod_data(self):
        mod_data = await self.data_channel.fetch_message(data["data"]["mod"])
        await mod_data.edit(content = """
        ```json
        {}
        ```
        """.format(json.dumps(self.mod_data)))

    async def start_period_tasks(self):
        print("[INFO] Checking for periodic tasks...")
        # check qotd
        await commands["qotd"]["f"](["ask"], None, self)
        # other daily tasks
        last_daily_data = await self.data_channel.fetch_message(data["data"]["daily"])
        now = datetime.now()
        if now > datetime.fromtimestamp(float(last_daily_data.content)) + timedelta(days=1):
            for task in (("bday", []), ("stats", [])):
                try:
                    await commands[task[0]]["f"](task[1], None, self)
                except Exception as e:
                    await self.main_guild.get_channel(data["data"]["channels"]["admin"]).send(
                        "<@!522972601488900097> [DAILY TASK FAILURE|{}] `{}`\n```\n{}```"
                        .format(task[0], e, e.with_traceback()))
            await last_daily_data.edit(content=now.timestamp())
        await asyncio.sleep(1 * 60 * 5)
        await self.start_period_tasks()

    def search_member(self, name, deep_check=False):
        if member := self.main_guild.get_member_named(utils.get_discord_nick_format(name)):
            return member
        if not deep_check: return None
        # deep checking (for searches with no tag)
        name = name.lower()
        for member in self.main_guild.members:
            if name == (member.nick or member.name)[:-7].lower():
                return member


    def set_tfm_instance(self, tfm):
        self.tfm = tfm
