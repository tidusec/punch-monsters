--!native
--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local AssertPlayer = require(script.Parent.Parent.Modules.AssertPlayer)
local Debounce = require(ReplicatedStorage.Modules.Debounce)

local PunchingBagService = Knit.CreateService {
	Name = "PunchingBagService";
}

function PunchingBagService:KnitStart(): nil
	self._data = Knit.GetService("DataService")
	self._gamepass = Knit.GetService("GamepassService")
    self.punchBagTemplate = require(ReplicatedStorage:WaitForChild("Templates"):WaitForChild("PunchBagsTemplate"))
    self._playerPunchBagInfo = {}

    Players.PlayerAdded:Connect(function(plr)
        self._playerPunchBagInfo[plr.UserId] = {
            LiftDebounce = false,
        }
    end)

    Players.PlayerRemoving:Connect(function(plr)
        if self._playerPunchBagInfo[plr.UserId] then
            self._playerPunchBagInfo[plr.UserId] = nil
        end
        self._playerPunchBagInfo[plr.UserId] = nil
    end)

	return
end

function PunchingBagService:Hit(player: Player, map: string, name: string): nil
    AssertPlayer(player)
	local playerInfo = self._playerPunchBagInfo[player.UserId]
	local punchbagInfo = self.punchBagTemplate[map][name]

    assert(playerInfo, "Player info not found")
    assert(punchbagInfo, "Punchbag info not found. "..map.." is the map and "..name.." is the name"..player.Name)
	
    if playerInfo.LiftDebounce ~= false then
        if playerInfo.LiftDebounce:IsActive() then
            return
        else
            return self:GiveStuff(player, punchbagInfo)
        end
    else
        playerInfo.LiftDebounce = Debounce.new(0.45)
        return self:GiveStuff(player, punchbagInfo)
    end
	
	return
end

function PunchingBagService:GiveStuff(player: Player, punchbagInfo): nil
    local amount = punchbagInfo.Hit
    local punchStrength, strengthMultiplier = self._data:GetTotalStrength(player, "Punch")
    if punchStrength < punchbagInfo.PunchRequirement then return end
            
    local hasVIP =  self._gamepass:DoesPlayerOwn(player, "VIP")
	if punchbagInfo.Vip and not hasVIP then
        return self._gamepass:PromptPurchase(player, "VIP")
    end

    self._data:IncrementValue(player, "PunchStrength", amount * strengthMultiplier)
end

function PunchingBagService.Client:Hit(player: Player, map :string, name: string): nil
	return self.Server:Hit(player, map, name)
end

return PunchingBagService