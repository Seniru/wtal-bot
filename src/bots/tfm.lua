local transfromage  = require("transfromage")
local utils         = require("utils")

local cmds          = require("./commandHandler")
local enum          = require("../enum")

local getenv = os.getenv

local tfm = {
    bot = transfromage.client:new(nil, nil, true, true),
    loginAttempts = 5,
    discord = nil
}
   
tfm.bot:once("ready", function()
    print("[INFO] Logging into transformice...")
    tfm.bot:connect("Wtal#5272", getenv("PASSWORD"))
end)

tfm.bot:on("connection", function(name, comm, id, time)
    print("[INFO] Logged in successfully!")
    tfm.loginAttempts = 5
    tfm.bot:openTribeInterface(true)
    p(tfm.bot:waitFor("tribeInterface"))
    --tfm:sendTribeMessage("Connected to tribe chat!")
    -- tfm.discord:setGame(onlineCount .. " / " .. totalMembers .. " Online!")
end)

tfm.bot:on("connectionFailed", function()
    if tfm.loginAttempts > 0 then
        print("[ERR] Connection to transformice failed! Trying again (Attempts: " .. tfm.loginAttempts .. ")")
        tfm.loginAttempts = tfm.loginAttempts - 1
        tfm.bot:connect("Wtal#5272", getenv("PASSWORD"))
    else
        print("[INFO]Connection to transformice failed! Restarting...")
        os.exit(1)
    end
end)

tfm.bot:on("tribeMessage", function(member, message)
    tfm.discord.guild:getChannel(enum.channels.tribe_chat):send(
        ("> **[" .. member .. "]** " .. message):gsub("@here", "@|here"):gsub("@everyone", "@|everyone")
    )
end)

function tfm:init(discordClient)
    print("[INFO] Initializing transformice bot...")
    tfm.bot:handlePlayers(true)
    tfm.bot:setLanguage("en")
    tfm.bot:start("89818485", getenv("TFMAGE"))
    tfm.discord = discordClient
end

return tfm
