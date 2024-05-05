--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local Debounce = require(ReplicatedStorage.Modules.Debounce)
local abbreviate = require(ReplicatedStorage.Modules.Abbreviate)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Component = require(Packages.Component)

local player = Players.LocalPlayer

local MegaQuestScreen: Component.Def = {
	Name = script.Name;
	IgnoreAncestors = { StarterGui };
	Guards = {
		Ancestors = { player.PlayerGui },
		Name = "MegaQuest",
		ClassName = "ScreenGui",
		Children = {
			Background = {
				ClassName = "ImageLabel",
				Children = {
					Close = { ClassName = "ImageButton" },
					Claim = { ClassName = "ImageButton" },
					Buy = { ClassName = "ImageButton" },
          Note = { ClassName = "TextLabel" },
          Goal2Title = { ClassName = "TextLabel" },
          Goal1Title = { ClassName = "TextLabel" },
          PetName = { ClassName = "TextLabel" },
          PetRarity = { ClassName = "TextLabel" },
					Pet = {
						ClassName = "ImageLabel",
						Children = {
							Viewport = { ClassName = "ViewportFrame" }
						}
					},
          Goal1Progress = {
						ClassName = "ImageLabel",
						Children = {
							Bar = { ClassName = "ImageLabel" },
              Value = { ClassName = "TextLabel" }
						}
					},
          Goal2Progress = {
						ClassName = "ImageLabel",
						Children = {
							Bar = { ClassName = "ImageLabel" },
              Value = { ClassName = "TextLabel" }
						}
					}
				}
			}
		}
	};
}

function MegaQuestScreen:Initialize(): nil
	self._data = Knit.GetService("DataService")
	self._quests = Knit.GetService("QuestService")
	self._questGoals = self._quests:GetQuestGoals()
	self._background = self.Instance.Background

	local db = Debounce.new(0.5)
	self:AddToJanitor(self._background.Claim.MouseButton1Click:Connect(function(): nil
    if not self._quests:IsComplete() then return end
		if db:IsActive() then return end
		return self._quests:Claim()
	end))

	self:AddToJanitor(self._data.DataUpdated:Connect(function(key): nil
		if key ~= "MegaQuestProgress" and key ~= "UpdatedQuestProgress" then return end
		return self:UpdateProgress()
	end))

  return self:UpdateProgress()
end

function MegaQuestScreen:UpdateProgress(): nil
	task.defer(function(): nil
		local progressData = self._data:GetValue("MegaQuestProgress")

    local index = 1
    for name, currentValue in pairs(progressData) do
      task.defer(function(): nil
        local barContainer = self._background:FindFirstChild(`Goal{index}Progress`)
		local title = self._background:FindFirstChild(`Goal{index}Title`)
		if not barContainer or not title then return end
		
        local goalValue: number = self._questGoals[name]
		local progress = currentValue :: number / goalValue
        barContainer.Bar.Size = UDim2.fromScale(progress, 1)
		barContainer.Value.Text = if name == "StayActive" then
			`{currentValue :: number / 60}/{goalValue / 60}`
        else
        	`{currentValue}/{goalValue}`
        
		title.Text = if name == "StayActive" then
          `Stay Active for {goalValue / 60} Minutes`
        elseif name == "OpenEggs" then
          `Open {goalValue} Eggs`
        elseif name == "GainStrength" then
		  `Gain {abbreviate(goalValue)} Strength`
		else
			"???"
		  
        return
      end)
      index += 1
    end

		if index > 1 then
			local colorValue = if self._quests:IsComplete() then Color3.new(1, 1, 1) else Color3.new(0.74, 0.74, 0.74)
			self._background.Claim.ImageColor3 = colorValue
			self._background.Claim.Title.TextColor3 = colorValue
		end

		return
	end)

	return
end

return Component.new(MegaQuestScreen)