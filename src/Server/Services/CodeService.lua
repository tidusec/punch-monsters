--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Templates = ServerScriptService.Server.Templates
local Packages = ReplicatedStorage.Packages

local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Array = require(ReplicatedStorage.Modules.NewArray)

local CodeService = Knit.CreateService {
	Name = "CodeService";
}

function CodeService:KnitStart(): nil
    self._data = Knit.GetService("DataService")
	self._codes = require(Templates:WaitForChild("CodeTemplate"))
	return
end

function CodeService:KnitInit(): nil
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

function CodeService:Redeem(player: Player, code: string): string
	local reward = self.codes[code]
	if not reward then 
		return "Invalid code provided!"
	end

	local redeemedCodes = Array.new("string", self._data:GetValue("RedeemedCodes"))
	if redeemedCodes:Has(code) then
		return "You've already redeemed this code!"
	end

	for key, value in reward do
		task.defer(function()
			self._data:IncrementValue(player, key, value)
		end)
	end
	
	redeemedCodes:Push(code)
	self._data:SetValue(player, "RedeemedCodes", redeemedCodes:ToTable())
	return "Successfully redeemed code!"
end

function CodeService.Client:Redeem(player: Player, code: string): number
	return self.Server:Redeem(player, code)
end

return CodeService