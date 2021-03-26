local discordia = require("discordia")
local utils     = require("utils")

local cmds      = require("./commandHandler")
local enum      = require("../enum")

local getenv = os.getenv

local discord = {
    prefix = ">",
    bot = discordia.Client({
        cacheAllMembers = true
    }),
    tfm = require("./tfm")
}

discord.bot:once("ready", function()
    discord.guild = discord.bot:getGuild(enum.guild)
    discord.tfm:init(discord)
end)

discord.bot:on("messageCreate", function(msg)
    local content = msg.content:match("^" .. discord.prefix .. "%s*(.*)")
    if not content then return end
    local args = string.split(content, "%s+")
    local cmd = args[1]
    table.remove(args, 1)
    if cmds[cmd] and cmds[cmd].discord then
        cmds[cmd].discord.f(args, msg, msg.author, discord.bot, discord.tfm.bot)
    end
end)

function discord:init()
    print("[INFO] Initializing discord bot...")
    self.bot:run("Bot " .. getenv("DISCORD"))
end

return discord
