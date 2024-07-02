--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ServerScriptService.Server.Modules
local Packages = ReplicatedStorage.Packages

local AssertPlayer = require(Modules.AssertPlayer)
local abbreviate = require(ReplicatedStorage.Assets.Modules.Abbreviate)

local Knit = require(Packages.Knit)
local Promise = require(Packages.Promise)
local Array = require(ReplicatedStorage.Modules.NewArray)
local ProfileService = require(Packages.ProfileService)

local PROFILE_TEMPLATE = require(ReplicatedStorage.Templates.ProfileTemplate)

type Promise = typeof(Promise.new())

-- local Test = RunService:IsStudio()
local Test = false

local DataService = Knit.CreateService {
	Name = "DataService";
	DataUpdated = Instance.new("BindableEvent");
	Client = {
		DataUpdated = Knit.CreateSignal(),
	};
}

local ProfileStore = ProfileService.GetProfileStore(
	"PlayerTestData#14",
	PROFILE_TEMPLATE
)

if Test then
	ProfileStore = ProfileService.GetProfileStore(
		`TestProfile#{HttpService:GenerateGUID()}`,
		PROFILE_TEMPLATE
	)
end

local PROFILE_CACHE = {}
local gameClosed = false

game:BindToClose(function(): nil
	gameClosed = true
	return
end)

local function GetProfile(player: Player): Promise
	AssertPlayer(player)
	return Promise.new(function(resolve, reject): nil
		local profile = PROFILE_CACHE[player]
		if gameClosed then
			return resolve()
		end

		repeat
			profile = PROFILE_CACHE[player]
			task.wait()
		until profile ~= nil and profile.Loaded
		return resolve(profile)
	end)
end

local function CreateLeaderstats(player: Player): nil
	AssertPlayer(player)
	task.spawn(function()
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
	
		for name, value in pairs(PROFILE_TEMPLATE.leaderstats) do
			local stat = Instance.new("StringValue")
			stat.Name = name
			stat.Value = value
			stat.Parent = leaderstats
		end
	
		leaderstats.Parent = player
	end)
	return
end

local function CreatePetsFolder(player: Player): nil
	AssertPlayer(player)
	task.spawn(function()
		local PetFolder = Instance.new("Folder")
		PetFolder.Name = "PetFolder"
		PetFolder.Parent = player
	end)
	return
end

local function UpdateLeaderstats(player: Player): nil
	AssertPlayer(player)
	task.spawn(function(): nil
		local success, profile = GetProfile(player):await()
		if not success then return error(profile) end
		if not profile then return end

		local data = profile.Data
		local leaderstats = player:WaitForChild("leaderstats")

		local punchStrength = data.PunchStrength
		local bicepsStrength = data.BicepsStrength
		local absStrength = data.AbsStrength

		local arithmeticMean = (punchStrength + bicepsStrength + absStrength) / 3

		local geometricMean = (punchStrength * bicepsStrength * absStrength) ^ (1/3)

		local harmonicMean = 3 / ((1 / punchStrength) + (1 / bicepsStrength) + (1 / absStrength))

		--// make it a combination of all 3, making it so that the player has to train all 3 to get the best strength
		data.leaderstats.Strength = (arithmeticMean + 3 * geometricMean + 2 * harmonicMean) / 6 * 3
		data.leaderstats.Strength = math.floor(data.leaderstats.Strength * 100) / 100

		(leaderstats :: any).Strength.Value = abbreviate(data.leaderstats.Strength);
		(leaderstats :: any).Eggs.Value = abbreviate(data.leaderstats.Eggs);
		(leaderstats :: any).Rebirths.Value = abbreviate(data.leaderstats.Rebirths)
		return
	end)
	return
end

function DataService:KnitStart()
	self._pets = Knit.GetService("PetService")
	self._rebirths = Knit.GetService("RebirthService")
	self._boosts = Knit.GetService("BoostService")
	self._gamepass = Knit.GetService("GamepassService")
	self._quests = Knit.GetService("QuestService")
	
	Players.PlayerAdded:Connect(function(player: Player): nil
		return self:OnPlayerAdded(player)
	end)
	Players.PlayerRemoving:Connect(function(player: Player): nil
		local profile = PROFILE_CACHE[player]
		if not profile then return end
		return profile:Release()
	end)

	for _, player in Players:GetPlayers() do
		self:OnPlayerAdded(player)
	end
end

function DataService:OnPlayerAdded(player: Player): nil
	AssertPlayer(player)
	local profile = ProfileStore:LoadProfileAsync(`Player_{player.UserId}`)
	if not profile then
		return player:Kick()
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile:ListenToRelease(function(): nil
		PROFILE_CACHE[player] = nil
		return player:Kick()
	end)

	if player:IsDescendantOf(Players) then
		PROFILE_CACHE[player] = profile
		CreateLeaderstats(player)
		CreatePetsFolder(player)
		UpdateLeaderstats(player)
		self:InitializeClientUpdate(player)
		profile.Loaded = true
	else
		profile:Release()
	end
	return 
end

function DataService:InitializeClientUpdate(player: Player): nil
	AssertPlayer(player)
	task.spawn(function(): nil
		local success, profile = GetProfile(player):await()
		if not success then return error(profile) end
		
		self:DataUpdate(player, "leaderstats", profile.Data.leaderstats)
		self:DataUpdate(player, "Pets", profile.Data.Pets)
		self:DataUpdate(player, "ActiveBoosts", profile.Data.ActiveBoosts)
		self:DataUpdate(player, "Wins", profile.Data.Wins)
		self:DataUpdate(player, "PunchStrength", profile.Data.PunchStrength)
		self:DataUpdate(player, "AbsStrength", profile.Data.AbsStrength)
		self:DataUpdate(player, "BicepsStrength", profile.Data.BicepsStrength)
		self:DataUpdate(player, "ProductsLog", profile.Data.ProductsLog)
		self:DataUpdate(player, "RedeemedCodes", profile.Data.RedeemedCodes)
		self:DataUpdate(player, "Settings", profile.Data.Settings)
		self:DataUpdate(player, "Timers", profile.Data.Timers)
		self:DataUpdate(player, "ClaimedRewardsToday", profile.Data.ClaimedRewardsToday)
		self:DataUpdate(player, "FirstJoinToday", profile.Data.FirstJoinToday)
		self:DataUpdate(player, "AutoTrain", profile.Data.AutoTrain)
		self:DataUpdate(player, "AutoFight", profile.Data.AutoFight)
		return
	end)
	return
end

function DataService:DataUpdate<T>(player: Player, key: string, value: T): nil
	task.spawn(function(): nil
		self.Client.DataUpdated:Fire(player, key, value)
		return self.Client.DataUpdated:Fire(player, key, value)
	end)
	task.spawn(function(): nil
		return self.DataUpdated:Fire(player, key, value)
	end)
	return
end

--// General Functions

local function PetDuplicatesWereFound(): boolean
	local duplicatesFound = false
	local ids = Array.new("string")
	
	for player, profile in pairs(PROFILE_CACHE) do	
		local pets = Array.new("table", profile.Data.Pets.OwnedPets)
		for _, pet in pets:GetValues() do
			if ids:Has(pet.ID) then
				duplicatesFound = true
				player:Kick(`Exploiting | Duplicate pet ID found | Pet name: {pet.Name}`)
				break
			end
			ids:Push(pet.ID)
		end
	end

	return duplicatesFound
end

function DataService:SetValue<T>(player: Player, name: string, value: T): Promise
	AssertPlayer(player)
	return Promise.new(function(resolve, reject): nil
		local success, profile = GetProfile(player):await()
		if not success then return error(profile) end
		if not profile then return end

		if name == "Pets" then
			if PetDuplicatesWereFound() then return end
		end
		
		task.spawn(function(): nil
			return self._quests:SetProgress(player, if name == "Eggs" then "OpenEggs" else "GainStrength", value)
		end)
		
		local data = profile.Data
		if data[name] ~= nil then
			data[name] = value
		elseif data.leaderstats[name] ~= nil then
			data.leaderstats[name] = value
		else
			return reject(`Could not find key "{name}" in profile while setting {player.DisplayName}'s data.`)
		end
		
		UpdateLeaderstats(player)
		self:DataUpdate(player, name, value)
		return resolve()
	end)
end

function DataService:IncrementValue(player: Player, name: string, amount: number): Promise
	AssertPlayer(player)
	return Promise.new(function(resolve): nil
		local value = self:GetValue(player, name)
		self:SetValue(player, name, value + (amount or 1)):await()
		return resolve()
	end)
end

function DataService:DeductValue(player: Player, name: string, amount: number): Promise
	AssertPlayer(player)
	return Promise.new(function(resolve): nil
		local value = self:GetValue(player, name)
		self:SetValue(player, name, value - (amount or 1)):await()
		return resolve()
	end)
end

function DataService:GetValue<T>(player: Player, name: string): T
	AssertPlayer(player)
	local success, profile = GetProfile(player):await()
	if not success then return error(profile) end
	if not profile then return nil :: any end

	local data = profile.Data
	local value = data[name]
	return if value == nil then data.leaderstats[name] else value
end

function DataService:SetSetting<T>(player: Player, settingName: string, value: T): Promise
	AssertPlayer(player)
	if string.find(settingName, "Auto") then
		if type(value) ~= "boolean" then
			return error(`Expected boolean, got {type(value)}`)
		end
		return Promise.new(function(resolve): nil
			self:SetValue(player, settingName, value)
			return resolve()
		end)
	else
		return Promise.new(function(resolve): nil
			local settings = self:GetValue(player, "Settings")
			settings[settingName] = value
			self:SetValue(player, "Settings", settings)
			return resolve()
		end)
	end
end

function DataService:GetSetting<T>(player: Player, settingName: string): T
	AssertPlayer(player)
	local settings = self:GetValue(player, "Settings")
	return settings[settingName]
end

function DataService:GetTotalStrength(player: Player, strengthType: "Punch" | "Abs" | "Biceps"?): (number, number)
	AssertPlayer(player)
	local initialStrength = self:GetValue(player, (strengthType or "") .. "Strength")
	local strengthMultiplier = self:GetTotalStrengthMultiplier(player)

	--// The reason why I return initialStrength here instead of initialStrength * strengthMultiplier is because
	--// you will be counting double as incrementvalue already takes account of the strength multiplier
	--// (and it makes no sense to double a players strength at the when he has 1B to 2B because he bought gamepass)
	--// it will improve his training 
	--/                      - tidusec
	return initialStrength, strengthMultiplier
end

function DataService:GetTotalStrengthMultiplier(player: Player): number
	AssertPlayer(player)
	local petMultiplier = self._pets:GetTotalMultiplier(player)
	local rebirthMultiplier = self._rebirths:GetBoost(player, "Strength")
	print("OOF")
	local gamepassMultiplier = if self._gamepass:DoesPlayerOwn(player, "2x Strength") then 2 else 1
	local boostMultiplier = if self._boosts:IsBoostActive(player, "2xStrength") then 2 else 1
	return petMultiplier * rebirthMultiplier * gamepassMultiplier * boostMultiplier
end

function DataService:AddDefeatedBoss(player: Player, bossMap: string): nil
	local defeatedBosses = self:GetValue(player, "DefeatedBosses")
	table.insert(defeatedBosses, bossMap)
	self:SetValue(player, "DefeatedBosses", defeatedBosses)
	return
end

-- client

function DataService.Client:GetValue(player, name)
	return self.Server:GetValue(player, name)
end

function DataService.Client:GetSetting(player, name)
	return self.Server:GetSetting(player, name)
end

function DataService.Client:SetSetting(player, name, value)
	return self.Server:SetSetting(player, name, value)
end

function DataService.Client:GetTotalStrength(player, strengthType: "Punch" | "Abs" | "Biceps"?)
	return self.Server:GetTotalStrength(player, strengthType)
end

function DataService.Client:GetTotalStrengthMultiplier(player)
	return self.Server:GetTotalStrengthMultiplier(player)
end

function DataService.Client:DispatchUpdate(player: Player): nil
	return self.Server:InitializeClientUpdate(player)
end

return DataService