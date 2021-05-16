import os
import asyncio

from bots.Transformice import Transformice
from bots.Discord import Discord

loop = asyncio.get_event_loop()

discord = Discord()
tfm = Transformice("Wtal#5272", os.getenv("PASSWORD"), loop, discord)

discord.set_tfm_instance(tfm)

loop.create_task(discord.start(os.getenv("DISCORD")))
#tfm.run()
loop.run_forever()
