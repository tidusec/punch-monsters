--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)
local Knit = require(Packages.Knit)

local GamepassService = Knit.GetService("GamepassService")

local player = Players.LocalPlayer

local PurchasePromptButton: Component.Def = {
	Name = script.Name;
	IgnoreAncestors = { StarterGui };
	Guards = {
		Ancestors = { player.PlayerGui, workspace },
		Attributes = {
			ProductID = { Type = "number" },
			Gamepass = { Type = "boolean" }
		}
	};
}

function PurchasePromptButton:Event_MouseButton1Click(): nil
	local productID: number = self.Attributes.ProductID
	if self.Attributes.Gamepass then
		MarketplaceService:PromptGamePassPurchase(player, productID)
	else
		if productID == 1890708273 then
			if GamepassService:DoesPlayerOwn("+500 Inventory Space") then
				return
			end
		elseif productID == 1890693814 then
			if GamepassService:DoesPlayerOwn("8x Hatch") then
				return
			end
		elseif productID == 1890692458 then
			if GamepassService:DoesPlayerOwn("10x Luck") then
				return
			end
		elseif productID == 1890692021 then
			if GamepassService:DoesPlayerOwn("100x Luck") then
				return
			end
		elseif productID == 1890690821 then
			if GamepassService:DoesPlayerOwn("+4 Pets Equipped") then
				return
			end
		end
		MarketplaceService:PromptProductPurchase(player, productID)
	end
	return
end

return Component.new(PurchasePromptButton)