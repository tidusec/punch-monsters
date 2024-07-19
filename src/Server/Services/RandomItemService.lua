--!native
--!strict
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local AssertPlayer = require(ServerScriptService.Server.Modules.AssertPlayer)

local RandomItemService = Knit.CreateService {
  Name = "RandomItemService";
}

local Items = require(ServerScriptService.Server.Templates.RandomItems)

function RandomItemService:KnitStart()
	self._gamepass = Knit.GetService("GamepassService")
	self._boosts = Knit.GetService("BoostService")
end

function RandomItemService:GiveItem(player, map, boss)
	AssertPlayer(player)
	local item = self:GiveRandomItem(player, map)
	self:Redeem(player, item, boss)
	return true
end

function RandomItemService:Redeem(player, item)
	--// Redeem item
	return
end

function RandomItemService:GiveRandomItem(player, map)
	return
	--[[
	local chances = Items[map]
  	local has2xLuck = self._gamepass:DoesPlayerOwn(player, "2x Luck")
	local has10xLuck = self._gamepass:DoesPlayerOwn(player, "10x Luck")
	local has100xLuck = self._gamepass:DoesPlayerOwn(player, "100x Luck")
	local has10xLuckBoost = self._boosts:IsBoostActive(player, "10xLuck")
	local has100xLuckBoost = self._boosts:IsBoostActive(player, "100xLuck")
	local luckMultiplier = 1
	
	if has2xLuck then
		luckMultiplier = 2
	end

	if has10xLuck then
		luckMultiplier = 10
	end

	if has100xLuck then
		luckMultiplier = 100
	end

	if has10xLuckBoost then
		luckMultiplier += 10
	end

	if has100xLuckBoost then
		luckMultiplier += 100
	end
	
	local totalProbability = 0
	local cumulativeProbabilities = {}

	for prizeName, probability in chances do
		totalProbability += probability * luckMultiplier
		cumulativeProbabilities[prizeName] = totalProbability
	end
	
	local random = Random.new():NextNumber() * totalProbability
	for prizeName, cumulativeProbability in cumulativeProbabilities do
		if random <= cumulativeProbability then
			return prizeName
		end
	end
	
	for prizeName in self._eggTemplate.Chances do
		return prizeName
	end]]
end

return RandomItemService