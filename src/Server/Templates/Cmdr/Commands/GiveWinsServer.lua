return function (context, player, wins)
    local Knit = shared.Knit
    local DataService = Knit.GetService("DataService")

    local success, errormessage = pcall(function()
        DataService:IncrementValue(player, "Wins", wins)
    end)
    if success then
        return "Successfully gave " .. tostring(wins) .. " wins to " .. tostring(player)
    else
        return "Failed to give wins to " .. tostring(player) .. " because: " .. tostring(errormessage)
    end
  end