--!native
--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

local Modules = ServerScriptService.Server.Modules
local AssertPlayer = require(Modules.AssertPlayer)

local PetsTemplate = require(ReplicatedStorage.Templates.PetsTemplate)
local Welder = require(ReplicatedStorage.Modules.Welder)
local VerifyID = require(ReplicatedStorage.Modules.VerifyID)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Janitor = require(Packages.Janitor)
local Array = require(ReplicatedStorage.Modules.NewArray)
local ProfileTemplate = require(ReplicatedStorage.Templates.ProfileTemplate)

local FOLLOW_SPEED = 12
local Y_OFFSET = 0
local MAX_PETS = 10 -- Assuming the maximum number of pets a player can have
local BASE_RADIUS = 10 -- The radius of the circle around the player
local Y_OFFSET = 1 -- Height offset from the player

local PetService = Knit.CreateService {
	Name = "PetService";
	Client = {};
}

local lastEquippedPlayerPets: { [number]: boolean } = {}
local playersLastOwnVisible: { [number]: boolean } = {}
local playersLastOthersVisible: { [number]: boolean } = {}

function PetService:KnitStart()
	self._data = Knit.GetService("DataService")
	self._gamepass = Knit.GetService("GamepassService")
	
	self._data.DataUpdated.Event:Connect(function(player, key, value): nil
		if key == "Pets" then
			local lastEquippedPets = lastEquippedPlayerPets[player.UserId]
			if not lastEquippedPets then
				lastEquippedPets = {} :: any
				lastEquippedPlayerPets[player.UserId] = lastEquippedPets
			end
			
			local pets = value
			if lastEquippedPets == pets.Equipped then return end
			self:UpdateFollowingPets(player, pets.Equipped)
			lastEquippedPlayerPets[player.UserId] = pets.Equipped
		elseif key == "Settings" then
			task.defer(function()
				local lastOwnVisible = playersLastOwnVisible[player.UserId]
				local settings: typeof(ProfileTemplate.Settings) = value
				if lastOwnVisible == settings.ShowOwnPets then return end

				self:ToggleVisibility(player, settings.ShowOwnPets)
				playersLastOwnVisible[player.UserId] = settings.ShowOwnPets
			end)
			task.defer(function()
				local lastOthersVisible = playersLastOthersVisible[player.UserId]
				local settings: typeof(ProfileTemplate.Settings) = value

				if lastOthersVisible == settings.ShowOtherPets then return end
				for _, otherPlayer in pairs(Players:GetPlayers()) do
					if otherPlayer == player then continue end
					self:ToggleVisibility(otherPlayer, settings.ShowOtherPets)
				end

				playersLastOthersVisible[player.UserId] = settings.ShowOtherPets
			end)
		end
		return
	end)
end

function PetService:ToggleVisibility(player: Player, on: boolean): nil
	task.defer(function()
		local char = player.Character or player.CharacterAdded:Wait()
		local petsFolder = char:FindFirstChild("Pets")
		if not petsFolder then return end

		for _, pet in pairs(petsFolder:GetChildren()) do
			task.defer(function()
				for _, part in pairs(pet:GetChildren()) do
					task.defer(function()
						if not part:IsA("BasePart") then return end
						part.Transparency = if on then 0 else 1
					end)
				end
			end)
		end
	end)
	return
end

function PetService:Find(player: Player, id: string): typeof(PetsTemplate.Dog)?
	AssertPlayer(player)
	VerifyID(player, id)

	local pets = self._data:GetValue(player, "Pets")
	return Array.new("table", pets.OwnedPets)
		:Find(function(pet)
			return pet.ID == id
		end)
end
	

function PetService:Add(player: Player, petName: string): nil
	AssertPlayer(player)

	local template = PetsTemplate[petName]
	local pet = {
		Name = petName,
		ID = HttpService:GenerateGUID(),
		Rarity = template.Rarity,
		StrengthMultiplier = template.StrengthMultiplier
	}

	task.defer(function(): nil
		local pets = self._data:GetValue(player, "Pets")
		local ownedPets = pets.OwnedPets
		table.insert(ownedPets, pet)

		self:AutoDelete(player, pets)
		return
	end)
	return
end

function PetService:GetPetSpace(player: Player): number
	AssertPlayer(player)
	
	local petSpace = 4
	if self._gamepass:DoesPlayerOwn(player, "+2 Pets Equipped") then
		petSpace += 2
	end
	if self._gamepass:DoesPlayerOwn(player, "+4 Pets Equipped") then
		petSpace += 4
	end

	local pets = self._data:GetValue(player, "Pets")

	local petStorage = 200

	if self._gamepass:DoesPlayerOwn(player, "+200 Inventory Space") then
		petStorage += 200
	end

	if self._gamepass:DoesPlayerOwn(player, "+500 Inventory Space") then
		petStorage += 500
	end

	if pets.MaxEquip ~= petSpace or pets.MaxStorage ~= petStorage then
		pets.MaxEquip = petSpace
		pets.MaxStorage = petStorage
		self._data:SetValue(player, "Pets", pets)
	end

	return petSpace
end

function PetService:AddInventorySpace(player: Player, amount: number): nil
	AssertPlayer(player)
	
	local pets = self._data:GetValue(player, "Pets")
	pets.MaxStorage += amount
	self._data:SetValue(player, "Pets", pets)
	return
end

function PetService:Equip(player: Player, pet: typeof(PetsTemplate.Dog)): nil
	task.defer(function()
		AssertPlayer(player)
		VerifyID(player, pet.ID)

		local petSpace = self:GetPetSpace(player)
		local pets = self._data:GetValue(player, "Pets")
		local equippedPets = pets.Equipped
		if #equippedPets >= petSpace then return end

		table.insert(equippedPets, pet)
		pets.Equipped = equippedPets
		self._data:SetValue(player, "Pets", pets)

		local visible = self._data:GetSetting(player, "ShowOwnPets")
		self:ToggleVisibility(player, visible)
	end)
	return
end

function PetService:Unequip(player: Player, pet: typeof(PetsTemplate.Dog)): nil
	task.defer(function(): nil
		AssertPlayer(player)
		VerifyID(player, pet.ID)

		local pets = self._data:GetValue(player, "Pets")
		local equippedPets = Array.new("table", pets.Equipped)
		equippedPets:RemoveValue(pet)
		pets.Equipped = equippedPets:ToTable()
		self._data:SetValue(player, "Pets", pets)
		return
	end)
	return
end

function PetService:UnequipAll(player: Player): nil
	AssertPlayer(player)
	local pets = self._data:GetValue(player, "Pets")
	pets.Equipped = {}
	self._data:SetValue(player, "Pets", pets)
	return
end

function PetService:IsEquipped(player: Player, pet: typeof(PetsTemplate.Dog)): boolean
	AssertPlayer(player)
	VerifyID(player, pet.ID)

	local pets = self._data:GetValue(player, "Pets")
	return Array.new("table", pets.Equipped)
		:Map(function(pet)
			return pet.ID
		end)
		:Has(pet.ID)
end

function PetService:GetTotalMultiplier(player: Player): number
	AssertPlayer(player)
	local pets = self._data:GetValue(player, "Pets")
	local total = 1
	for _, pet in pets.Equipped do
		total += pet.StrengthMultiplier
	end
	
	return total
end

function PetService:GetPetOrder(player: Player): number?
	AssertPlayer(player)
	
	local character = player.Character or player.CharacterAdded:Wait()
	local petFolder = character:WaitForChild("Pets") :: Folder
	if #petFolder:GetChildren() == 0 then
		return 1
	end

	local activeSlots = {}
	for _, pet in petFolder:GetChildren() do
		local order = pet:GetAttribute("Order")
		activeSlots[order] = order
	end

	local petSpace = self:GetPetSpace(player)
	for availableSlot = 1, petSpace do
		if not activeSlots[availableSlot] then
			return availableSlot
		end
	end
	
	return
end

local function calculatePositions(numPets)
    local positions = {}
    local radius = BASE_RADIUS

    if numPets == 1 then
        positions[1] = Vector3.new(0, Y_OFFSET, radius)
    elseif numPets == 2 then
        positions[1] = Vector3.new(-radius, Y_OFFSET, 0)
        positions[2] = Vector3.new(radius, Y_OFFSET, 0)
    else
        for i = 1, numPets do
            local angle = (i - 1) * (2 * math.pi / numPets)
            local x = radius * math.cos(angle)
            local z = radius * math.sin(angle)
            positions[i] = Vector3.new(x, Y_OFFSET, z)
        end
    end

    return positions
end

function PetService:StartFollowing(player: Player, pet: Model, pet_index: number, numpets: number): nil
	AssertPlayer(player)
	task.defer(function()
		local janitor = Janitor.new()
		janitor:LinkToInstance(pet, true)

		local character = player.Character or player.CharacterAdded:Wait()
		local petFolder = character:FindFirstChild("Pets") :: Folder?
		if not petFolder then
			petFolder = Instance.new("Folder", player.Character);
			(petFolder :: any).Name = "Pets"
		end

		local primaryPart = character.PrimaryPart :: Part
		pet:PivotTo(primaryPart.CFrame)
		local characterAttachment = Instance.new("Attachment", primaryPart)
		local petAttachment = Instance.new("Attachment", pet.PrimaryPart)
		janitor:Add(characterAttachment)
		janitor:Add(petAttachment)

		local positionAligner = Instance.new("AlignPosition")
		positionAligner.MaxForce = 10_000_000
		positionAligner.Attachment0 = petAttachment
		positionAligner.Attachment1 = characterAttachment
		positionAligner.Responsiveness = FOLLOW_SPEED
		positionAligner.Parent = pet.PrimaryPart
		janitor:Add(positionAligner)

		local orientationAligner = Instance.new("AlignOrientation")
		orientationAligner.MaxTorque = 10_000_000
		orientationAligner.Attachment0 = petAttachment
		orientationAligner.Attachment1 = characterAttachment
		orientationAligner.Responsiveness = FOLLOW_SPEED
		orientationAligner.Parent = pet.PrimaryPart
		janitor:Add(positionAligner)

		local order = self:GetPetOrder(player)
		pet:SetAttribute("Order", order)

		local PET_POSITIONS = calculatePositions(numpets)
		local position = PET_POSITIONS[pet_index]

		characterAttachment.Position = position
		characterAttachment.Orientation = Vector3.new(0, -90, 0)
		
		local petParts = Array.new("Instance", pet:GetChildren())
			:Filter(function(e)
				return e:IsA("BasePart")
			end)
		
		for _, part: BasePart in petParts:GetValues() do
			part.Anchored = false
			part.CanCollide = false
			if part == pet.PrimaryPart then continue end
			Welder.Weld(pet.PrimaryPart, { part })
		end
		
		pcall(function()
			pet.Parent = petFolder
		end)
		if not pet.PrimaryPart then return end
		if pet.PrimaryPart:IsDescendantOf(workspace) then
			pet.PrimaryPart:SetNetworkOwner(player)
		end

		local BOBBING_AMPLITUDE = 0.8  -- Adjust this value to change the height of the bobbing
		local BOBBING_FREQUENCY = 2    -- Adjust this value to change the speed of the bobbing

		janitor:Add(game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
			local time = os.clock()
			local verticalOffset = math.sin(time * BOBBING_FREQUENCY) * BOBBING_AMPLITUDE
			characterAttachment.Position = Vector3.new(
				position.X,
				position.Y + verticalOffset,
				position.Z
			)
		end))
	end)
	return
end

local petJanitors: { [number]: typeof(Janitor.new()) } = {}
function PetService:UpdateFollowingPets(player: Player, pets: { typeof(PetsTemplate.Dog) & { Name: string } }): nil
	AssertPlayer(player)
	
	local petsJanitor = petJanitors[player.UserId]
	if not petsJanitor then
		petsJanitor = Janitor.new()
		petJanitors[player.UserId] = petsJanitor
	end
	petsJanitor:Cleanup()

	local visible = self._data:GetSetting(player, "ShowOwnPets")
	self:ToggleVisibility(player, visible)

	local totalpets = #pets
	local pet_index = 1

	for _, pet in pets do
		local pet_index_tosend = pet_index
		task.defer(function(): nil
			local petModelTemplate = ReplicatedStorage.Assets.Pets:FindFirstChild(pet.Name)
			if not petModelTemplate then
				return warn(`Could not find pet model "{pet.Name}"`)
			end

			local petModel = petModelTemplate:Clone()
			petsJanitor:Add(petModel)
			return self:StartFollowing(player, petModel, pet_index_tosend, totalpets)
		end)
		pet_index += 1
	end
	return
end

function PetService:Upgrade(player, pet, weight)
	AssertPlayer(player)

	local pets = self._data:GetValue(player, "Pets")
	local pets_array = Array.new("table", pets.OwnedPets)

	local amount = pets_array
		:Filter(function(pet_checked)
			return pet_checked == pet
		end)
		:Amount()
	
	if amount < weight then return end
	
	for i = 1, weight do
		pets_array:RemoveValue(pet)
	end

	local number = Random.new():NextNumber()

	if number < weight * 0.2 then
		--// TODO: think trough if this is really the way to go
		self:Add(player, "Gold "..pet)
	end
end

function PetService:EquipBest(player)
    AssertPlayer(player)

    local pets = self._data:GetValue(player, "Pets")
    local ownedPets = pets.OwnedPets
    local equippedPets = pets.Equipped
    local petSpace = self:GetPetSpace(player)
    
    local function comparePets(a, b)
        return a.StrengthMultiplier > b.StrengthMultiplier
    end

    table.sort(ownedPets, comparePets)

    local equippedPetsMap = {}

    local newEquippedPets = {}
    for _, pet in ipairs(ownedPets) do
        if #newEquippedPets >= petSpace then
            break
        end
        if not equippedPetsMap[pet.ID] then
            table.insert(newEquippedPets, pet)
            equippedPetsMap[pet.ID] = true
        end
    end

    pets.Equipped = newEquippedPets
    self._data:SetValue(player, "Pets", pets)
end

function PetService:Delete(player: Player, pet: typeof(PetsTemplate.Dog)): nil
	task.defer(function(): nil
		AssertPlayer(player)
		VerifyID(player, pet.ID)

		local pets = self._data:GetValue(player, "Pets")
		if pet.Locked then return end
		local ownedPets = Array.new("table", pets.OwnedPets)
		ownedPets:RemoveValue(pet)
		local equippedPets = Array.new("table", pets.Equipped)
		equippedPets:RemoveValue(pet)
		pets.Equipped = equippedPets:ToTable()
		pets.OwnedPets = ownedPets:ToTable()
		self._data:SetValue(player, "Pets", pets)
		return
	end)
	return
end

function PetService:Lock(player, petID)
	task.defer(function(): nil
		AssertPlayer(player)
		VerifyID(player, petID)
		local pets = self._data:GetValue(player, "Pets")
		local ownedPets = Array.new("table", pets.OwnedPets)
		local pet = ownedPets:Find(function(pet)
			return pet.ID == petID
		end)
		if not pet then return end
		pet.Locked = not pet.Locked
		self._data:SetValue(player, "Pets", pets)
		return
	end)
	return
end

function PetService:IsLocked(player, petID)
	AssertPlayer(player)
	VerifyID(player, petID)
	local pets = self._data:GetValue(player, "Pets")
	local pet = Array.new("table", pets.OwnedPets)
		:Find(function(pet)
			return pet.ID == petID
		end)
	return pet.Locked
end

function PetService:AutoDelete(player, pets)
	AssertPlayer(player)
	pets = pets or self._data:GetValue(player, "Pets")
	local autodelete = self._data:GetValue(player, "AutoDelete")

	local ownedPets = Array.new("table", pets.OwnedPets)
	local equippedPets = Array.new("table", pets.Equipped)

	ownedPets:Filter(function(pet)
		return not pet.Locked
	end)

	ownedPets:Filter(function(pet)
		return not autodelete[pet.Rarity]
	end)

	equippedPets:Filter(function(pet)
		return not pet.Locked
	end)
	equippedPets:Filter(function(pet)
		return not autodelete[pet.Rarity]
	end)

	pets.Equipped = equippedPets:ToTable()
	pets.OwnedPets = ownedPets:ToTable()
	self._data:SetValue(player, "Pets", pets)
	return pets
end

function PetService.Client:Equip(player, pet)
	return self.Server:Equip(player, pet)
end

function PetService.Client:Unequip(player, pet)
	return self.Server:Unequip(player, pet)
end

function PetService.Client:Lock(player, petID)
	return self.Server:Lock(player, petID)
end

function PetService.Client:IsLocked(player, petID)
	return self.Server:IsLocked(player, petID)
end

function PetService.Client:UnequipAll(player)
	return self.Server:UnequipAll(player)
end

function PetService.Client:IsEquipped(player, pet)
	return self.Server:IsEquipped(player, pet)
end

function PetService.Client:EquipBest(player)
	return self.Server:EquipBest(player)
end

function PetService.Client:GetPetSpace(player)
	return self.Server:GetPetSpace(player)
end

function PetService.Client:GetTotalMultiplier(player)
	return self.Server:GetTotalMultiplier(player)
end

function PetService.Client:Delete(player, pet)
	return self.Server:Delete(player, pet)
end

return PetService