--!native
--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Welder = require(ReplicatedStorage.Modules.Welder)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local AssertPlayer = require(script.Parent.Parent.Modules.AssertPlayer)

type Situp = {
	Required: number;
	Gain: number;
	IsVIP: boolean;
}

type SitupInfo = {
	Equipped: boolean;
	SitupDebounce: boolean;
	EquippedSitupTemplate: Situp?;
}

local SitupService = Knit.CreateService {
	Name = "SitupService";
}

function SitupService:KnitStart(): nil
	self._data = Knit.GetService("DataService")
	self._gamepass = Knit.GetService("GamepassService")
	self._playerSitupInfo = {}

	Players.PlayerAdded:Connect(function(player)
		if not self._playerSitupInfo[player.UserId] then
			self._playerSitupInfo[player.UserId] = {
				Equipped = false,
				SitupDebounce = false,
				EquippedSitupTemplate = nil
			}
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		self._playerSitupInfo[player.UserId] = nil
	end)

	return
end

function SitupService:Situp(player: Player): nil
	AssertPlayer(player)

	local SitupInfo = self._playerSitupInfo[player.UserId]
	if not SitupInfo.Equipped then return end
	if SitupInfo.SitupDebounce then return end
	SitupInfo.SitupDebounce = true
	self._playerSitupInfo[player.UserId] = SitupInfo
	
	task.delay(1.3, function(): nil
		
		SitupInfo.SitupDebounce = false
		self._playerSitupInfo[player.UserId] = SitupInfo
		return
	end)
	
	local strengthMultiplier = self._data:GetTotalStrengthMultiplier(player)
	local hasVIP = self._gamepass:DoesPlayerOwn(player, "VIP")
	if SitupInfo.EquippedSitupTemplate.IsVIP and not hasVIP then
		return self._gamepass:PromptPurchase(player, "VIP")
	end
	
	self._data:IncrementValue(player, "AbsStrength", SitupInfo.EquippedSitupTemplate.Gain * strengthMultiplier)
	return
end

function SitupService:Equip(player: Player, mapName: string, number: number, Situp: Situp): nil
	AssertPlayer(player)

	local SitupInfo = self._playerSitupInfo[player.UserId]
	if SitupInfo.EquippedSitupTemplate == Situp then return end
	if SitupInfo.Equipped then return end

	local bicepsStrength = self._data:GetValue(player, "AbsStrength")
	if Situp.Required > bicepsStrength then return end
	
	SitupInfo.Equipped = true
	SitupInfo.EquippedSitupTemplate = Situp
	self._playerSitupInfo[player.UserId] = SitupInfo
	return
end

function SitupService:Unequip(player: Player): nil
	AssertPlayer(player)

	local SitupInfo = self._playerSitupInfo[player.UserId]
	if not SitupInfo.Equipped then return end
	SitupInfo.Equipped = false
	SitupInfo.EquippedSitupTemplate = nil
	self._playerSitupInfo[player.UserId] = SitupInfo

	task.spawn(function()
		local character = player.Character :: any
		if character:FindFirstChild("Situp") then
			character.Situp:Destroy()
		end
	end)
	return
end

function SitupService.Client:Situp(player: Player): nil
	return self.Server:Situp(player)
end

function SitupService.Client:Equip(player: Player, mapName: string, number: number, Situp: Situp): nil
	return self.Server:Equip(player, mapName, number, Situp)
end

function SitupService.Client:Unequip(player: Player): nil
	return self.Server:Unequip(player)
end

function SitupService.Client:IsEquipped(player: Player): boolean
	return self.Server._playerSitupInfo[player.UserId].Equipped
end

return SitupService