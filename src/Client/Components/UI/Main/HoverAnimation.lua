--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Component = require(Packages.Component)

local player = Players.LocalPlayer

local HoverAnimation: Component.Def = {
    Name = script.Name;
    IgnoreAncestors = { StarterGui };
}

local UIController = Knit.GetController("UIController")

function HoverAnimation:Initialize(): nil
    if not self.Instance:GetAttribute("HoverAmount") == nil then
        UIController:AnimateButton(self.Instance, nil, self.Instance:GetAttribute("HoverAmount"))
        return
    end

    UIController:AnimateButton(self.Instance)
    return
end

return Component.new(HoverAnimation)