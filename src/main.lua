-- [[ ================================== ]] --
-- [[ Initialization ]] --

math.randomseed(os.time())

local http          = require("coro-http")
local timer         = require("timer")
local json          = require("json")
local md5           = require("md5")
local transfromage  = require("transfromage")

local discord       = require("./bots/discord.lua")

-- [ Optimizations ] --
local time = os.time


local data = {
    startTime = time()
}

-- [[ ================================== ]] --
discord:init()
