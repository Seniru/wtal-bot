import aiotfm
import asyncio
import json
import os
import re

import data
import utils

from bots.cmd_handler import commands
from bots.commands.mod import kick

class Transformice(aiotfm.Client):
	def __init__(self, name, password, loop, discord, community=0):
		super().__init__(community, True, True, loop)
		self.pid = 0
		self.name = name
		self.password = password
		self.discord = discord
		self.client_type = "Transformice"
		self.members = []

	async def handle_packet(self, conn, packet):
		handled = await super().handle_packet(conn, packet.copy())

		if not handled:  # Add compatibility to more packets
			CCC = packet.readCode()

			if CCC == (60, 3): # Tribulle
				TC = packet.read16()

				if TC == 91:
					self.dispatch("tribe_new_member",
						packet.readUTF() # nick
					)

				elif TC == 92:
					self.dispatch("tribe_member_left",
						packet.readUTF() # nick
					)

				elif TC == 93:
					self.dispatch("tribe_member_kicked",
						packet.readUTF(), # target
						packet.readUTF() # kicker
					)

				elif TC == 124:
					self.dispatch("tribe_member_get_role", 
						packet.readUTF(), # setter
						packet.readUTF(), # target
						packet.readUTF() # rank
					)


	def run(self, block=True):

		self.loop.run_until_complete(self.start())
		if block:
			self.loop.run_forever()

	async def on_login_ready(self, online_players, community, country):
		print(f"[INFO][TFM] Login Ready [{community}-{country}]")
		await self.login(self.name, self.password, encrypted=False, room="*#castle")

	async def on_logged(self, player_id, username, played_time, community, pid):
		self.pid = pid

	async def on_ready(self):
		print("[INFO][TFM] Connected to community platform")

	async def on_tribe_message(self, author, message):
		author = utils.normalize_name(author)
		await self.discord.get_channel(data.data["channels"]["tribe_chat"]).send(utils.normalize_msg_from_tc(f"> **[{author}]** {message}", self.discord))

	async def on_tribe_member_get_role(self, setter, target, role):
		await self.discord.get_channel(data.data["channels"]["tribe_chat"]).send("> {} has changed the rank of {} to {}.".format(
			utils.normalize_name(setter),
			utils.normalize_name(target),
			role
		))
		await self.update_member(target)

	async def on_tribe_new_member(self, name):
		name = utils.normalize_name(name)
		await self.discord.get_channel(data.data["channels"]["tribe_chat"]).send("> {} just joined the tribe!.".format(utils.normalize_name(name)))
		if self.discord.mod_data["blacklist"].get(name):
			await kick([name], None, self.discord) # passing self.discord is just a hacky approach here
			return await self.sendTribeMessage(f"{name} is in the blacklist, please do not invite them again!")
		await self.sendTribeMessage(f"Welcome to 'A place to call home' {name}!")
		await self.update_member(name)

	async def on_tribe_member_left(self, name):
		await self.discord.get_channel(data.data["channels"]["tribe_chat"]).send("> {} has left the tribe ;c".format(utils.normalize_name(name)))
		await self.update_member(name)

	async def on_tribe_member_kicked(self, name, kicker):
		await self.discord.get_channel(data.data["channels"]["tribe_chat"]).send("> {} has kicked {} out of the tribe!".format(
			utils.normalize_name(kicker),
			utils.normalize_name(name)
		))
		await self.update_member(name)

	async def on_member_connected(self, name):
		await self.discord.get_channel(data.data["channels"]["tribe_chat"]).send(f"> {} just connected!")
		await self.sendTribeMessage(f"Welcome back {name}!")

	async def on_member_disconnected(self, name):
		await self.discord.get_channel(data.data["channels"]["tribe_chat"]).send(f"> {} has disconnected!")

	async def on_whisper(self, message):
		args = re.split(r"\s+", message.content)
		if (not message.sent) and args[0] in commands and commands[args[0]]["tfm"] and commands[args[0]]["whisper_command"]:
			await commands[args[0]]["f"](args[1:], message, self)

	async def update_member(self, target):
		discord_nick = utils.get_discord_nick_format(utils.normalize_name(target))
		member = self.discord.main_guild.get_member_named(discord_nick)
		await self.discord.on_member_update(member, member)

		