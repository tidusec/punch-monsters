return function (context, player, rebirths)
    local Knit = shared.Knit
    local RebirthService = Knit.GetService("RebirthService")

    local success, errormessage = pcall(function()
        for i = 1, rebirths do
            RebirthService:_AddRebirth(player)
        end
    end)
    if success then
        return "Successfully gave " .. tostring(rebirths) .. " rebirths to " .. tostring(player)
    else
        return "Failed to give rebirths to " .. tostring(player) .. " because: " .. tostring(errormessage)
    end
  end