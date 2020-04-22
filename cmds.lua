local JSON_BIN_ENDPOINT = "https://api.jsonbin.io/b/5e9ecde1435f5604bb4556a5"
local JSON_BIN_SECRET = "$2b$10$" .. os.getenv("JSON_BIN_SECRET")
local WANDBOX_ENDPOINT = "https://wandbox.org/api"

local cmds = {}

cmds.getCommands = function(http, json)
    return xpcall(function()
        local head, body = http.request("GET", JSON_BIN_ENDPOINT, {{"secret-key", JSON_BIN_SECRET}})
        return json.parse(body)
    end, function(err)
        print("An error occured:" .. err)
        return {}
    end)
end

cmds.updateCommands = function(cmds, http, json)
    return xpcall(function()
        http.request("PUT", JSON_BIN_ENDPOINT, {
            {"Content-Type", "application/json"},
            {"secret-key", JSON_BIN_SECRET},
            {"versioning", "false"}
        }, json.stringify(cmds))
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
