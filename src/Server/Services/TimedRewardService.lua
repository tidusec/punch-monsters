local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Array = require(Packages.Array)

local TimedRewardService = Knit.CreateService {
  Name = "TimedRewardService";
  Client = {};
}

local FIRST_JOIN_CACHE = {}
local CLAIMED_REWARDS_CACHE = {}
function TimedRewardService:KnitStart()
  self._data = Knit.GetService("DataService")

  Players.PlayerAdded:Connect(function(player)
    self:_CheckReset(player)
  end)
end

function TimedRewardService:Claim(player: Player, crateNumber: number): nil
  if self:IsClaimed(player, crateNumber) then return end

  local claimed
  if CLAIMED_REWARDS_CACHE[player.UserId] then
    claimed = CLAIMED_REWARDS_CACHE[player.UserId]
  else
    claimed = self:_GetClaimedRewardsToday(player)
    CLAIMED_REWARDS_CACHE[player.UserId] = claimed
  end

  table.insert(claimed, crateNumber)
  self:_SetClaimedRewardsToday(player, claimed)
  return
end

function TimedRewardService:IsClaimed(player: Player, crateNumber: number): boolean
  return Array.new("number", self:_GetClaimedRewardsToday(player)):Has(crateNumber)
end

function TimedRewardService:GetElapsedTime(player: Player): number
  return math.round(tick() - self:_GetFirstJoinToday(player))
end

function TimedRewardService:_CheckReset(player: Player): nil
  -- resets every 12 hours
  if self:GetElapsedTime(player) >= 12 * 60 * 60 then
    self:_SetFirstJoinToday(player, tick())
    self:_SetClaimedRewardsToday(player, {})
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

function TimedRewardService.Client:GetElapsedTime(player: Player): number
  return self.Server:GetElapsedTime(player)
end

function TimedRewardService.Client:Claim(player: Player, crateNumber: number): nil
  return self.Server:Claim(player, crateNumber)
end

function TimedRewardService.Client:IsClaimed(player: Player, crateNumber: number): boolean
  return self.Server:IsClaimed(player, crateNumber)
end

return TimedRewardService