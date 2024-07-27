local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MemoryStoreService = game:GetService("MemoryStoreService")

local TFM = require(ReplicatedStorage.Modules.TFMv2)
local abbreviate = require(ReplicatedStorage.Modules.Abbreviate)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Component = require(Packages.Component)
local Array = require(ReplicatedStorage.Modules.NewArray)

local Leaderboard: Component.Def = {
  Name = script.Name;
  Guards = {
    Ancestors = { workspace },
    ClassName = "SurfaceGui",
    Attributes = {
      Type = { Type = "string" }
    },
    Children = {
      Content = { ClassName = "ScrollingFrame" }
    }
  };
}

function Leaderboard:Initialize(): nil
  self._data = Knit.GetService("DataService")
  self._playtime = Knit.GetService("PlaytimeService")

  self._leaderboardEntry = ReplicatedStorage.Assets.UserInterface.Leaderboard.Entry
  self._updateTime = 0
  self._memoryStore = MemoryStoreService:GetSortedMap("Leaderboard_" .. self.Attributes.Type)

  self:StartUpdateLoop()
  return
end

function Leaderboard:StartUpdateLoop(): nil
  task.spawn(function()
    while true do
      self:UpdateMemoryStore()
      self:UpdateEntries()
      task.wait(15)
    end
  end)
  return
end

function Leaderboard:UpdateMemoryStore(): nil
  for _, player in ipairs(Players:GetPlayers()) do
    local score = self:_GetScore(player)
    self._memoryStore:SetAsync(tostring(player.UserId), score, 30) -- 20 second expiration
  end
  return
end

function Leaderboard:UpdateEntries(): nil
  task.spawn(function()
    self.Instance.Content:ClearAllChildren()
  end)

  local success, result = pcall(function()
    return self._memoryStore:GetRangeAsync(Enum.SortDirection.Descending, 50)
  end)

  if not success then
    warn(result)
    warn("Failed to get sorted data from MemoryStore")
    return
  end

  for i, data in ipairs(result) do
    task.spawn(function()
      local userId = tonumber(data.key)
      local player = Players:GetPlayerByUserId(userId)
      if player then
        local entryFrame = self._leaderboardEntry:Clone()
        entryFrame.PlayerName.Text = player.DisplayName
        if self.Attributes.Type == "Playtime" then
          entryFrame.Score.Text = TFM.FormatStr(TFM.Convert(data.value), "%02h:%02m:%02S")
        else
          entryFrame.Score.Text = abbreviate(data.value)
        end
        entryFrame.Icon.Image = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size48x48)
        entryFrame.LayoutOrder = i
        entryFrame.Parent = self.Instance.Content
      end
    end)
  end

  return
end

function Leaderboard:_GetScore(player: Player): number
  if self.Attributes.Type == "Strength" then
    return self._data:GetValue(player, "Strength")
  else
    return self._playtime:GetTotalPlaytime(player)
  end
end

return Component.new(Leaderboard)