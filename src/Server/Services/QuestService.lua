--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Runtime = game:GetService("RunService")
local Players = game:GetService("Players")
local GameData = DataStoreService:GetDataStore("GameData")

local randomPair = require(ReplicatedStorage.Modules.RandomPair)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local QUEST_GOALS = {
  StayActive = 25 * 60, -- 25 mins
  OpenEggs = 1500,
  EarnStrength = 35000,
}

local QuestService = Knit.CreateService {
  Name = "QuestService";
  Client = {};
}

function QuestService:KnitStart(): nil
  self._data = Knit.GetService("DataService")
  self._pets = Knit.GetService("PetService")
  self._hatch = Knit.GetService("HatchingService")

  self._data.DataUpdated.Event:Connect(function(player: Player, key): nil
    if key == "UpdatedQuestProgress" then
      self:_Reset(player)
    end
  end)

  local elapsed = 0
  local questsWereReset = GameData:GetAsync("QuestsResetThisWeek")
  Runtime.Heartbeat:Connect(function(dt: number): nil
    if elapsed >= 1 then
      elapsed = 0
      local date = os.date("!*t")
      if date.wday == 1 then
        if questsWereReset then return end

        GameData:RemoveAsync("GoalsThisWeek")
        GameData:SetAsync("QuestsResetThisWeek", true)
        questsWereReset = GameData:GetAsync("QuestsResetThisWeek")
        for _, player in pairs(Players:GetPlayers()) do
          task.defer(function(): nil
            self._data:SetValue(player, "UpdatedQuestProgress", false):await()
            self:_Reset(player)
            return
          end)
        end
      else
        if not questsWereReset then return end
        GameData:SetAsync("QuestsResetThisWeek", false)
        questsWereReset = GameData:GetAsync("QuestsResetThisWeek")
      end
    else
      elapsed += dt
    end
    return
  end)

  return
end

function QuestService:_Reset(player: Player): nil
  if self._data:GetValue(player, "UpdatedQuestProgress") then return end
  self._data:SetValue(player, "UpdatedQuestProgress", true):await()

  local goal1, goal2 = self:GetGoalsThisWeek()
  local progress = self._data:GetValue(player, "MegaQuestProgress")
  if not progress then progress = {} end
  progress[goal1] = 0
  progress[goal2] = 0
  self._data:SetValue(player, "MegaQuestProgress", progress):await()
  
  return
end

function QuestService:IncrementProgress(player: Player, goalName: string, amount: number): nil
  local progress = self._data:GetValue(player, "MegaQuestProgress")
  if not progress or next(progress) == nil then
    self._data:SetValue(player, "UpdatedQuestProgress", false):await()
    self:_Reset(player)
    progress = self._data:GetValue(player, "MegaQuestProgress")
  end

  if progress[goalName] then
    self:SetProgress(player, goalName, progress[goalName] + amount)
  end
  return
end

function QuestService:SetProgress(player: Player, goalName: string, value: number): nil
  local progress = self._data:GetValue(player, "MegaQuestProgress")
  if not progress then return end
  if progress[goalName] then
    progress[goalName] = value
    self._data:SetValue(player, "MegaQuestProgress", progress)
  end
  return
end

function QuestService:IsComplete(player: Player): boolean
  local progress1, progress2 = self:GetQuestProgress(player)
  return progress1 == 1 and progress2 == 1
end

function QuestService:GetQuestProgress(player: Player): (number, number)
  local goal1, goal2 = self:GetGoalsThisWeek()
  return self:_GetGoalProgress(player, goal1), self:_GetGoalProgress(player, goal2)
end

function QuestService:_GetGoalProgress(player: Player, goalName: string): number
  local progress = self._data:GetValue(player, "MegaQuestProgress")
  if not progress then return 0 end
  if progress["Done"] then return 1 end
  if progress["Completed"] then return 1 end
  return math.min((progress[goalName] or 0) / QUEST_GOALS[goalName], 1)
end

function QuestService:GetGoalsThisWeek(): (string, string)
  local goals = GameData:GetAsync("GoalsThisWeek")
  if not goals then
    local goal1, goal2 = randomPair(QUEST_GOALS), randomPair(QUEST_GOALS)
    while goal1 == goal2 do
      goal2 = randomPair(QUEST_GOALS)
    end
    GameData:SetAsync("GoalsThisWeek", {goal1, goal2})
    return goal1, goal2
  else
    return goals[1], goals[2]
  end
end

function QuestService:Claim(player: Player): nil
  if not self:IsComplete(player) then return end
  local progress = self._data:GetValue(player, "MegaQuestProgress")
  if not progress then return end
  if progress["Completed"] then return end

  --// TODO: make it give the pet
  self._pets:Add(player, "Magical Winged Wyvern")
  self._hatch:ShowFakeHatch(player, "Magical Winged Wyvern")

  progress["Completed"] = true
  self._data:SetValue(player, "MegaQuestProgress", progress)

  return
end

function QuestService:MakeItDone(player: Player): nil
  local progress = self._data:GetValue(player, "MegaQuestProgress")
  if not progress then return end
  progress["Done"] = true
  self._data:SetValue(player, "MegaQuestProgress", progress)
  return
end

function QuestService.Client:Claim(player: Player): nil
  return self.Server:Claim(player)
end

function QuestService.Client:MakeItDone(player: Player): nil
  return self.Server:MakeItDone(player)
end

function QuestService.Client:IsComplete(player: Player): boolean
  return self.Server:IsComplete(player)
end

function QuestService.Client:GetQuestProgress(player: Player): (number, number)
  return self.Server:GetQuestProgress(player)
end

function QuestService.Client:GetQuestGoals(): typeof(QUEST_GOALS)
  return QUEST_GOALS
end

return QuestService