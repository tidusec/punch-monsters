--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage.Packages

local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Array = require(Packages.Array)

local EnemyFightingService = Knit.CreateService {
	Name = "EnemyFightingService";
}

function EnemyFightingService:KnitStart(): nil
    self._data = Knit.GetService("DataService")
	self._enemies = require(ReplicatedStorage.Templates.EnemiesTemplate)
	self._rebirths = Knit.GetService("RebirthService")
	self._boosts = Knit.GetService("BoostService")
	self._gamepass = Knit.GetService("GamepassService")
    self.memory = {}

	self._strengthToHealthRatio = 10
	self._healthToDamageRatio = 1.2

	Players.PlayerAdded:Connect(function(player: Player)
		self.memory[player.UserId] = {
			entered = false,
			fighting = false,
			health = 100,
			boss = "",
			bosshealth = 0,
			bossdamage = 0,
			winner = false,
		}
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self.memory[player.UserId] = nil
	end)

	return
end

function EnemyFightingService:Enter(player: Player, boss: string): string
	if self.memory[player.UserId].entered then return end
	if self._enemies[boss] then
		self.memory[player.UserId].entered = true
		self.memory[player.UserId].boss = boss
		self.memory[player.UserId].health = self._data:GetTotalStrength(player) * self._strengthToHealthRatio
		self.memory[player.UserId].bosshealth = self._enemies[boss].Strength * self._strengthToHealthRatio
		self.memory[player.UserId].bossdamage = self._enemies[boss].Strength / self._healthToDamageRatio
		self.memory[player.UserId].winner = false
		return self.memory[player.UserId].health, self.memory[player.UserId].bosshealth
	end
end

function EnemyFightingService:StartFight(player: Player, boss: string): string
	if not self.memory[player.UserId].entered then return end
	if self.memory[player.UserId].fighting then return end

	if self.memory[player.UserId].boss == boss then
		self.memory[player.UserId].fighting = true
		task.spawn(function()
			while self.memory[player.UserId].fighting do
				task.wait(0.3)
				self.memory[player.UserId].health -= self.memory[player.UserId].bossdamage
				if self.memory[player.UserId].health <= 0 then
					self:ClearData(player, false)
					return
				end
			end
		end)
		return
	end
end

function EnemyFightingService:Attack(player: Player): string
	if not self.memory[player.UserId].fighting then return self.memory[player.UserId].bosshealth, self.memory[player.UserId].health end
	self.memory[player.UserId].bosshealth -= self._data:GetTotalStrength(player)
	if self.memory[player.UserId].bosshealth <= 0 then
		if self._enemies[self.memory[player.UserId].boss].Boss then
			local bossmap = "Map"..self._enemies[self.memory[player.UserId].boss].Map
			warn(bossmap)
			self._data:AddDefeatedBoss(player, bossmap)
		end
		
		self:AddWin(player)
		self:ClearData(player, true)
		return self.memory[player.UserId].bosshealth, self.memory[player.UserId].health
	elseif self.memory[player.UserId].health <= 0 then
		self:ClearData(player)
		return self.memory[player.UserId].bosshealth, self.memory[player.UserId].health
	else
		return self.memory[player.UserId].bosshealth, self.memory[player.UserId].health
	end
end

function EnemyFightingService:AddWin(player: Player): string
	local hasDoubleWins = self._gamepass:DoesPlayerOwn(player, "2x Wins")
	local hasWinsBoost = self._boosts:IsBoostActive(player, "2xWins")
	local gamepassMultiplier: number = (if hasDoubleWins then 2 else 1) * (if hasWinsBoost then 2 else 1)
	local rebirthMultiplier: number = self._rebirths:GetBoost(player, "Wins")
	self._data:IncrementValue(player, "Wins", self._enemies[self.memory[player.UserId].boss].Wins * rebirthMultiplier * gamepassMultiplier)
	return
end

function EnemyFightingService:ClearData(player: Player, winner: boolean): string
	self.memory[player.UserId].fighting = false
	self.memory[player.UserId].boss = ""
	self.memory[player.UserId].bosshealth = winner and 0 or self.memory[player.UserId].bosshealth
	self.memory[player.UserId].entered = false
	self.memory[player.UserId].health =  winner and self.memory[player.UserId].health or 0
	self.memory[player.UserId].winner = winner
	return
end

function EnemyFightingService:Update(player: Player): string
	return self.memory[player.UserId].bosshealth, self.memory[player.UserId].health
end

function EnemyFightingService.Client:Enter(player: Player, boss: string): number
	return self.Server:Enter(player, boss)
end

function EnemyFightingService.Client:StartFight(player: Player, boss: string): number
	self.Server:StartFight(player, boss)
end

function EnemyFightingService.Client:Attack(player: Player): number
	return self.Server:Attack(player)
end

function EnemyFightingService.Client:Update(player: Player): number
	return self.Server:Update(player)
end

return EnemyFightingService