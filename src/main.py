import os
import asyncio

import aiomysql
async def test():
    import json
    aiomysql.create_pool()
    conn = await aiomysql.connect(host="db", user="user", db="db", password="password", port=3306)
    cur = await conn.cursor()
    
    await cur.execute("select * from test;")
    r = await cur.fetchall()
    print(r)
    await conn.commit()
    await cur.close()
    conn.close()

loop = asyncio.get_event_loop()

loop.run_until_complete(test())
loop.run_forever()
#from bots.Transformice import Transformice
##sys.path.append("discordslashcommands")
#from bots.Discord import Discord
#
#print("[INFO][SYSTME] Starting...")
#
#loop = asyncio.get_event_loop()
#
#discord = Discord()
#tfm = Transformice(os.getenv("USERNAME"), os.getenv("PASSWORD"), loop, discord)
#
#discord.set_tfm_instance(tfm)
#
#print("[INFO][DISCORD] Starting...")
#loop.create_task(discord.start(os.getenv("DISCORD")))
##tfm.run()
#loop.run_forever()