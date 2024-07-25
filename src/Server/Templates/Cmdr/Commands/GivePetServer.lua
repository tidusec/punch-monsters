return function (context, petName, toPlayer, amount)
    local Knit = shared.Knit
    local PetService = Knit.GetService("PetService")

    local success, errormessage = pcall(function()
        for i = 1, amount do
            PetService:Add(toPlayer, petName)
        end
    end)
    if success then
        return "Gave " .. tostring(toPlayer) .. " " .. amount .. " " .. petName
    else
        return "Failed to give " .. tostring(toPlayer) .. " " .. amount .. " " .. petName .. " because " .. errormessage
    end
  end