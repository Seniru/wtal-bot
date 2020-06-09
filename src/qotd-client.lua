local DATA_CHANNEL = "718723565167575061"
local DATA_ID = "718728423475904562"

local qotd = {}

qotd.test = function(discord, json)
    discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID):setContent([[```json
 {"last-post":0,"questions":["What was the moment you knew you weren't a kid anymore?","What was the lowest point in life?"],"index":125}
```]]) 
end

qotd.addQuestion = function(question, discord, json)
    return xpcall(function()
        local body = discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID).content:sub(8, -5)
        local res = json.parse(body)
        table.insert(res.questions, question)
        discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID):setContent("```json\n" .. 
            json.stringify(res)
        .. "\n```")
    end, function(err) 
        print("An error occured in the endpoint\nErr: " .. err)
    end)
end

qotd.retrieveQuestion = function(discord, json, force)
    return xpcall(function()
        print("Retrieving JSON data")
        local body = discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID).content:sub(8, -5)
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
            discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID):setContent("```json\n" .. 
                json.stringify(res)
            .. "\n```")
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

qotd.getQuestionQueue = function(discord, json)
    return xpcall(function()
        local body = discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID).content:sub(8, -5)
        local questions = json.parse(body)["questions"]
        local res = ""
        local count = 0
        for _, question in next, questions do
            res = res .. (count + 1) .. ". " .. question .. "\n"
            count = count + 1
        end
        p(questions)
        return res, count
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
        return "An error occured in the endpoint", false
    end)
end

qotd.deleteQuestion = function(questionId, discord, json)
    return xpcall(function()
        print("Retrieving JSON data...")
        local body = discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID).content:sub(8, -5)
        local res = json.parse(body)
        print("Deleting the question...")
        table.remove(res.questions, questionId)
        print("Updating JSON data...")
        discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID):setContent("```json\n" .. 
                json.stringify(res)
        .. "\n```")
        print("Done!")
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
    end)
end

qotd.isInCooldown = function(discord, json)
    return xpcall(function()
        local body = discord:getChannel(DATA_CHANNEL):getMessage(DATA_ID).content:sub(8, -5)
        local res = json.parse(body)["last-post"]
        return os.time() < (res + 1 * 60 * 60 * 24)
    end, function(err)
        print("An error occured in the endpoint\nErr: " .. err)
    end)
end

return qotd
