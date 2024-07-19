local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cmdr = require(ReplicatedStorage.Packages.Cmdr)
local Knit = require(ReplicatedStorage.Packages.Knit)

local CmdrService = Knit.CreateService {
    Name = "CmdrService";
    Client = {};
}

return CmdrService