return function (context, player)
    local Knit = shared.Knit
    local DataService = Knit.GetService("DataService")

    local success, errormessage = pcall(function()
        DataService:Wipe(player)
    end)
    if success then
        return "Wiped " .. tostring(player).. " successfully"
    else
        return "Failed to wipe " .. tostring(player) .. " because " .. errormessage.." please try again."
    end
  end