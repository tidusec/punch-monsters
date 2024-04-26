--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage.Packages

local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Array = require(Packages.Array)

local TrainingService = Knit.CreateService {
	Name = "TrainingService";
}

function TrainingService:KnitStart(): nil
    self._data = Knit.GetService("DataService")
    self._rebirths = Knit.GetService("RebirthService")
	self._boosts = Knit.GetService("BoostService")
	self._gamepass = Knit.GetService("GamepassService")

	self._situptemplates = require(ReplicatedStorage.Templates.SitupBenchTemplate)
    self._dumbelltemplates = require(ReplicatedStorage.Templates.DumbellTemplates)
    self._punchbagtemplates = require(ReplicatedStorage.Templates.PunchbagTemplates)
    
    self.memory = {}

	Players.PlayerAdded:Connect(function(player: Player)
		self.memory[player.UserId] = {
			equipped = {
                SitupBench = self._situptemplates[1],
                Dumbell = self._dumbelltemplates[1]
            },
            current_training = "",
		}
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self.memory[player.UserId] = nil
	end)

	return
end

function TrainingService:Enter(player: Player, boss: string): string
	if self.memory[player.UserId].entered then return end
	if self._enemies[boss] then
		self.memory[player.UserId].entered = true
		self.memory[player.UserId].boss = boss
		self.memory[player.UserId].bosshealth = self._enemies[boss].health
		return
	end
end

function TrainingService:StartFight(player: Player, boss: string): string
	if not self.memory[player.UserId].entered then return end
	if self.memory[player.UserId].fighting then return end
	if self.memory[player.UserId].boss == boss then
		self.memory[player.UserId].fighting = true
		return
	end
end

function TrainingService:Attack(player: Player): string
	if not self.memory[player.UserId].fighting then return end
	self.memory[player.UserId].bosshealth -= self._data:GetTotalStrength(player)
	if self.memory[player.UserId].bosshealth <= 0 then
		if self._enemies[self.memory[player.UserId].boss].Boss then
			local bossmap = "Map"..self._enemies[self.memory[player.UserId].boss].Map
			self._data:AddDefeatedBoss(player, bossmap)
		end
		
		self:AddWin(player)
		self:ClearData(player)
		return
	elseif self.memory[player.UserId].health <= 0 then
		self:ClearData(player)
		return
	else
		return self.memory[player.UserId].bosshealth, self.memory[player.UserId].health
	end
end

function TrainingService:AddWin(player: Player): string
	local hasDoubleWins = self._gamepass:DoesPlayerOwn(player, "2x Wins")
	local hasWinsBoost = self._boosts:IsBoostActive(player, "2xWins")
	local gamepassMultiplier: number = (if hasDoubleWins then 2 else 1) * (if hasWinsBoost then 2 else 1)
	local rebirthMultiplier: number = self._rebirths:GetBoost(player, "Wins")
	self._data:IncrementValue("Wins", (self :: any)._enemyTemplate.Wins * rebirthMultiplier * gamepassMultiplier)
	return
end

function TrainingService:ClearData(player: Player): string
	self.memory[player.UserId].fighting = false
	self.memory[player.UserId].boss = ""
	self.memory[player.UserId].bosshealth = 100
	self.memory[player.UserId].entered = false
	return
end

function TrainingService.Client:Enter(player: Player, boss: string): number
	return self.Server:Enter(player, boss)
end

function TrainingService.Client:StartFight(player: Player, boss: string): number
	return self.Server:StartFight(player, boss)
end

function TrainingService.Client:Attack(player: Player): number
	return self.Server:Attack(player)
end

return TrainingService