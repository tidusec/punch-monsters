local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterPlayer = game:GetService("StarterPlayer")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local Client = script:FindFirstAncestorOfClass("LocalScript")
local Packages = ReplicatedStorage.Packages
local Functions = Client.Functions
local EggTemplate = require(ReplicatedStorage.Templates.EggTemplate)
local PetsTemplate = require(ReplicatedStorage.Templates.PetsTemplate)

local Knit = require(Packages.Knit)
local Component = require(Packages.Component)
local Janitor = require(Packages.Janitor)
local Array = require(Packages.Array)

local UserInterface = ReplicatedStorage.Assets.UserInterface
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local characterRoot = character:WaitForChild("HumanoidRootPart")

local MAX_STAND_DISTANCE = 8

local HatchingStand = Component.new({
	Tag = script.Name,
	Ancestors = {workspace.Map1.Eggs} --workspace.Map2.Eggs, workspace.Map3.Eggs
})

function HatchingStand:Start(): nil
	Knit.GetController("ComponentController"):Register(self)
	self._pets = Knit.GetService("PetService")
	self._gamepass = Knit.GetService("GamepassService")
	self._ui = Knit.GetController("UIController")
	
	self._janitor = Janitor.new()
	self._janitor:Add(self.Instance)
	self._hatching = false
	
	local eggUi = player.PlayerGui.EggUi
	self._eggViewport = eggUi.EggViewport
	self._egg = self.Instance.Egg
	self._map = self.Instance.Parent.Parent.Name
	self._eggTemplate = EggTemplate[self._map][self.Instance.Name]
	
	self:AddPetCards()
end

local function createPet(petName: string)
	local pet = PetsTemplate[petName]
	return {
		Name = petName,
		ID = HttpService:GenerateGUID(),
		Rarity = pet.Rarity,
		StrengthMultiplier = pet.StrengthMultiplier
	}
end

function HatchingStand:ReturnPet()
	local has2xLuck = self._gamepass:DoesPlayerOwn("2x Luck")
	local has10xLuck = self._gamepass:DoesPlayerOwn("10x Luck")
	local has100xLuck = self._gamepass:DoesPlayerOwn("100x Luck")
	local luckMultiplier = 0
	
	if has2xLuck then
		luckMultiplier += 2
	end
	if has10xLuck then
		luckMultiplier += 10
	end
	if has100xLuck then
		luckMultiplier += 100
	end
	
	local totalProbability = 0
	local cumulativeProbabilities = {}
	for petName, probability in self._eggTemplate.Chances do
		totalProbability += probability * luckMultiplier
		cumulativeProbabilities[petName] = totalProbability
	end
	
	local random = Random.new():NextNumber() * totalProbability
	for petName, cumulativeProbability in cumulativeProbabilities do
		if random <= cumulativeProbability then
			return createPet(petName)
		end
	end
	
	for petName in self._eggTemplate.Chances do
		return createPet(petName)
	end
end

function HatchingStand:Hatch()
	if self._hatching then return end
	self._hatching = true
	
	local pet = self:ReturnPet(self._eggTemplate)
	if not pet then
		self._hatching = false
		return warn("No pet returned from HatchingStand")
	end
	
	local petModel = ReplicatedStorage.Assets.Pets:FindFirstChild(pet.Name)
	if not petModel then
		self._hatching = false
		return warn(`Could not find pet model "{pet.Model}"`)
	end
	
	self._pets:Add(pet)
	self._eggViewport:SetAttribute("FitModel", false)
	self._eggViewport:SetAttribute("FOV", nil)
	self._eggViewport:SetAttribute("ModelRotation", 0)
	self._ui:AddModelToViewport(self._eggViewport, self._egg, { replaceModel = true })
	self._ui:SetScreen("EggUi", true)
	task.delay(2.5, function()
		self._eggViewport:SetAttribute("FitModel", true)
		self._eggViewport:SetAttribute("FOV", 15)
		self._eggViewport:SetAttribute("ModelRotation", -120)
		self._ui:AddModelToViewport(self._eggViewport, petModel, { replaceModel = true })
		task.wait(2.5)
		self._ui:SetScreen("MainUi", false)
	end)
	
	local cost = self._eggTemplate.WinsCost
	if self._eggTemplate.Robux and not cost then
		print("devproduct here")
	end
	
	self._hatching = false
	self._chancesUI.Enabled = true
end

function HatchingStand:BuyOne(): nil
	if not self:IsClosest() then return end
	self:Hatch()
end

function HatchingStand:BuyThree(): nil
	if not self:IsClosest() then return end
	
	for _ = 1, 3 do
		task.spawn(function()
			self:Hatch()
		end)
	end
end

function HatchingStand:Auto(): nil
	if not self:IsClosest() then return end
	-- do stuff
end

function getDistanceFromPlayer(stand: Model): number
	local primaryPart = stand.Egg.PrimaryPart
	if not primaryPart then error(`No primary part in egg "{stand.Egg:GetFullName()}"`) end 
	return (primaryPart.Position - characterRoot.Position).Magnitude
end

function HatchingStand:IsClosest(): boolean
	local closestStand= Array.new(CollectionService:GetTagged(self.Tag) )
		:Filter(function(stand)
			local distance = getDistanceFromPlayer(stand)
			return distance <= MAX_STAND_DISTANCE
		end)
		:Sort(function(a, b)
			local distanceA = getDistanceFromPlayer(a)
			local distanceB = getDistanceFromPlayer(b)
			return distanceA < distanceB
		end)
		:First()

	return closestStand == self.Instance
end

function HatchingStand:AddPetCards(): nil
	self._chancesUI = UserInterface.Hatching.HatchingUi:Clone()
	local container: Frame = self._chancesUI.Background.PetChances
	self._chancesUI.Enabled = true
	
	task.spawn(function()
		local pets = Array.new()
		for pet, chance in self._eggTemplate.Chances do
			pets:Push({
				Name = pet, 
				Chance = chance
			})
		end

		pets:SortMutable(function(a, b)
			return a.Chance > b.Chance
		end)

		for pet in pets:Values() do
			self._chancesUI.Enabled = true
			local petModel: Model? = ReplicatedStorage.Assets.Pets:FindFirstChild(pet.Name)		
			local petCard: ImageLabel = UserInterface.Hatching.PetChanceCard:Clone()
			local viewport: ViewportFrame = petCard.Viewport
			petCard.Chance.Text = `{pet.Chance}%`
			petCard.Parent = container

			CollectionService:AddTag(viewport,"Viewport")
			self._ui:AddModelToViewport(viewport, petModel)
			self._janitor:Add(petCard)
		end
	end)
	
	self._chancesUI.Adornee = self._egg.PrimaryPart
	self._chancesUI.Parent = player.PlayerGui
	self._chancesUI.Enabled = true
end

function HatchingStand:Destroy(): nil
	self._janitor:Destroy()
end

return HatchingStand