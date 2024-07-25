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

	self:AddToJanitor(self._background.Sort.MouseButton1Click:Connect(function()
		if self._sorting == "None" then
			self._sorting = "Rarity"
		elseif self._sorting == "Rarity" then
			self._sorting = "Strength"
		elseif self._sorting == "Strength" then
			self._sorting = "Name"
		elseif self._sorting == "Name" then
			self._sorting = "None"
		end

		self:AddPetCards()
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
		self._petStats.Strength.Text = `{pet.StrengthMultiplier}x`

		if pet.Rarity == "Huge" then
			self._petStats.Stars.Huge.Visible = true
		end

		if pet["Limited"] then
			self._petStats.Stars.Limited.Visible = true
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

function InventoryScreen:UpdatePetCards(pets, sorting): nil
	pets = pets or self.petsInventory
	sorting = sorting or self._sorting or "None" --// None, Rarity, Strength, Name

	self._updateJanitor:Cleanup()
	local ownedPets: { [string]: Pet } = pets.OwnedPets

	for _, pet in pairs(ownedPets) do
		task.spawn(function()
			local card: ImageButton & { Viewport: ViewportFrame; StrengthMultiplier: TextLabel } = Assets.UserInterface.Inventory.PetCard:Clone()
			card.StrengthMultiplier.Text = `{pet.StrengthMultiplier}x`
			card.Parent = self._container.Frame

			if pet.Rarity == "Huge" then
				card.Stars.Huge.Visible = true
			end

			if pet["Limited"] then
				card.Stars.Limited.Visible = true
			end
			
			local Viewport = Component.Get("Viewport")
			Viewport:Add(card.Viewport)
			if self._pets:IsEquipped(pet) then
				card.Equipped.Visible = true
			else
				card.Equipped.Visible = false
			end
			self._ui:AddModelToViewport(card.Viewport, Assets.Pets[pet.Name])
			self._updateJanitor:Add(card)
			self._updateJanitor:Add(card.MouseButton1Click:Connect(function()
				self:SelectPet(pet)
			end))
		end)
	end

	self._background.Equipped.Text = tostring(#pets.Equipped).."/"..tostring(pets.MaxEquip)
	self._background.Storage.Text = tostring(#pets.OwnedPets).."/"..(tostring(pets.MaxStorage) or "200")

	return
end

return Component.new(InventoryScreen)