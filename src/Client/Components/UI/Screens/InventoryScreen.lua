--!native
--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tween = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local PetsTemplate = require(ReplicatedStorage.Templates.PetsTemplate)
local Packages = ReplicatedStorage.Packages
local Assets = ReplicatedStorage.Assets

local RarityStrokes = ReplicatedStorage.Assets.UIStrokes.Rarities

local Knit = require(Packages.Knit)
local Janitor = require(Packages.Janitor)
local Component = require(Packages.Component)

local player = Players.LocalPlayer

type Pet = typeof(PetsTemplate.Dog) & { Name: string }
local InventoryScreen: Component.Def = {
	Name = script.Name;
	IgnoreAncestors = { StarterGui };
	Guards = {
		ClassName = "ScreenGui",
		Ancestors = { player.PlayerGui },
		Children = {
			Background = {
				ClassName = "ImageLabel",
				Children = {
					Stats = { ClassName = "ImageLabel" },
					Pets = { ClassName = "ScrollingFrame" }
				}
			},
		}
	};
}

function InventoryScreen:Initialize(): nil
	self._data = Knit.GetService("DataService")
	self._pets = Knit.GetService("PetService")
	self._ui = Knit.GetController("UIController")
	self._canDelete = false
	self._petToDelete = nil

	local background: ImageLabel & { Pets: ScrollingFrame; Stats: ImageLabel } = self.Instance.Background
	self._background = background
	self._container = self._background.Pets
	self._petStats = background.Stats
	self._petStats.Visible = false
	self.petsInventory = nil
	self._sorting = "None"
	
	self._updateJanitor = Janitor.new()
	self:AddToJanitor(self._data.DataUpdated:Connect(function(key, value)
		if key ~= "Pets" then return end
		self.petsInventory = value
		self:UpdatePetCards(value)
	end))

	self:AddToJanitor(self._background.EquipBest.MouseButton1Click:Connect(function()
		self._pets:EquipBest()
	end))

	self:AddToJanitor(self._background.UnequipAll.MouseButton1Click:Connect(function()
		self._pets:UnequipAll()
	end))

	self:AddToJanitor(self._background.Sort.MouseButton1Click:Connect(function()
		if self._sorting == "None" then
			self._sorting = "Rarity"
			self._background.Sort.TextLabel.Text = "Sort: Rarity"
		elseif self._sorting == "Rarity" then
			self._sorting = "Strength"
			self._background.Sort.TextLabel.Text = "Sort: Strength"
		elseif self._sorting == "Strength" then
			self._sorting = "Name"
			self._background.Sort.TextLabel.Text = "Sort: Name"
		elseif self._sorting == "Name" then
			self._sorting = "None"
			self._background.Sort.TextLabel.Text = "Sort: None"
		end

		self:UpdatePetCards()
	end))

	self:AddToJanitor(self._background.Delete.MouseButton1Click:Connect(function()
		if self._canDelete then
			if not self._petToDelete then return end
			self._pets:Delete(self._petToDelete)
		end
	end))
	return
end

function InventoryScreen:ToggleSelectionFrame(on: boolean): nil
	local backgroundPosition = self._background:GetAttribute(if on then "OpenedPosition" else "ClosedPosition")
	local statsPosition = self._petStats:GetAttribute(if on then "OpenedPosition" else "ClosedPosition")
	local info = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
	
	if on then
		self._petStats.Visible = true
	end
	
	Tween:Create(self._background, info, {
		Position = backgroundPosition
	}):Play()
	local t = Tween:Create(self._petStats, info, {
		Position = statsPosition
	})

	t.Completed:Once(function()
		self._petStats.Visible = on
	end)
	t:Play()
	return
end

local lastPetSelected
local selectionJanitor = Janitor.new()
local function toggleButton(button: ImageButton & { Title: TextLabel & { UIGradient: UIGradient } }, on: boolean): nil
	task.spawn(function()
		button.Image = button:GetAttribute(if on then "OnImage" else "OffImage")
		button.Title.UIGradient.Color = button:GetAttribute(if on then "OnColor" else "OffColor")
		button.Title.Text = if on then "Equip" else "Unequip"
	end)
	return
end

function InventoryScreen:SelectPet(pet: Pet): nil
	selectionJanitor:Cleanup()
	if lastPetSelected == pet then
		lastPetSelected = nil
		self._canDelete = false
		return self:ToggleSelectionFrame(false)
	else
		self._canDelete = true
	end
	self._petToDelete = pet
	lastPetSelected = pet :: any
	
	local isEquipped = self._pets:IsEquipped(pet)
	toggleButton(self._petStats.Equip, not isEquipped)
	
	task.spawn(function(): nil
		self._petStats.PetName.Text = pet.Name
		self._petStats.Rarity.Text = pet.Rarity
		self._petStats.Rarity:ClearAllChildren()
		if RarityStrokes:FindFirstChild(pet.Rarity) then
			local clone = RarityStrokes:FindFirstChild(pet.Rarity):Clone()
			clone.Parent = self._petStats.Rarity
			clone.Name = "RarityStroke"
		else
			local clone = RarityStrokes:FindFirstChild("Common"):Clone()
			clone.Parent = self._petStats.Rarity
			clone.Name = "RarityStroke"
		end
		RarityStrokes:FindFirstChild("UIStroke"):Clone().Parent = self._petStats.Rarity
		self._petStats.Strength.Text = `{pet.StrengthMultiplier}x`

		if pet.Rarity == "Huge" then
			self._petStats.Stars.Huge.Visible = true
		else
			self._petStats.Stars.Huge.Visible = false
		end

		if pet["Limited"] then
			self._petStats.Stars.Limited.Visible = true
		else
			self._petStats.Stars.Limited.Visible = false
		end

		
		local petModel = Assets.Pets:FindFirstChild(pet.Name)
		if not petModel then
			return warn(`Could not find pet model "{pet.Name}"`)
		end
		
		selectionJanitor:Add(self._ui:AddModelToViewport(self._petStats.Viewport, petModel, { replaceModel = true }))
		return self:ToggleSelectionFrame(true)
	end)
	
	selectionJanitor:Add(self._petStats.Equip.MouseButton1Click:Connect(function()
		local isEquipped = self._pets:IsEquipped(pet)
		toggleButton(self._petStats.Equip, isEquipped)
		
		if isEquipped then
			self._pets:Unequip(pet)
		else
			self._pets:Equip(pet)
		end
	end))
	selectionJanitor:Add(self._petStats.Lock.MouseButton1Click:Connect(function()

	end))
	return
end

function InventoryScreen:Height(card_amount: number): number
	local rows = math.ceil(card_amount / 5)
	local a = -0.0001714  -- Fitted coefficient
	local b = -0.01133    -- Fitted coefficient
	local c = 0.2491      -- Fitted coefficient
	local height = a * math.pow(rows, 2) + b * rows + c
	return height
end

if not ReplicatedStorage:FindFirstChild("CACHE") then
    local cache = Instance.new("Folder")
    cache.Name = "CACHE"
    cache.Parent = ReplicatedStorage
end

local CACHE = ReplicatedStorage.CACHE


function InventoryScreen:UpdatePetCards(pets, sorting)
    pets = pets or self.petsInventory
    sorting = sorting or self._sorting or "None"

    self._updateJanitor:Cleanup()
    local ownedPets = pets.OwnedPets
    local equippedPets = {}
    for _, pet in ipairs(pets.Equipped) do
        equippedPets[pet.ID] = true
    end

    local sortedPets = {}
    for _, pet in pairs(ownedPets) do
        table.insert(sortedPets, pet)
    end

    local function isEquipped(petID)
        return equippedPets[petID] or false
    end

    table.sort(sortedPets, function(a, b)
        local aEquipped = isEquipped(a.ID)
        local bEquipped = isEquipped(b.ID)

        if aEquipped ~= bEquipped then
            return aEquipped and not bEquipped
        end

        if sorting == "Rarity" then
            local rarityOrder = {
                Common = 1,
                Uncommon = 2,
                Rare = 3,
                Epic = 4,
                Legendary = 5,
                Huge = 6
            }
            return rarityOrder[a.Rarity] > rarityOrder[b.Rarity]
        elseif sorting == "Strength" then
            return a.StrengthMultiplier > b.StrengthMultiplier
        elseif sorting == "Name" then
            if a.Name ~= b.Name then
                return a.Name < b.Name
            else
                if a.Rarity ~= b.Rarity then
                    local rarityOrder = {
                        Common = 1,
                        Uncommon = 2,
                        Rare = 3,
                        Epic = 4,
                        Legendary = 5,
                        Huge = 6
                    }
                    return rarityOrder[a.Rarity] > rarityOrder[b.Rarity]
                else
                    return a.StrengthMultiplier > b.StrengthMultiplier
                end
            end
        end

        return false
    end)

    coroutine.wrap(function()
        for _, pet in ipairs(sortedPets) do
            local card = Assets.UserInterface.Inventory.PetCard:Clone()
            card.StrengthMultiplier.Text = `{pet.StrengthMultiplier}x`
            card.Parent = self._container.Frame

            if pet.Rarity == "Huge" then
                card.Stars.Huge.Visible = true
            else
                card.Stars.Huge.Visible = false
            end

            if pet["Limited"] then
                card.Stars.Limited.Visible = true
            else
                card.Stars.Limited.Visible = false
            end

            local Viewport = Component.Get("Viewport")
            Viewport:Add(card.Viewport)
            card.Equipped.Visible = equippedPets[pet.ID]

			if not CACHE:FindFirstChild(pet.Name) then
				self._ui:AddModelToViewportNoRotation(card.Viewport, Assets.Pets[pet.Name], { replaceModel = true })
				task.delay(2, function()
					if card:FindFirstChild("Viewport") then
						if CACHE:FindFirstChild(pet.Name) then
							return
						end
						local clone = card.Viewport:Clone()
						clone.Parent = CACHE
						clone.Name = pet.Name
					end
				end)
			else
				card.Viewport:Destroy()
				local clone = CACHE:FindFirstChild(pet.Name):Clone()
				clone.Parent = card
			end

            self._updateJanitor:Add(card)
            self._updateJanitor:Add(card.MouseButton1Click:Connect(function()
                self:SelectPet(pet)
            end))

            task.wait()
        end
    end)()

    self._background.Equipped.Text = tostring(#pets.Equipped).."/"..tostring(pets.MaxEquip or 4)
    self._background.Storage.Text = tostring(#pets.OwnedPets).."/"..(tostring(pets.MaxStorage) or "200")

	if not ReplicatedStorage:FindFirstChild("PetCounter") then
		local counter = Instance.new("IntValue")
		counter.Name = "PetCounter"
		counter.Parent = ReplicatedStorage
	end

	if not ReplicatedStorage:FindFirstChild("MaxPets") then
		local maxPets = Instance.new("IntValue")
		maxPets.Name = "MaxPets"
		maxPets.Parent = ReplicatedStorage
	end

	ReplicatedStorage.PetCounter.Value = #pets.OwnedPets
	ReplicatedStorage.MaxPets.Value = pets.MaxStorage
    return
end



return Component.new(InventoryScreen)