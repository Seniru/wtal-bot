local WANDBOX_ENDPOINT = "https://wandbox.org/api"

local DATA_CHANNEL = "718723565167575061"
local DATA_ID = "718746213385502772"

local cmds = {}

cmds.test = function(discord, json)
    discord:getChannel(DATA_CHANNEL):send("```json\n" .. json.stringify({}) .. "\n```") 
end

cmds.getCommands = function(discord, json)
    return xpcall(function()
        local body = discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID).content:sub(8, -5)
        return json.parse(body)
    end, function(err)
        print("An error occured:" .. err)
        return {}
    end)
end

cmds.updateCommands = function(cmds, discord, json)
    return xpcall(function()
        discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID):setContent("```json\n" .. 
            json.stringify(cmds)
        .. "\n```")
    end, function(err)
        print("An error occured: " .. err)
        return false
    end)
end

cmds.runCommand = function(source, compiler, input, http, json)
    return xpcall(function()
        local head, code = http.request("GET", source)
        local options = {compiler = compiler, code = code, stdin = input}
        local head, body = http.request("POST", WANDBOX_ENDPOINT .. "/compile.json", {
            {"Content-Type", "application/json"}
        }, json.stringify(options))
        return json.parse(body)
    end, function(err)
        print("An error occured: " .. err)
        return false
    end)
end

return cmds
