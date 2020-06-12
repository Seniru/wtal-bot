local DATA_CHANNEL = "718723565167575061"
local BIRTHDAY_CHANNEL = "592742600058994688"
local LAST_POST_DATA_MSG = "719816851781058670"
local BIRTHDAY_LIST_MSG = "592742900509704205"
local BIRTHDAY_LIST_MSG2 = "592743169863581713"

local bdays = {}

bdays.isInCooldown = function(discord)
    local lastPost = tonumber(discord:getChannel(DATA_CHANNEL):getMessage(LAST_POST_DATA_MSG).content)
    return os.time() < (lastPost + 1 * 60 * 60 * 24)
end

bdays.getBirthdays = function(discord, channel, defaultChannel)
    local body = 
        discord:getChannel(BIRTHDAY_CHANNEL):getMessage(BIRTHDAY_LIST_MSG).content ..
        discord:getChannel(BIRTHDAY_CHANNEL):getMessage(BIRTHDAY_LIST_MSG2).content
    local birthdays = {}
    local today = os.date("*t", os.time()).day .. os.date(" %B", os.time())

    for match in body:gmatch("\n" .. today .. " %- (.-#%d+)") do
        birthdays[#birthdays + 1] = match
    end

    local embed = {
        title = ":birthday: Today's birthdays :tada:",
        description = #birthdays == 0 and "No birthdays today :(" or table.concat(birthdays, "\n"),
        color = 0xffff33,
        timestamp = os.date('%Y-%m-%dT%H:%M:%S', os.time())
    }

    if not channel then
        if #birthdays > 0 and not bdays.isInCooldown(discord) then
            discord:getChannel(defaultChannel):send {embed = embed}
            discord:getChannel(DATA_CHANNEL):getMessage(LAST_POST_DATA_MSG):setContent(os.time())
        end
    else
        channel:send {embed = embed}
    end
end

return bdays