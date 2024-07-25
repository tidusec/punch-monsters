--!native
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Players = game:GetService("Players")
local Sound = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local EggTemplate = require(ReplicatedStorage.Templates.EggTemplate)
local PetsTemplate = require(ReplicatedStorage.Templates.PetsTemplate)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Array = require(ReplicatedStorage.Modules.NewArray)
local Component = require(Packages.Component)
local Janitor = require(Packages.Janitor)

local UserInterface = ReplicatedStorage.Assets.UserInterface
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local characterRoot = character:WaitForChild("HumanoidRootPart")

local MAX_STAND_DISTANCE = 13

local HatchingStand: Component.Def = {
	Name = script.Name;
	IgnoreAncestors = { StarterGui };
	Guards = {
		Ancestors = { workspace:WaitForChild("Map1"):WaitForChild("Eggs"), workspace:WaitForChild("Map2"):WaitForChild("Eggs"), workspace:WaitForChild("Map3"):WaitForChild("Eggs") },
		ClassName = "Model",
		Children = {
			Egg = {
				ClassName = "Model",
				PrimaryPart = function(primary)
					return primary ~= nil
				end
			}
		}
	};
}

function HatchingStand:Initialize(): nil
	self._data = Knit.GetService("DataService")
	self._pets = Knit.GetService("PetService")
	self._boosts = Knit.GetService("BoostService")
	self._gamepass = Knit.GetService("GamepassService")
	self._dumbell = Knit.GetService("DumbellService")
	self._hatchingService = Knit.GetService("HatchingService")
	self._schedulercontroller = Knit.GetController("SchedulerController")
	self._ui = Knit.GetController("UIController")
	self._hatching = false
	
	local eggUi = player.PlayerGui.EggUi
	self._eggViewport = eggUi.EggViewport
	self._egg = self.Instance.Egg
	self._map = self.Instance.Parent.Parent.Name
	self._eggTemplate = EggTemplate[self._map][self.Instance.Name]

	self:AddToJanitor(self._hatchingService.PetHatched:Connect(function(pets, map, eggname): nil
		if eggname ~= self.Instance.Name or map ~= self._map then return end
		self:HatchAnimation(pets)
		return
	end))
	
	self:AddPetCards()
	self._chancesUI.Enabled = true
	return
end

function HatchingStand:HatchAnimation(pets)
	-- Ensure pets is a table
	if type(pets) == "string" then
		pets = {pets}
	end

	local janitor = Janitor.new()

	-- Initialize UI
	self._ui:SetScreen("EggUi", true)
	self._ui:SetHatching(true)
	self._chancesUI.Enabled = false

	local numPets = #pets
	local viewportFrames = {}

	-- Create viewport frames for each pet
	for i, pet in ipairs(pets) do
		local viewportFrame = Instance.new("ViewportFrame")
		janitor:Add(viewportFrame)
		viewportFrame.BackgroundTransparency = 1
		viewportFrame.Size = UDim2.new(1 / numPets, -10, 1, 0)
		viewportFrame.Position = UDim2.new((i - 1) / numPets, 5, 0, 0)
		viewportFrame.BackgroundTransparency = 1
		viewportFrame.Parent = self._eggViewport

		table.insert(viewportFrames, viewportFrame)

		local petModel = ReplicatedStorage.Assets.Pets:FindFirstChild(pet)
		if not petModel then
			self._hatching = false
			return warn(string.format("Could not find pet model \"%s\"", tostring(pet)))
		end

		local petTemplate = PetsTemplate[pet]
		if petTemplate.Rarity == "Legendary" then
			Sound.Master.LegendaryHatch:Play()
		end

		viewportFrame:SetAttribute("FitModel", false)
		viewportFrame:SetAttribute("FOV", 70)
		viewportFrame:SetAttribute("ModelRotation", 0)
		self._ui:AddModelToViewortNoRotation(viewportFrame, self._egg, { replaceModel = true })
	end

	-- Enhanced egg shaking animation with TweenService
	local TweenService = game:GetService("TweenService")
	for _, viewportFrame in ipairs(viewportFrames) do
		task.spawn(function()
			local shakeDuration = 1.5
			local startTime = tick()
			local originalPosition = viewportFrame.Position
			while tick() - startTime < shakeDuration do
				local shakeOffset = UDim2.new(0, math.random(-10, 10), 0, math.random(-10, 10))
				local tween = TweenService:Create(viewportFrame, TweenInfo.new(0.05, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut), { Position = originalPosition + shakeOffset })
				tween:Play()
				tween.Completed:Wait()
				task.wait(0.05)
			end
			viewportFrame.Position = originalPosition
		end)
	end

	-- Wait for shaking animation to finish
	task.wait(1.5)

	-- Add particle effects and smooth transitions to pet models
	for i, pet in ipairs(pets) do
		local viewportFrame = viewportFrames[i]
		local petModel = ReplicatedStorage.Assets.Pets:FindFirstChild(pet)

		-- Particle effects
		local particleEmitter = Instance.new("ParticleEmitter")
		particleEmitter.Texture = "rbxassetid://1454292685" -- Replace with actual particle texture ID
		particleEmitter.Rate = 100
		particleEmitter.Lifetime = NumberRange.new(0.5, 1)
		particleEmitter.Speed = NumberRange.new(5, 10)
		particleEmitter.Parent = viewportFrame

		-- Smooth transition to show pet model
		viewportFrame:SetAttribute("FitModel", true)
		viewportFrame:SetAttribute("FOV", 70)
		viewportFrame:SetAttribute("ModelRotation", 90)
		janitor:Add(self._ui:AddModelToFastViewport(viewportFrame, petModel, { replaceModel = true }))

		-- Lighting effect
		local pointLight = Instance.new("PointLight")
		pointLight.Brightness = 2
		pointLight.Range = 10
		pointLight.Parent = petModel.PrimaryPart

		-- Additional particle effects
		local burstEmitter = Instance.new("ParticleEmitter")
		burstEmitter.Texture = "rbxassetid://1454292685" -- Replace with actual burst texture ID
		burstEmitter.Rate = 0
		burstEmitter.Lifetime = NumberRange.new(0.2, 0.5)
		burstEmitter.Speed = NumberRange.new(20, 30)
		burstEmitter.Parent = viewportFrame
		burstEmitter:Emit(100)
	end

	-- Wait for pet animations to finish
	task.wait(3)

	-- Smoothly transition back to main UI
	self._ui:SetScreen("MainUi", false)
	self._ui:SetHatching(false)
	self._hatching = false
	self._chancesUI.Enabled = true

	-- Cleanup viewport frames to prevent grey screen
	for _, viewportFrame in ipairs(viewportFrames) do
		viewportFrame:Destroy()
	end

	janitor:Cleanup()
end



function HatchingStand:Hatch(amount :number): nil
	assert(type(amount) == "number", "Amount must be a number")
	assert(amount > 0, "Amount must be greater than 0")
	if self._dumbell:IsEquipped() then return end
	if self._hatching then return end
	self._hatching = true

	if amount == 1 then
		self._hatchingService:Hatch(self._map, self.Instance.Name)
	else
		self._hatchingService:HatchMany(self._map, self.Instance.Name, amount)
	end
	
	task.wait(0.5)
	self._hatching = false
	return
end

function HatchingStand:BuyOne(): nil
	if not self:IsClosest() then return end
	self:Hatch(1)
	return
end

function HatchingStand:BuyThree(): nil
	if not self:IsClosest() then return end
	self:Hatch(3)
	return
end

function HatchingStand:Auto(): nil
	if not self:IsClosest() then return end
	while self._hatching do
		self:Hatch(3)
		task.wait(1)
	end
	return
end

local function getDistanceFromPlayer(stand: Model & { Egg: Model }): number
	local primaryPart = stand.Egg.PrimaryPart
	return if primaryPart then (primaryPart.Position - characterRoot.Position).Magnitude else 1000
end

function HatchingStand:GetClosest(): Model & { Egg: Model }
	local closestStand = Array.new("Instance", CollectionService:GetTagged(self.Name))
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
		
	return closestStand
end

function HatchingStand:IsClosest(): boolean
	local closestStand = self:GetClosest()
	return closestStand == self.Instance
end

function HatchingStand:AddPetCards(): nil
	self._chancesUI = UserInterface.Hatching.HatchingUi:Clone()
	self._chancesUI.Enabled = true
	
	local container: Frame = self._chancesUI.Background.PetChances
	task.spawn(function()
		local pets = Array.new("table")
		type ChanceTable = {
			Name: string;
			Chance: number;
		}

		local chances: { [string]: number } = self._eggTemplate.Chances
		for pet, chance in pairs(chances) do
			pets:Push({
				Name = pet, 
				Chance = chance
			})
		end
		
		pets:Sort(function(a: ChanceTable, b: ChanceTable)
			return a.Chance > b.Chance
		end)
		
		for _, pet in pets:GetValues() do
			self._chancesUI.Enabled = true
			local petModel: Model? = ReplicatedStorage.Assets.Pets:FindFirstChild(pet.Name)		
			local petCard: ImageLabel & { Viewport: ViewportFrame; Chance: TextLabel } = UserInterface.Hatching.PetChanceCard:Clone()
			local viewport = petCard.Viewport
			petCard.Chance.Text = `{pet.Chance}%`
			petCard.Parent = container
			
			local Viewport = Component.Get("Viewport")
			Viewport:Add(viewport)
			self._ui:AddModelToViewport(viewport, petModel)
			self:AddToJanitor(petCard)
		end
	end)
	
	self._chancesUI.Background.BuyOne.MouseButton1Click:Connect(function()
		self:BuyOne()
	end)
	self._chancesUI.Background.BuyThree.MouseButton1Click:Connect(function()
		self:BuyThree()
	end)
	self._chancesUI.Background.Auto.MouseButton1Click:Connect(function()
		self:Auto()
	end)
	self._chancesUI.Adornee = self._egg.PrimaryPart
	self._chancesUI.Parent = player.PlayerGui
	self._chancesUI.Enabled = true



	self._schedulercontroller:Every("0.33s", function()
		if not self:IsClosest() then
			self._chancesUI.Enabled = false
		else
			if self._ui:GetHatching() then self._chancesUI.Enabled = false return end
			self._chancesUI.Enabled = true
		end
	end)
	return
end

return Component.new(HatchingStand)