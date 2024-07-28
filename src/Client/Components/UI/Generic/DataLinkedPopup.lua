--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local abbreviate = require(ReplicatedStorage.Assets.Modules.Abbreviate)

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

	self:AddToJanitor(self._data.DataUpdated:Connect(function(key, value)
		local linkedKey = self.Attributes.DataKey
		if key ~= linkedKey then return end
        if previous then
           if previous < value then
            task.spawn(function()
                local extra = self.Instance.Parent:Clone()
                extra.Visible = true
                extra.Position = UDim2.new(rand:NextNumber(0.2, 0.8), 0, rand:NextNumber(0.2, 0.8), 0)
                extra.Value.Text = "+"..abbreviate(value - previous)
                extra.Parent = self.Instance.Parent.Parent
                repeat task.wait(0.2) until gui.Enabled
                task.wait(2)
                extra:Destroy()
            end)
           end 
        end

        previous = value

	end))
	return
end

return Component.new(DataLinkedPopup)