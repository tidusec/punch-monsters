--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Component = require(Packages.Component)

local player = Players.LocalPlayer

local ScreenRoute: Component.Def = {
    Name = script.Name;
    IgnoreAncestors = { StarterGui };
    Attributes = {
        DestinationScreen = { Type = "string" }
    },
    Guards = {
        Ancestors = { player.PlayerGui },
        ClassName = "ImageButton",
    };
}

function ScreenRoute:Initialize(): nil
    self._ui = Knit.GetController("UIController")
    self:AddToJanitor(self.Instance.MouseButton1Click:Connect(function()
        local destination = self.Attributes.DestinationScreen
        local blur = true
        if destination == "MainUi" then
            blur = false
        end
        self._ui:SetScreen(self.Attributes.DestinationScreen, blur)
    end))
    return
end

return Component.new(ScreenRoute)