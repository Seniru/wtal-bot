import aiotfm
import asyncio
import json
import os
import re

import data
import utils

from bots.cmd_handler import commands

class Transformice(aiotfm.Client):
	def __init__(self, name, password, loop, discord, community=0):
		super().__init__(community, True, True, loop)
		self.pid = 0
		self.name = name
		self.password = password
		self.discord = discord
		self.client_type = "Transformice"

	async def handle_packet(self, conn, packet):
		handled = await super().handle_packet(conn, packet.copy())

		if not handled:  # Add compatibility to more packets
			CCC = packet.readCode()

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
		await self.discord.get_channel(data.data["channels"]["tribe_chat"]).send(f"> **[{author}]** {message}")

	async def on_whisper(self, message):
		args = re.split(r"\s+", message.content)
		if (not message.sent) and args[0] in commands and commands[args[0]]["tfm"] and commands[args[0]]["whisper_command"]:
			await commands[args[0]]["f"](args[1:], message, self)
