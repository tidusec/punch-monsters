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

local UserInterface = ReplicatedStorage.Assets.UserInterface
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local characterRoot = character:WaitForChild("HumanoidRootPart")

local MAX_STAND_DISTANCE = 5

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
	self._ui = Knit.GetController("UIController")
	self._hatching = false
	
	local eggUi = player.PlayerGui.EggUi
	self._eggViewport = eggUi.EggViewport
	self._egg = self.Instance.Egg
	self._map = self.Instance.Parent.Parent.Name
	self._eggTemplate = EggTemplate[self._map][self.Instance.Name]

	self:AddToJanitor(self._hatchingService.PetHatched:Connect(function(pets): nil
		self:HatchAnimation(pets)
		return
	end))
	
	self:AddPetCards()
	self._chancesUI.Enabled = true
	return
end

function HatchingStand:HatchAnimation(pets)
    if type(pets) == "string" then
        pets = Array.new("string", { pets })
    end

    self._ui:SetScreen("EggUi", true)

    for _, pet in pets do
        local petModel = ReplicatedStorage.Assets.Pets:FindFirstChild(pet)
        if not petModel then
            self._hatching = false
            return warn(string.format("Could not find pet model \"%s\"", pet))
        end

        local petTemplate = PetsTemplate[pet]
        if petTemplate.Rarity == "Legendary" then
            Sound.Master.LegendaryHatch:Play()
        end

        self._eggViewport:SetAttribute("FitModel", false)
        self._eggViewport:SetAttribute("FOV", nil :: any)
        self._eggViewport:SetAttribute("ModelRotation", 0 :: any)
        self._ui:AddModelToViewport(self._eggViewport, self._egg, { replaceModel = true })

        -- Wait for the initial setup before showing the pet model
        task.wait(1.5)

        self._eggViewport:SetAttribute("FitModel", true)
        self._eggViewport:SetAttribute("FOV", 15 :: any)
        self._eggViewport:SetAttribute("ModelRotation", -120 :: any)
        self._ui:AddModelToViewport(self._eggViewport, petModel, { replaceModel = true })

        -- Wait for the pet's animation to finish before continuing to the next pet
        task.wait(1.5)
    end

    -- No need to wait here anymore as the last pet's animation wait is included in the loop
    self._ui:SetScreen("MainUi", false)

    self._hatching = false
    self._chancesUI.Enabled = true
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
	-- do stuff
	return
end

local function getDistanceFromPlayer(stand: Model & { Egg: Model }): number
	local primaryPart = stand.Egg.PrimaryPart
	return if primaryPart then (primaryPart.Position - characterRoot.Position).Magnitude else 1000
end

function HatchingStand:IsClosest(): boolean
	local closestStand= Array.new("Instance", CollectionService:GetTagged(self.Name))
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
	
	self._chancesUI.Adornee = self._egg.PrimaryPart
	self._chancesUI.Parent = player.PlayerGui
	self._chancesUI.Enabled = true
	return
end

return Component.new(HatchingStand)