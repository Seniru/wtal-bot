local JSON_BIN_ENDPOINT = "https://api.jsonbin.io/b/5e9869195fa47104cea1b350"
local JSON_BIN_SECRET = "$2b$10$" .. os.getenv("JSON_BIN_SECRET")

local modsys = {}

modsys.getJSON = function(http)
    return xpcall(function()
        local head, body = http.request("GET", JSON_BIN_ENDPOINT, {{"secret-key", JSON_BIN_SECRET}})
        return body
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return "An error occured in the endpoint", false
    end)
end

modsys.warnMember = function(member, reason, http, json)
    return xpcall(function()
        local head, body = http.request("GET", JSON_BIN_ENDPOINT, {{"secret-key", JSON_BIN_SECRET}})
        local res = json.parse(body)
        if not res.warnings[member] then
            res.warnings[member] = {reason}
        else
            table.insert(res.warnings[member], reason)
        end
        http.request("PUT", JSON_BIN_ENDPOINT, {
            {"Content-Type", "application/json"},
            {"secret-key", JSON_BIN_SECRET},
            {"versioning", "false"}
        }, json.stringify(res))
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return "An error occured in the endpoint", false
    end)
end

modsys.removeWarning = function(member, id, http, json)
    return xpcall(function()
        local head, body = http.request("GET", JSON_BIN_ENDPOINT, {{"secret-key", JSON_BIN_SECRET}})
        local res = json.parse(body)
        if res.warnings[member] then
            table.remove(res.warnings[member], id)
            http.request("PUT", JSON_BIN_ENDPOINT, {
                {"Content-Type", "application/json"},
                {"secret-key", JSON_BIN_SECRET},
                {"versioning", "false"}
            }, json.stringify(res))
        end
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return "An error occured in the endpoint", false
    end)
end

modsys.getWarnings = function(member, http, json)
    return xpcall(function()
        local head, body = http.request("GET", JSON_BIN_ENDPOINT, {{"secret-key", JSON_BIN_SECRET}})
        local warnings = json.parse(body)["warnings"][member]
        return warnings, warnings and #warnings or 0
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return "An error occured in the endpoint", false
    end)
end

modsys.blacklistPlayer = function(member, http, json)
    return xpcall(function()
        local head, body = http.request("GET", JSON_BIN_ENDPOINT, {{"secret-key", JSON_BIN_SECRET}})
        local res = json.parse(body)
        res.blacklist[member] = true
        http.request("PUT", JSON_BIN_ENDPOINT, {
            {"Content-Type", "application/json"},
            {"secret-key", JSON_BIN_SECRET},
            {"versioning", "false"}
        }, json.stringify(res))
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return "An error occured in the endpoint"
    end)
end

modsys.whitelistPlayer = function(member, http, json)
    return xpcall(function()
        local head, body = http.request("GET", JSON_BIN_ENDPOINT, {{"secret-key", JSON_BIN_SECRET}})
        local res = json.parse(body)
        res.blacklist[member] = nil
        http.request("PUT", JSON_BIN_ENDPOINT, {
            {"Content-Type", "application/json"},
            {"secret-key", JSON_BIN_SECRET},
            {"versioning", "false"}
        }, json.stringify(res))     
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return "An error occured in the endpoint"
    end)
end

modsys.getBlacklist = function(http, json)
    return xpcall(function()
        local head, body = http.request("GET", JSON_BIN_ENDPOINT, {{"secret-key", JSON_BIN_SECRET}})
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

modsys.isBlacklisted = function(member, http, json)
    return xpcall(function()
        local head, body = http.request("GET", JSON_BIN_ENDPOINT, {{"secret-key", JSON_BIN_SECRET}})
        local res = json.parse(body)
        return not not res.blacklist[member]
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return false
    end)
end

return modsys