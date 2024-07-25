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

	self:AddToJanitor(self._hatchingService.PetHatched:Connect(function(pets, map, eggname): nil
		if eggname ~= self.Instance.Name or map ~= self._map then return end
		self:HatchAnimation(pets)
		return
	end))
	return
end

function ServerStand:HatchAnimation(pets)
    if type(pets) == "string" then
        pets = {pets}
    end

    local janitor = Janitor.new()
    local TweenService = game:GetService("TweenService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    self._ui:SetScreen("EggUi", true)
    self._ui:SetHatching(true)

    local numPets = #pets
    local viewportFrames = {}

    -- Create viewport frames for each pet
    for i, pet in ipairs(pets) do
        local viewportFrame = Instance.new("ViewportFrame")
        janitor:Add(viewportFrame)
        viewportFrame.BackgroundTransparency = 1
        viewportFrame.Size = UDim2.new(1 / numPets, -10, 1, 0)
        viewportFrame.Position = UDim2.new((i - 1) / numPets, 5, 0, 0)
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

    -- Egg pulsing and sparkling animation
    local function pulseEgg(viewportFrame)
        local originalSize = viewportFrame.Size
        local sparkles = Instance.new("ParticleEmitter")
        sparkles.Texture = "rbxassetid://6333823"  -- Sparkle texture
        sparkles.Size = NumberSequence.new(0.1, 0.5)
        sparkles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
        sparkles.Speed = NumberRange.new(1, 3)
        sparkles.Lifetime = NumberRange.new(0.5, 1)
        sparkles.Rate = 20
        sparkles.Parent = viewportFrame

        local function scaleUDim2(udim2, scale)
            return UDim2.new(
                udim2.X.Scale * scale, udim2.X.Offset * scale,
                udim2.Y.Scale * scale, udim2.Y.Offset * scale
            )
        end

        local pulseTween = TweenService:Create(viewportFrame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Size = scaleUDim2(originalSize, 1.05)
        })
        pulseTween:Play()

        return function()
            pulseTween:Cancel()
            sparkles:Destroy()
            viewportFrame.Size = originalSize
        end
    end

    local stopPulsing = {}
    for _, viewportFrame in ipairs(viewportFrames) do
        table.insert(stopPulsing, pulseEgg(viewportFrame))
    end

    -- Dramatic pause
    task.wait(2)

    -- Egg hatching animation
    local function hatchEgg(viewportFrame)
        local hatchEffect = Instance.new("ParticleEmitter")
        hatchEffect.Texture = "rbxassetid://6333823"  -- Sparkle texture
        hatchEffect.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
        hatchEffect.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
        hatchEffect.Speed = NumberRange.new(5, 10)
        hatchEffect.Lifetime = NumberRange.new(0.5, 1)
        hatchEffect.Rate = 100
        hatchEffect.Parent = viewportFrame

        local crackSound = Instance.new("Sound")
        crackSound.SoundId = "rbxassetid://5771441412"
        crackSound.Parent = viewportFrame
        crackSound:Play()

        local shakeDuration = 1
        local startTime = tick()
        local originalPosition = viewportFrame.Position
        while tick() - startTime < shakeDuration do
            local shakeOffset = UDim2.new(0, math.random(-3, 3), 0, math.random(-3, 3))
            TweenService:Create(viewportFrame, TweenInfo.new(0.05, Enum.EasingStyle.Sine), {Position = originalPosition + shakeOffset}):Play()
            task.wait(0.05)
        end
        viewportFrame.Position = originalPosition

        task.wait(0.5)
        hatchEffect:Destroy()
    end

    for _, viewportFrame in ipairs(viewportFrames) do
        hatchEgg(viewportFrame)
    end

    -- Stop pulsing animation
    for _, stopPulse in ipairs(stopPulsing) do
        stopPulse()
    end

    -- Reveal pet with sparkle burst
    for i, pet in ipairs(pets) do
        local viewportFrame = viewportFrames[i]
        local petModel = ReplicatedStorage.Assets.Pets:FindFirstChild(pet)

        local burstEffect = Instance.new("ParticleEmitter")
        burstEffect.Texture = "rbxassetid://6333823"  -- Sparkle texture
        burstEffect.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
        burstEffect.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
        burstEffect.Speed = NumberRange.new(10, 20)
        burstEffect.Lifetime = NumberRange.new(0.5, 1)
        burstEffect.Rate = 0
        burstEffect.Parent = viewportFrame
        burstEffect:Emit(100)

        viewportFrame:SetAttribute("FitModel", true)
        viewportFrame:SetAttribute("FOV", 70)
        viewportFrame:SetAttribute("ModelRotation", 90)
        janitor:Add(self._ui:AddModelToFastViewport(viewportFrame, petModel, { replaceModel = true }))

        local rotationTween = TweenService:Create(viewportFrame, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1), {
            Rotation = 360
        })
        rotationTween:Play()

        local sparkles = Instance.new("ParticleEmitter")
        sparkles.Texture = "rbxassetid://6333823"  -- Sparkle texture
        sparkles.Size = NumberSequence.new(0.1, 0.3)
        sparkles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
        sparkles.Speed = NumberRange.new(1, 3)
        sparkles.Lifetime = NumberRange.new(1, 2)
        sparkles.Rate = 20
        sparkles.Parent = viewportFrame
    end

    -- Celebration sound
    local celebrationSound = Instance.new("Sound")
    celebrationSound.SoundId = "rbxassetid://6333015935"
    celebrationSound.Parent = self._eggViewport
    celebrationSound:Play()

    -- Wait for pet animations to finish
    task.wait(5)

    -- Smoothly transition back to main UI
    self._ui:SetScreen("MainUi", false)
    self._ui:SetHatching(false)
    self._hatching = false

    -- Cleanup viewport frames
    for _, viewportFrame in ipairs(viewportFrames) do
        viewportFrame:Destroy()
    end

    janitor:Destroy()
end

return Component.new(ServerStand)