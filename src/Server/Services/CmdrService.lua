local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cmdr = require(ReplicatedStorage.Packages.Cmdr)
local Knit = require(ReplicatedStorage.Packages.Knit)

local CmdrFolder = game:GetService("ServerScriptService"):WaitForChild("Server"):WaitForChild("Templates"):WaitForChild("Cmdr")

local CmdrService = Knit.CreateService {
    Name = "CmdrService";
    Client = {};
}

function CmdrService:KnitInit(): nil
    Cmdr:RegisterDefaultCommands()
    Cmdr:RegisterHooksIn(CmdrFolder.Hooks)
    Cmdr:RegisterTypesIn(CmdrFolder.Types)
    Cmdr:RegisterCommandsIn(CmdrFolder.Commands)
    return
end

return CmdrService