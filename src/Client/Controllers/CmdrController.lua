--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Cmdr = require(ReplicatedStorage.CmdrClient)

local CmdrController = Knit.CreateController {
	Name = "CmdrController";
}

function CmdrController:KnitInit(): nil
	Cmdr:SetActivationKeys({ Enum.KeyCode.K })
	return
end

return CmdrController