import os
import asyncio

from bots.Transformice import Transformice
#sys.path.append("discordslashcommands")
from bots.Discord import Discord

print("[INFO][SYSTME] Starting...")

loop = asyncio.get_event_loop()

discord = Discord()
tfm = Transformice(os.getenv("USERNAME"), os.getenv("PASSWORD"), loop, discord)

discord.set_tfm_instance(tfm)

print("[INFO][DISCORD] Starting...")
loop.create_task(discord.start(os.getenv("DISCORD")))
tfm.run()
loop.run_forever()