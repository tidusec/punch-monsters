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

local ServerStand: Component.Def = {
	Name = script.Name;
	IgnoreAncestors = { StarterGui };
	Guards = {
		Ancestors = { workspace:WaitForChild("Server"):WaitForChild("Eggs") },
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

function ServerStand:Initialize(): nil
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
	return
end

function ServerStand:HatchAnimation(pets)
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

return Component.new(ServerStand)