import re
import discord
import os
import utils

from data import data
from bots.cmd_handler import commands

intents = discord.Intents.default()
intents.members = True

class Discord(discord.Client):

    def __init__(self):
        super().__init__(intents = intents)
        self.client_type = "Discord"
        self.keys = {}
        self.main_guild = None
        
    async def on_ready(self):
        print("[INFO][DISCORD] Client is ready!")
        self.main_guild = self.get_guild(data["guild"])

    async def on_message(self, message):
        if message.content.startswith(">"):
            content = re.match(r"^>\s*(.+)", message.content).group(1)
            args = re.split(r"\s+", content)

            if args[0] in commands and commands[args[0]]["discord"]:
                await commands[args[0]]["f"](args[1:], message, self)

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

        verified_role = self.main_guild.get_role(data["roles"]["verified"])

        if not verified_role in after.roles:
            return

        normalized_nick = utils.get_tfm_nick_format(after.nick)
        tribe = await self.tfm.getTribe(True)
        print(normalized_nick.lower())
        tribe_member = tribe.get_member(normalized_nick.lower())
        rank_role = self.main_guild.get_role(data["ranks"]["Passer-by" if not tribe_member else tribe_member.rank.name])

        if not rank_role:
            pass
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

    def set_tfm_instance(self, tfm):
        self.tfm = tfm

    

