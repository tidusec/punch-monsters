--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Templates = ServerScriptService.Server.Templates
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
    self.memory = {}
	return
end

function EnemyFightingService:KnitInit(): nil
	self._playersJoinedAt = {}

	Players.PlayerAdded:Connect(function(player: Player): nil
		self._playersJoinedAt[player.UserId] = tick()
		return
	end)
	Players.PlayerRemoving:Connect(function(player: Player): nil
		self._playersJoinedAt[player.UserId] = nil
		return
	end)

	return
end

function EnemyFightingService:Enter(player: Player, boss: string): string
	self.memory[player.UserId] = boss
end

function EnemyFightingService:StartFight(player: Player, boss: string): string
	self.memory[player.UserId] = boss
end

function EnemyFightingService:Attack(player: Player): string
	return 100, 250
end

function EnemyFightingService.Client:Enter(player: Player, boss: string): number
	return self.Server:Enter(player, boss)
end

function EnemyFightingService.Client:StartFight(player: Player, boss: string): number
	return self.Server:StartFight(player, boss)
end

function EnemyFightingService.Client:Attack(player: Player): number
	return self.Server:Attack(player)
end

return EnemyFightingService