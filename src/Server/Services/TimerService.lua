--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Array = require(ReplicatedStorage.Packages.Array)

local TimerService = Knit.CreateService {
  Name = "TimerService"
}

type Timer = {
  Name: string;
  ID: string;
  BeginTime: number;
  Length: number;
}

function TimerService:KnitStart(): nil
  self._data = Knit.GetService("DataService")

  return self._data.DataUpdated.Event:Connect(function(player, key): nil
    if key ~= "Timers" then return end
    return self:RemoveFinished(player)
  end)
end

function TimerService:RemoveFinished(player: Player): nil
  task.defer(function()
    local unfinishedTimers = Array.new("table", self:GetAll(player))
      :Filter(function(timer: Timer)
        return not self:IsFinished(timer)
      end)

    self._data:SetValue(player, "Timers", unfinishedTimers)
  end)
  return
end

function TimerService:IsFinished(timer: Timer): boolean
  return tick() - timer.BeginTime >= timer.Length
end

function TimerService:GetAll(player: Player): { Timer }
  local data = self._data:GetValue(player, "Timers")
  if not data or #data == 0 then
    return {}
  else
    return data
  end
end

function TimerService:Start(player: Player, name: string, length: number): nil
  task.defer(function()
    local timer: Timer = {
      Name = name,
      ID = HttpService:GenerateGUID(),
      BeginTime = tick(),
      Length = length
    }
  
    
    local timers = self:GetAll(player)
    timers[#timers + 1] = timer
    self._data:SetValue(player, "Timers", timers)
    self:RemoveFinished(player)
  end)
  return
end

function TimerService:GetTimeLeft(timer: Timer): number
  return math.max(0, timer.Length - (tick() - timer.BeginTime))
end

return TimerService
