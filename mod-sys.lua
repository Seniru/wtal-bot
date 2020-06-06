local JSON_BIN_ENDPOINT = "https://api.jsonbin.io/b/5e9869195fa47104cea1b350"
local JSON_BIN_SECRET = "$2b$10$" .. os.getenv("JSON_BIN_SECRET")
local DATA_CHANNEL = "718723565167575061"
local DATA_ID = "718747955557040158"

local modsys = {}

modsys.test = function(discord, json)
    discord:getChannel(DATA_CHANNEL):send("```json\n" .. json.stringify(
        {
            ["warnings"] = {},
            ["blacklist"] = {}
        }
    ) .. "\n```") 
end

modsys.getJSON = function(discord)
    return xpcall(function()
        local body = discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID).content:sub(8, -5)
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return "An error occured in the endpoint", false
    end)
end

modsys.warnMember = function(member, reason, discord, json)
    return xpcall(function()
        local body = discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID).content:sub(8, -5)
        local res = json.parse(body)
        if not res.warnings[member] then
            res.warnings[member] = {reason}
        else
            table.insert(res.warnings[member], reason)
        end
        discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID):setContent("```json\n" .. 
            json.stringify(res)
        .. "\n```")
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return "An error occured in the endpoint", false
    end)
end

modsys.removeWarning = function(member, id, discord, json)
    return xpcall(function()
        local body = discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID).content:sub(8, -5)
        local res = json.parse(body)
        if res.warnings[member] then
            table.remove(res.warnings[member], id)
            discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID):setContent("```json\n" .. 
                json.stringify(res)
            .. "\n```")
        end
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return "An error occured in the endpoint", false
    end)
end

modsys.getWarnings = function(member, discord, json)
    return xpcall(function()
        local body = discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID).content:sub(8, -5)
        local warnings = json.parse(body)["warnings"][member]
        return warnings, warnings and #warnings or 0
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return "An error occured in the endpoint", false
    end)
end

modsys.blacklistPlayer = function(member, discord, json)
    return xpcall(function()
        local body = discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID).content:sub(8, -5)
        local res = json.parse(body)
        res.blacklist[member] = true
        discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID):setContent("```json\n" .. 
            json.stringify(res)
        .. "\n```")
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return "An error occured in the endpoint"
    end)
end

modsys.whitelistPlayer = function(member, discord, json)
    return xpcall(function()
        local body = discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID).content:sub(8, -5)
        local res = json.parse(body)
        res.blacklist[member] = nil
        discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID):setContent("```json\n" .. 
            json.stringify(res)
        .. "\n```")
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return "An error occured in the endpoint"
    end)
end

modsys.getBlacklist = function(discord, json)
    return xpcall(function()
        local body = discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID).content:sub(8, -5)
        local res = json.parse(body)
        local list = {}
        for name, listed in next, res.blacklist do
            list[#list + 1] = name
        end
        return list
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return {}
    end)
end

modsys.isBlacklisted = function(member, discord, json)
    return xpcall(function()
        local body = discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID).content:sub(8, -5)
        local res = json.parse(body)
        return not not res.blacklist[member]
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return false
    end)
end

return modsys
