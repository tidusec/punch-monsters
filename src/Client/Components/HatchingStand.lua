--!native
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Sound = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local EggTemplate = require(ReplicatedStorage.Templates.EggTemplate)
local PetsTemplate = require(ReplicatedStorage.Templates.PetsTemplate)

local RarityStrokes = ReplicatedStorage.Assets.UIStrokes.Rarities

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
    self._janitor = Janitor.new()
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

    self._janitor:Add(self._hatchingService.PetHatched:Connect(function(pets, map, eggname): nil
        if eggname ~= self.Instance.Name or map ~= self._map then return end
        self:HatchAnimation(pets)
    end))
    
    self:AddPetCards()
    self._chancesUI.Enabled = true
    return nil
end

function HatchingStand:HatchAnimation(pets)
    if type(pets) == "string" then
        pets = {pets}
    end

    self._animationjanitor = Janitor.new()
    local animationCompleted = false

    self._ui:SetScreen("EggUi", true)
    self._ui:SetHatching(true)

    self._chancesUI.Enabled = false

    local numPets = #pets
    local viewportFrames = {}

    local rows = math.min(2, math.floor(numPets / 4) + 1)
    local cols = math.min(4, math.ceil(numPets / rows))
    local viewportSize = UDim2.new(1 / cols, -10, (1 / rows)/1.3, -10)

    local crackSound = Instance.new("Sound")
    crackSound.SoundId = "rbxassetid://14657667490"
    crackSound.Parent = self._eggViewport
    crackSound:Play()

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

    task.wait(1) -- Reduced wait time

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

            local shakeDuration = 0.5 -- Reduced shake duration
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
            task.wait(0.8) -- Reduced wait time
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

    animationCompleted = true

    task.wait(2) -- Reduced wait time
    crackSound:Destroy()

    self:FinishHatchAnimation()
end

function HatchingStand:CreatePetInfoFrame(viewportFrame, pet, petInfo)
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
    nameLabel.Position = UDim2.new(0, 0, 0.6, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Text = pet
    nameLabel.Parent = infoFrame

    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(1, 0, 0.2, 0)
    rarityLabel.Position = UDim2.new(0, 0, 1, 0)
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
    RarityStrokes:FindFirstChild("UIStrokeHatch"):Clone().Parent = rarityLabel
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

function HatchingStand:FinishHatchAnimation()

    self._ui:SetScreen("MainUi", false)
    self._ui:SetHatching(false)
    self._hatching = false

    self._chancesUI.Enabled = true

    self._animationjanitor:Destroy()
end

function HatchingStand:Hatch(amount: number): nil
    assert(type(amount) == "number", "Amount must be a number")
    assert(amount > 0, "Amount must be greater than 0")
    if self._dumbell:IsEquipped() or self._hatching then return end
    self._hatching = true

    if ReplicatedStorage:FindFirstChild("PetCounter") then
       if ReplicatedStorage.PetCounter.Value >= ReplicatedStorage.MaxPets.Value then
           self._ui:ShowError("You have reached the pet limit!")
           self.hatchingauto = nil
           self._hatching = false
           return
       end 
    end

    if amount == 1 then
        self._hatchingService:Hatch(self._map, self.Instance.Name)
    else
        self._hatchingService:HatchMany(self._map, self.Instance.Name, amount)
    end
    
    task.wait(0.5)
    self._hatching = false
    return nil
end

function HatchingStand:BuyOne(): nil
    if not self:IsClosest() then return end
    self:Hatch(1)
    return nil
end

function HatchingStand:BuyThree(): nil
    if not self:IsClosest() then return end
    if self._gamepass:DoesPlayerOwn("3x Hatch") then
        self:Hatch(3)
        return nil
    else
        self._gamepass:PromptPurchase("3x Hatch")
    end
    return nil
end

function HatchingStand:BuyEight(): nil
    if not self:IsClosest() then return end
    if self._gamepass:DoesPlayerOwn("8x Hatch") then
        self:Hatch(8)
        return nil
    else
        game:GetService("MarketplaceService"):PromptProductPurchase(player, 1890693814)
    end
end

function HatchingStand:Auto(): nil
    self.hatchingauto = true
    if not self:IsClosest() then return end
    while self.hatchingauto do
        self:Hatch(8)
        repeat task.wait(0.5) until not self._hatching
        task.wait(6)
    end
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    local connection
    connection = root:GetPropertyChangedSignal("Position"):Connect(function()
        self.hatchingauto = nil
        connection:Disconnect()
    end)
    return nil
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
            local petModel: Model? = ReplicatedStorage.Assets.Pets:WaitForChild(pet.Name, 5) 
            local petCard: ImageLabel & { Viewport: ViewportFrame; Chance: TextLabel } = UserInterface.Hatching.PetChanceCard:Clone()
            local viewport = petCard.Viewport
            petCard.Chance.Text = string.format("%.2f%%", pet.Chance)
            petCard.Parent = container
            
            local Viewport = Component.Get("Viewport")
            Viewport:Add(viewport)
            
            if not petModel then
                warn(string.format("Could not find pet model \"%s\"", tostring(pet.Name)))
                continue
            end
            
            self._ui:AddModelToViewportNoRotation(viewport, petModel, { replaceModel = true })
            self._janitor:Add(petCard)
        end
    end)
    
    self._chancesUI.Background.BuyOne.MouseButton1Click:Connect(function()
        self:BuyOne()
    end)
    self._chancesUI.Background.BuyThree.MouseButton1Click:Connect(function()
        self:BuyThree()
    end)
    self._chancesUI.Background.BuyEight.MouseButton1Click:Connect(function()
        self:BuyEight()
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
            if self._ui:GetHatching() then 
                self._chancesUI.Enabled = false 
                return 
            end
            self._chancesUI.Enabled = true
        end
    end)
    return nil
end

function HatchingStand:Destroy()
    self._janitor:Destroy()
end

return Component.new(HatchingStand)