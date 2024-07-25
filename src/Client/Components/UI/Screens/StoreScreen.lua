local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tween = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local Assets = ReplicatedStorage.Assets
local Pets = Assets.Pets

local Tweens = require(script.Parent.Parent.Parent.Parent.Modules.Tweens)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Array = require(ReplicatedStorage.Modules.NewArray)
local Component = require(Packages.Component)

local player = Players.LocalPlayer

local StoreScreen: Component.Def = {
	Name = script.Name;
	IgnoreAncestors = { StarterGui };
	Guards = {
		Ancestors = { player.PlayerGui },
		ClassName = "ScreenGui",
	};
}

function StoreScreen:Initialize(): nil
    self._ui = Knit.GetController("UIController")

	self._background = self.Instance.Background
    self._contentFrame = self._background.Content
    self._LimitedTimeEgg = self._contentFrame.LimitedTimeEgg
    self._StorePets = self._contentFrame.StorePets

    local LimitedTimeEggPets = {
        ["Panda"] = self._LimitedTimeEgg.Panda;
        ["Lamb"] = self._LimitedTimeEgg.Lamb;
        ["Yeti"] = self._LimitedTimeEgg.Yeti;
        ["Icy Hedgehog"] = self._LimitedTimeEgg["Icy Hedgehog"];
        ["Huge Snowman"] = self._LimitedTimeEgg["Huge Snowman"];
    }

    local StorePets = {
        ["Heart and Soul"] = self._StorePets["Heart and Soul"];
        ["Mystic Golden Pot"] = self._StorePets["Mystic Golden Pot"];
        ["Mystic Shattered Shard"] = self._StorePets["Mystic Shattered Shard"];
        ["Mystic Crystal Demon"] = self._StorePets["Mystic Crystal Demon"];
    }

    for petName, petFrame in pairs(LimitedTimeEggPets) do
        self._ui:AddModelToViewport(petFrame.ViewportFrame, Pets:FindFirstChild(petName))
    end

    for petName, petFrame in pairs(StorePets) do
        self._ui:AddModelToViewport(petFrame.ViewportFrame, Pets:FindFirstChild(petName))
    end

	return
end

return Component.new(StoreScreen)
