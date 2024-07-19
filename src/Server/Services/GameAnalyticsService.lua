local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local GameAnalytics = require(Packages.GameAnalytics)
local Knit = require(Packages.Knit)

local GameAnalyticsService = Knit.CreateService {
    Name = "GameAnalyticsService";
    Client = {};
}

function GameAnalyticsService:KnitInit(): nil
    GameAnalytics:configureBuild("0.1.0")
    --// TODO: Add this as a game secret
    GameAnalytics:initialize({
        gameKey = "d56ad73fe937100837e8107353b1dd8f",
        secretKey = "610e25e1fbf416eb7cd07ad09d3699b94c7d49d3",
        automaticSendBusinessEvents = true,
    })
    return
end

function GameAnalyticsService:RegisterCurrencyAdded(userid: number, currencyType: string, amount: number): nil
    assert(type(currencyType) == "string", "Currency type must be a string")
    assert(type(amount) == "number", "Amount must be a number")
    assert(type(userid) == "number", "Userid must be number")

    GameAnalytics:addResourceEvent(userid, {
        flowType = GameAnalytics.EGAResourceFlowType.Source,
        currency = currencyType,
        amount = amount,
        itemType = "Game",
    })
    return
end

function GameAnalyticsService:RegisterCurrencySpent(userid: number, currencyType: string, amount: number): nil
    assert(type(currencyType) == "string", "Currency type must be a string")
    assert(type(amount) == "number", "Amount must be a number")
    assert(type(userid) == "number", "Userid must be number")

    GameAnalytics:addResourceEvent(userid, {
        flowType = GameAnalytics.EGAResourceFlowType.Sink,
        currency = currencyType,
        amount = amount,
        itemType = "Game",
    })
    return
end

function GameAnalyticsService:MapProgress(userid: number, map: string): nil
    assert(type(userid) == "number", "Userid must be number")
    assert(type(map) == "string", "Map must be a string")

    GameAnalytics:addProgressionEvent(userid, {
        --// ???
    })
    return
end

return GameAnalyticsService