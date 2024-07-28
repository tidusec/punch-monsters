--!native
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

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

local RarityStrokes = ReplicatedStorage.Assets.UIStrokes.Rarities


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

    self._animationjanitor = Janitor.new()
    local animationCompleted = false

    self._ui:SetScreen("EggUi", true)
    self._ui:SetHatching(true)

    local numPets = #pets
    local viewportFrames = {}

    local rows = math.floor(numPets / 4)
    local cols = math.ceil(numPets / rows)
    local viewportSize = UDim2.new(1 / cols, -10, (1 / rows)/1.3, -10)

    for i, pet in ipairs(pets) do
        local viewportFrame = Instance.new("ViewportFrame")
        self._animationjanitor:Add(viewportFrame)
        viewportFrame.BackgroundTransparency = 1
        viewportFrame.Size = viewportSize
        
        local column = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        viewportFrame.Position = UDim2.new(column / cols, 5, row / rows, 5)
        
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
        self._ui:AddModelToViewportNoRotation(viewportFrame, self._egg, { replaceModel = true })
    end

    local function pulseEgg(viewportFrame)
        local originalSize = viewportFrame.Size
        local sparkles = Instance.new("ParticleEmitter")
        sparkles.Texture = "rbxassetid://6333823"
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

    task.wait(2)

    local function hatchEgg(viewportFrame)
        task.spawn(function()
            local hatchEffect = Instance.new("ParticleEmitter")
            hatchEffect.Texture = "rbxassetid://6333823"
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
            task.spawn(function()
                while tick() - startTime < shakeDuration do
                    local shakeOffset = UDim2.new(0, math.random(-3, 3), 0, math.random(-3, 3))
                    TweenService:Create(viewportFrame, TweenInfo.new(0.05, Enum.EasingStyle.Sine), {Position = originalPosition + shakeOffset}):Play()
                    task.wait(0.05)
                end
                viewportFrame.Position = originalPosition
            end)
            task.wait(1.3)
            hatchEffect:Destroy()
        end)
    end

    for _, viewportFrame in ipairs(viewportFrames) do
        hatchEgg(viewportFrame)
    end

    for _, stopPulse in ipairs(stopPulsing) do
        stopPulse()
    end

    for i, pet in ipairs(pets) do
        local viewportFrame = viewportFrames[i]
        local petModel = ReplicatedStorage.Assets.Pets:FindFirstChild(pet)

        local burstEffect = Instance.new("ParticleEmitter")
        burstEffect.Texture = "rbxassetid://6333823"
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
        self._animationjanitor:Add(self._ui:AddModelToFastViewport(viewportFrame, petModel, { replaceModel = true }))

        local rotationTween = TweenService:Create(viewportFrame, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1), {
            Rotation = 360
        })
        rotationTween:Play()

        local sparkles = Instance.new("ParticleEmitter")
        sparkles.Texture = "rbxassetid://6333823"
        sparkles.Size = NumberSequence.new(0.1, 0.3)
        sparkles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
        sparkles.Speed = NumberRange.new(1, 3)
        sparkles.Lifetime = NumberRange.new(1, 2)
        sparkles.Rate = 20
        sparkles.Parent = viewportFrame

        local petInfo = PetsTemplate[pet]
        if petInfo then
            self._animationjanitor:Add(self:CreatePetInfoFrame(viewportFrame, pet, petInfo))
        end
    end

    local celebrationSound = Instance.new("Sound")
    celebrationSound.SoundId = "rbxassetid://6333015935"
    celebrationSound.Parent = self._eggViewport
    celebrationSound:Play()

    animationCompleted = true

    task.wait(3)

    self:FinishHatchAnimation()
end

function ServerStand:CreatePetInfoFrame(viewportFrame, pet, petInfo)
    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(viewportFrame.Size.X.Scale, viewportFrame.Size.X.Offset, 0.15, 0)
    infoFrame.Position = UDim2.new(
        viewportFrame.Position.X.Scale, 
        viewportFrame.Position.X.Offset, 
        viewportFrame.Position.Y.Scale + viewportFrame.Size.Y.Scale  - 0.2, 
        viewportFrame.Position.Y.Offset + viewportFrame.Size.Y.Offset
    )
    infoFrame.BackgroundTransparency = 1
    infoFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    infoFrame.Parent = viewportFrame.Parent

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0.1, 0)
    uiCorner.Parent = infoFrame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Text = pet
    nameLabel.Parent = infoFrame

    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, 0, 0.5, 0)
    rarityLabel.Position = UDim2.new(0, 0, 0.5, 0)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.TextColor3 = Color3.new(1, 1, 1)
    rarityLabel.Font = Enum.Font.Gotham
    rarityLabel.TextScaled = true
    rarityLabel.Text = petInfo.Rarity
    if RarityStrokes:FindFirstChild(petInfo.Rarity) then
        RarityStrokes:FindFirstChild(petInfo.Rarity):Clone().Parent = rarityLabel
    else
        RarityStrokes:FindFirstChild("Common"):Clone().Parent = rarityLabel
    end
    RarityStrokes:FindFirstChild("UIStroke"):Clone().Parent = rarityLabel
    rarityLabel.Parent = infoFrame

    local function fadeInText(label)
        label.TextTransparency = 1
        local tween = TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 0
        })
        tween:Play()
    end

    fadeInText(nameLabel)
    task.wait(0.3)
    fadeInText(rarityLabel)

    return infoFrame
end

function ServerStand:FinishHatchAnimation()

    self._ui:SetScreen("MainUi", false)
    self._ui:SetHatching(false)
    self._hatching = false

    self._animationjanitor:Destroy()
end

return Component.new(ServerStand)