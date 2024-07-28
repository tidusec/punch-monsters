--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Array = require(ReplicatedStorage.Packages.Array)

local BoostService = Knit.CreateService {
  Name = "BoostService";
  Client = {
    BoostUpdated = Knit.CreateSignal(),
  };
}

type BoostName = "10xLuck" | "100xLuck" | "2xWins" | "2xStrength"

local function minutes(min: number): number
  return min * 60
end

function BoostService:KnitStart(): nil
  self._timers = Knit.GetService("TimerService")
  return
end

function BoostService:_StartTimer(player: Player, name: BoostName, length: number): nil
  return self._timers:Start(player, name .. "Boost", length)
end

function BoostService:IsBoostActive(player: Player, boostName: BoostName): boolean
  return Array.new("table", self._timers:GetAll(player))
    :Some(function(timer)
      return timer.Name == boostName .. "Boost" and not self._timers:IsFinished(timer)
    end)
end

function BoostService:Activate10xLuckBoost(player: Player): nil
  self:_StartTimer(player, "10xLuck", minutes(30))
  self.Client.BoostUpdated:Fire(player)
  return
end

function BoostService:Activate100xLuckBoost(player: Player): nil
  self:_StartTimer(player, "100xLuck", minutes(15))
  self.Client.BoostUpdated:Fire(player)
  return
end

function BoostService:ActivateDoubleWinsBoost(player: Player): nil
  self:_StartTimer(player, "2xWins", minutes(30))
  self.Client.BoostUpdated:Fire(player)
  return
end

function BoostService:ActivateDoubleStrengthBoost(player: Player): nil
  self:_StartTimer(player, "2xStrength", minutes(30))
  self.Client.BoostUpdated:Fire(player)
  return
end

function BoostService:GetBoostTimeLeft(player: Player, boostName: BoostName): number
  local timer = Array.new("table", self._timers:GetAll(player))
    :Find(function(timer)
      return timer.Name == boostName .. "Boost"
    end)
  if timer then
    return self._timers:GetTimeLeft(timer)
  end
  return 0
end

function BoostService.Client:IsBoostActive(player: Player, boostName: BoostName): boolean
  return self.Server:IsBoostActive(player, boostName)
end

function BoostService.Client:GetBoostTimeLeft(player: Player, boostName: BoostName): number
  return self.Server:GetBoostTimeLeft(player, boostName)
end

return BoostService
