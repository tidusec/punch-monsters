--!native
--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local randomPair = require(ReplicatedStorage.Modules.RandomPair)

local TimedRewardTemplate = require(ReplicatedStorage.Templates.TimedRewardTemplate)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Array = require(ReplicatedStorage.Modules.NewArray)

local TimedRewardService = Knit.CreateService {
  Name = "TimedRewardService";
  Client = {};
}

local FIRST_JOIN_CACHE = {}
local CLAIMED_REWARDS_CACHE = {}
local SESSION_START_CACHE = {}

function TimedRewardService:KnitStart()
  self._data = Knit.GetService("DataService")
  self._pets = Knit.GetService("PetService")
  self._hatch = Knit.GetService("HatchingService")

  self._data.DataUpdated.Event:Connect(function(player, key)
    if key ~= "FirstJoinToday" then return end
    self:_CheckReset(player)
  end)

  Players.PlayerAdded:Connect(function(player)
    self:_OnPlayerAdded(player)
  end)

  Players.PlayerRemoving:Connect(function(player)
    self:_OnPlayerRemoving(player)
  end)
end

function TimedRewardService:Claim(player: Player, crateNumber: number): nil
  if self:IsClaimed(player, crateNumber) then return end

  task.defer(function(): nil
    local rebirthMultiplier = 1.25 ^ self._data:GetValue(player, "Rebirths")

    local claimed
    if CLAIMED_REWARDS_CACHE[player.UserId] then
      claimed = CLAIMED_REWARDS_CACHE[player.UserId]
    else
      claimed = self:_GetClaimedRewardsToday(player)
      CLAIMED_REWARDS_CACHE[player.UserId] = claimed
    end

    table.insert(claimed, crateNumber)
    self:_SetClaimedRewardsToday(player, claimed)

    local rewardPool = TimedRewardTemplate[crateNumber]
    local key, value = randomPair(rewardPool)
    local chances = {
      1/500,
      1/250,
      1/100,
    }
    local row = math.floor(crateNumber/4) + 1
    local chance = chances[row] or 1/500
    local random = Random.new():NextNumber()
    if random < chance then
      self._pets:Add(player, "Mystic Blackhole Phoenix")
      self._hatch:ShowFakeHatch(player, "Server", "Server1", "Mystic Blackhole Phoenix")
    end
    if key == "Eggs" then
      local _, randomEgg = randomPair(value)
      self._pets:Add(player, randomEgg)
      self._hatch:ShowFakeHatch(player, randomEgg)
    elseif key == "Strength" then
      local strengthType, strength = randomPair(value)
      self._data:IncrementValue(player, strengthType .. "Strength", strength * rebirthMultiplier)
    else
      local winsAmount = math.random(1, value)
      self._data:IncrementValue(player, "Wins", winsAmount * rebirthMultiplier)
    end
    return
  end)
  return
end

function TimedRewardService:IsClaimed(player: Player, crateNumber: number): boolean
  return Array.new("number", self:_GetClaimedRewardsToday(player)):Has(crateNumber)
end

function TimedRewardService:GetElapsedTime(player: Player): number
  local currentTime = tick()
  local timePlayedToday = self._data:GetValue(player, "TimePlayedToday")
  local sessionTime = currentTime - SESSION_START_CACHE[player.UserId]

  if sessionTime > 5 then
    self._data:IncrementValue(player, "TimePlayedToday", sessionTime)
    SESSION_START_CACHE[player.UserId] += sessionTime
  end

  return math.round(timePlayedToday + sessionTime)
end

function TimedRewardService:_CheckReset(player: Player): nil
  -- resets every 12 hours
  if tick() - self:_GetFirstJoinToday(player) >= 12 * 60 * 60 then
    self:_SetFirstJoinToday(player, tick())
    self:_SetClaimedRewardsToday(player, {})
    self._data:SetValue(player, "TimePlayedToday", 0)
  end
  return
end

function TimedRewardService:_GetFirstJoinToday(player: Player): number
  if FIRST_JOIN_CACHE[player.UserId] then
    return FIRST_JOIN_CACHE[player.UserId]
  else
    local firstJoin = self._data:GetValue(player, "FirstJoinToday")
    FIRST_JOIN_CACHE[player.UserId] = firstJoin
    return firstJoin
  end
end

function TimedRewardService:_GetClaimedRewardsToday(player: Player): { number }
  if CLAIMED_REWARDS_CACHE[player.UserId] then
    return CLAIMED_REWARDS_CACHE[player.UserId]
  else
    local claimed = self._data:GetValue(player, "ClaimedRewardsToday")
    CLAIMED_REWARDS_CACHE[player.UserId] = claimed
    return claimed
  end
end

function TimedRewardService:_SetFirstJoinToday(player: Player, value: number): nil
  FIRST_JOIN_CACHE[player.UserId] = value
  self._data:SetValue(player, "FirstJoinToday", value)
  return
end

function TimedRewardService:_SetClaimedRewardsToday(player: Player, value: { number }): nil
  CLAIMED_REWARDS_CACHE[player.UserId] = value
  self._data:SetValue(player, "ClaimedRewardsToday", value)
  return
end

function TimedRewardService:_OnPlayerAdded(player: Player): nil
  local firstJoinToday = self:_GetFirstJoinToday(player)
  if not firstJoinToday then
    self:_CheckReset(player)
  end
  SESSION_START_CACHE[player.UserId] = tick()
end

function TimedRewardService:_OnPlayerRemoving(player: Player): nil
  SESSION_START_CACHE[player.UserId] = nil
end

function TimedRewardService:GetTimeLeft(player: Player): number
  return math.floor(12 * 60 * 60 - (tick() - self:_GetFirstJoinToday(player)))
end

function TimedRewardService.Client:GetElapsedTime(player: Player): number
  return self.Server:GetElapsedTime(player)
end

function TimedRewardService.Client:Claim(player: Player, crateNumber: number): nil
  return self.Server:Claim(player, crateNumber)
end

function TimedRewardService.Client:IsClaimed(player: Player, crateNumber: number): boolean
  return self.Server:IsClaimed(player, crateNumber)
end

function TimedRewardService.Client:GetTimeLeft(player: Player): number
  return self.Server:GetTimeLeft(player)
end

return TimedRewardService
