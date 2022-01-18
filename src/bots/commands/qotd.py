async def queue(args, msg, client):

    import json
    from discord import Embed

    questions = list(enumerate(client.questions["questions"]))
    await msg.reply(embed = Embed.from_dict({
        "title": "QOTD queue",
        "description": "\n".join(map(lambda q: "{}. {}".format(q[0] + 1, q[1]), questions)),
        "color": 0x2987ba,
        "footer": {
            "text": "Total questions: {}".format(len(questions))
        }
    }))

async def add(args, msg, client):
    if idx := int(args[0]):
        client.questions["questions"].insert(idx, " ".join(args[1:]))
    else:   
        client.questions["questions"].append(" ".join(args)) 
        
    await client.update_qotd()
    await msg.reply("Added the question!")

async def remove(args, msg, client):
    try:
        client.questions["questions"].pop(int(args[0] if len(args) > 0 else "1") -1)
        await client.update_qotd()
        await msg.reply("Removed the question!")
    except Exception:
        await msg.reply("https://www.youtube.com/watch?v=VYMdlCEDYvo")


async def ask(args, msg, client):
    from datetime import datetime, timedelta
    from discord import Embed
    from data import data
    import json
    force = len(args) > 0 and args[0] == "force"
    now, lastpost = datetime.now(), datetime.fromtimestamp(client.questions["last-post"])
    cooldown_over = now > (lastpost + timedelta(seconds = 1 * 60 * 60 * 24))
    qotd_channel = client.get_channel(data["channels"]["qotd"])
    if force or cooldown_over:
        if len(client.questions["questions"]) > 0:
            qn = await qotd_channel.send(content = "<@&742418187198660719>", embed = Embed.from_dict({
                "title": "QOTD #{}".format(client.questions["index"]),
                "description": client.questions["questions"].pop(0),
                "color": 0x2987ba
            }))
            await client.start_public_thread("QOTD #{}".format(client.questions["index"]), qn.channel.id, qn.id)
            client.questions["index"] += 1
            client.questions["last-post"] = int(datetime.now().timestamp())
            await client.update_qotd()
            if msg: await msg.reply("Asked the question")
    else:
        if msg: await msg.reply("A question has been asked in the last 24 hours!")


delete = remove

