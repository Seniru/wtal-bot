local JSON_BIN_ENDPOINT = "https://api.jsonbin.io/b/5e70737c05179259c0bdbfde"
local JSON_BIN_SECRET = "$2b$10$" .. os.getenv("JSON_BIN_SECRET")

local qotd = {}

qotd.addQuestion = function(question, http, json)
    return xpcall(function()
        local head, body = http.request("GET", JSON_BIN_ENDPOINT, {{"secret-key", JSON_BIN_SECRET}})
        local res = json.parse(body)
        table.insert(res.questions, question)
        print(#res.questions)
        http.request("PUT", JSON_BIN_ENDPOINT, {
            {"Content-Type", "application/json"},
            {"secret-key", JSON_BIN_SECRET},
            {"versioning", "false"}
        }, json.stringify(res))
    end, function(err) 
        print("An error occured in the endpoint\nErr: " .. err)
    end)
end

qotd.retrieveQuestion = function(http, json, force)
    return xpcall(function()
        print("Retrieving JSON data")
        local head, body = http.request("GET", JSON_BIN_ENDPOINT, {{"secret-key", JSON_BIN_SECRET}})
        local res = json.parse(body)
        if #res.questions == 0 then return "No more questions", false end
        print("Retrieved! Manipulating data...")
        local question = res.questions[1]
        local isCooldownOver = os.time() > (res["last-post"] + 1 * 60 * 60 * 24)

        if force or isCooldownOver then
            table.remove(res.questions, 1)
            res["last-post"] = os.time()
            res["index"] = res["index"] + 1
            print("Manipulation done! Posting updated data...")
            http.request("PUT", JSON_BIN_ENDPOINT, {
                {"Content-Type", "application/json"},
                {"secret-key", JSON_BIN_SECRET},
                {"versioning", "false"}
            }, json.stringify(res))
            print("Printing the question...")
            return {question=question, index=res.index}, true
        else
            return "A question has been posted in the last 24 hours", false
        end
    end, function(err) 
        print("An error occured in the endpoint: " .. err)
        return "An error occured in the endpoint", false
    end)
end

qotd.getQuestionQueue = function(http, json)
    return xpcall(function()
        local head, body = http.request("GET", JSON_BIN_ENDPOINT, {{"secret-key", JSON_BIN_SECRET}})
        local questions = json.parse(body)["questions"]
        local res = ""
        local count = 0
        for _, question in next, questions do
            res = res .. (count + 1) .. ". " .. question .. "\n"
            count = count + 1
        end
        return res, count
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return "An error occured in the endpoint", false
    end)
end

qotd.deleteQuestion = function(questionId, http, json)
    return xpcall(function()
        print("Retrieving JSON data...")
        local head, body = http.request("GET", JSON_BIN_ENDPOINT, {{"secret-key", JSON_BIN_SECRET}})
        local res = json.parse(body)
        print("Deleting the question...")
        table.remove(res.questions, questionId)
        print("Updating JSON data...")
        http.request("PUT", JSON_BIN_ENDPOINT, {
                {"Content-Type", "application/json"},
                {"secret-key", JSON_BIN_SECRET},
                {"versioning", "false"}
            }, json.stringify(res)
        )
        print("Done!")
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
    end)
end

qotd.isInCooldown = function(http, json)
    return xpcall(function()
        local head, body = http.request("GET", JSON_BIN_ENDPOINT, {{"secret-key", JSON_BIN_SECRET}})
        local res = json.parse(body)["last-post"]
        return os.time() < res + 1 * 60 * 60 * 24
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
    end)
end

return qotd
