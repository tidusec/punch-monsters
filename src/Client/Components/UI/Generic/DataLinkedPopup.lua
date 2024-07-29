--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local abbreviate = require(ReplicatedStorage.Assets.Modules.Abbreviate)
local Tween = require(ReplicatedStorage.Assets.Modules.Tween)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Component = require(Packages.Component)

local player = Players.LocalPlayer

local DataLinkedPopup: Component.Def = {
	Name = script.Name;
	IgnoreAncestors = { StarterGui };
	Guards = {
		ClassName = "TextLabel",
		Ancestors = { player.PlayerGui }
	};
}

function DataLinkedPopup:Initialize(): nil
	self._data = Knit.GetService("DataService")
    local previous
    local rand = Random.new()
    local gui = self.Instance:FindFirstAncestorOfClass("ScreenGui")
    local stacked = 0

	self:AddToJanitor(self._data.DataUpdated:Connect(function(key, value)
		local linkedKey = self.Attributes.DataKey
		if key ~= linkedKey then return end
        if previous then
           if previous < value then
            if stacked > 15 then return end
            stacked += 1
            task.spawn(function()
                local extra = self.Instance.Parent:Clone()
                extra.Visible = true
                extra.Position = UDim2.new(rand:NextNumber(0.2, 0.8), 0, rand:NextNumber(0.2, 0.8), 0)
                extra.Value.Text = "+"..abbreviate(value - previous)
                extra.Parent = self.Instance.Parent.Parent

                repeat task.wait(0.2) until gui.Enabled
                
                Tween.new(extra, {
                    Position = UDim2.new(extra.Position.X.Scale, 0, extra.Position.Y.Scale - 0.3, 0),
                }, 1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
                task.wait(0.3)
                Tween.new(extra, {
                    ImageTransparency = 1
                }, 0.7, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
                Tween.new(extra.Value, {
                    TextTransparency = 1
                }, 0.7, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
                Tween.new(extra.Value.UIStroke, {
                    Transparency = 1
                }, 0.7, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
                task.wait(0.7)
                extra:Destroy()
                stacked -= 1
            end)
           end 
        end

        previous = value

	end))
	return
end

return Component.new(DataLinkedPopup)