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
    self.punchBagTemplate = ReplicatedStorage.PunchBagTemplate
    self._playerPunchBaglInfo = {}

    Players.PlayerAdded:Connect(function(plr)
        self._playerPunchBaglInfo[plr.UserId] = {
            LiftDebounce = false,
        }
    end)

    Players.PlayerRemoving:Connect(function(plr)
        if self._playerPunchBaglInfo[plr.UserId] then
            self._playerPunchBaglInfo[plr.UserId]:Destroy()
        end
        self._playerPunchBaglInfo[plr.UserId] = nil
    end)

	return
end

function PunchingBagService:Hit(player: Player, map: string, name: string): nil
	AssertPlayer(player)

	local playerInfo = self._playerPunchBaglInfo[player.UserId]
	local punchbagInfo = self.punchBagTemplate[map][name]

    assert(playerInfo, "Player info not found")
    assert(punchbagInfo, "Punchbag info not found. "..map.." is the map and "..name.." is the name"..player.Name)
	
    if playerInfo.LiftDebounce then
        if playerInfo.LiftDebounce:IsActive() then
            return
        else
            local amount = punchbagInfo.Hit
            local punchStrength, strengthMultiplier = self._data:GetTotalStrength("Punch")
            if punchStrength < punchbagInfo.PunchRequirement then return end
            
            local hasVIP =  self._gamepass:DoesPlayerOwn(player, "VIP")
	        if punchbagInfo.Vip and not hasVIP then
                return self._gamepass:PromptPurchase(player, "VIP")
            end

            self._data:IncrementValue(player, "PunchStrength", amount * strengthMultiplier)
        end
    end
	
	return
end



function PunchingBagService.Client:Hit(player: Player, map :string, name: string): nil
	return self.Server:Hit(player, map, name)
end

return PunchingBagService