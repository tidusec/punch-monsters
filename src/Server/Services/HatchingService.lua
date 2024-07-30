--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")

local Modules = ServerScriptService.Server.Modules
local Packages = ReplicatedStorage.Packages

local AssertPlayer = require(Modules.AssertPlayer)
local abbreviate = require(ReplicatedStorage.Assets.Modules.Abbreviate)

local Knit = require(Packages.Knit)
local Promise = require(Packages.Promise)
local Array = require(ReplicatedStorage.Modules.NewArray)

local HatchingService = Knit.CreateService {
  Name = "HatchingService";
  Client = {
    PetHatched = Knit.CreateSignal()
  };
}

function HatchingService:KnitStart(): nil
	self._data = Knit.GetService("DataService")
    self._pets = Knit.GetService("PetService")
  	self._boosts = Knit.GetService("BoostService")
  	self._gamepass = Knit.GetService("GamepassService")
  	self._eggTemplate = require(ReplicatedStorage.Templates.EggTemplate)
  	self._petsTemplate = require(ReplicatedStorage.Templates.PetsTemplate)
  	self._petsFolder = ReplicatedStorage.Assets.Pets
end

function HatchingService:HatchServer(player: Player, map: string, name: string)
	AssertPlayer(player)
  	assert(type(map) == "string", "Map must be a string")
  	assert(type(name) == "string", "Name must be a string")
	local egg = self._eggTemplate[map][name]
	if not egg then return end

	local petName = self:ReturnPet(player, egg)
	self._pets:Add(player, petName)
	self._data:IncrementValue(player, "Eggs")

	self.Client.PetHatched:Fire(player, petName, map, name)

	return
end

function HatchingService:HatchManyServer(player: Player, map: string, name: string, amount: number)
	assert(type(amount) == "number", "Amount must be a number")
	assert(amount > 0, "Amount must be greater than 0")

	local pets = Array.new()
	local egg = self._eggTemplate[map][name]
	if not egg then return end

	task.spawn(function()
		for _ = 1, amount do
			local petName = self:ReturnPet(player, egg)
			self._pets:Add(player, petName)
			self._data:IncrementValue(player, "Eggs")
			pets:Add(petName)
		end
	
		self.Client.PetHatched:Fire(player, pets:GetValues(), map, name)
	end)
	
	return
end

function HatchingService:DeductCost(player: Player, egg: table, amount: number): nil
	local WinsCost
	if egg.WinsCost then
		WinsCost = egg.WinsCost * amount
	end
	if egg["Robux"..amount] and not WinsCost then
		local success, result = pcall(function()
			return MarketplaceService:PromptProductPurchase(player, egg["Robux"..amount])
		end)
		--// processreceipt is fired when the player buys the product, so it will be handled there
		return
	else
		local wins = self._data:GetValue(player, "Wins")
		if  wins < WinsCost then
			return
		end
		self._data:DeductValue(player, "Wins", WinsCost)
	end

	return true
end

function HatchingService:HatchMany(player: Player, map: string, name: string, amount: number): nil
	AssertPlayer(player)
	assert(type(map) == "string", "Map must be a string")
	assert(type(name) == "string", "Name must be a string")
	local pets = self._data:GetValue(player, "Pets")
	if #pets.OwnedPets > pets.MaxStorage then
		return
	end
	local egg = self._eggTemplate[map][name]
	if not egg then return end

	local success = self:DeductCost(player, egg, amount)
	if not success then return end

	self:HatchManyServer(player, map, name, amount)

	return true
end

function HatchingService:Hatch(player: Player, map: string, name: string): nil
  	AssertPlayer(player)
  	assert(type(map) == "string", "Map must be a string")
  	assert(type(name) == "string", "Name must be a string")
	local pets = self._data:GetValue(player, "Pets")
	if #pets.OwnedPets > pets.MaxStorage then
		return
	end
	local egg = self._eggTemplate[map][name]
	if not egg then return end
	
	local success = self:DeductCost(player, egg, 1)

	if not success then return end
	self:HatchServer(player, map, name)

  	return true
end

function HatchingService:ShowFakeHatch(player, petName, map, egg)
	self.Client.PetHatched:Fire(player, petName, map, egg)
end

function HatchingService:GetFreePetGift(player: Player): nil
	AssertPlayer(player)
	local data = self._data:GetValue(player, "Tutorial")

	if data == false then
		self._data:SetValue(player, "Tutorial", true)
		self._pets:Add(player, "Mystic Ice Demon")
		self:ShowFakeHatch(player, "Mystic Ice Demon", "Server", "Server2")
	end
end


function HatchingService:ReturnPet(player, egg): string
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
	for petName, probability in egg.Chances do
		totalProbability += probability * luckMultiplier
		cumulativeProbabilities[petName] = totalProbability
	end
	
	local random = Random.new():NextNumber() * totalProbability
	for petName, cumulativeProbability in cumulativeProbabilities do
		if random <= cumulativeProbability then
			return petName
		end
	end
	
	for petName in self._eggTemplate.Chances do
		return petName
	end

	return
end

function HatchingService.Client:Hatch(player: Player, map: string, name: string): nil
  	return self.Server:Hatch(player, map, name)
end

function HatchingService.Client:HatchMany(player: Player, map: string, name: string, amount: number): nil
  	return self.Server:HatchMany(player, map, name, amount)
end

function HatchingService.Client:GetFreePetGift(player)
	return self.Server:GetFreePetGift(player)
end

return HatchingService