--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local abbreviate = require(ReplicatedStorage.Assets.Modules.Abbreviate)
local TFM = require(ReplicatedStorage.Assets.Modules.TFMv2)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Component = require(Packages.Component)

local player = Players.LocalPlayer

local BoostLinkedText: Component.Def = {
	Name = script.Name;
	IgnoreAncestors = { StarterGui };
	Guards = {
		Ancestors = { player.PlayerGui },
        Attributes = {
			Potion = { Type = "string" }
        }
	};
}

function BoostLinkedText:Initialize(): nil
	self._boost = Knit.GetService("BoostService")
    local potion = self.Attributes.Potion
    local timeleft = self._boost:GetBoostTimeLeft(potion)
    task.spawn(function()
        local x = 0
        while true do
            --// synchronise every 20 seconds and do the rest on the client
            x += 1
            if x == 20 then
                x = 0
                timeleft = self._boost:GetBoostTimeLeft(potion)
            end
            if timeleft > 1 then
                timeleft -= 1 
            end

            self.Instance.Value.Text = TFM.FormatStr(TFM.Convert(math.floor(timeleft)), "%02h:%02m:%02S")
            task.wait(1)
        end
    end)

    self:AddToJanitor(self._boost.BoostUpdated:Connect(function()
        timeleft = self._boost:GetBoostTimeLeft(potion)
    end))
	return
end

return Component.new(BoostLinkedText)