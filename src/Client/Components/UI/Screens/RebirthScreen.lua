--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local RebirthRequirementsTemplate = require(ReplicatedStorage.Templates.RebirthRequirementsTemplate)
local Debounce = require(ReplicatedStorage.Modules.Debounce)
local abbreviate = require(ReplicatedStorage.Modules.Abbreviate)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Component = require(Packages.Component)

local player = Players.LocalPlayer

local beforeAfterGuard = {
	ClassName = "ImageLabel",
	Children = {
		Value = { ClassName = "TextLabel" }
	}
}

local RebirthScreen: Component.Def = {
	Name = script.Name;
	IgnoreAncestors = { StarterGui };
	Guards = {
		Ancestors = { player.PlayerGui },
		Name = "RebirthUi",
		ClassName = "ScreenGui",
		Children = {
			Background = {
				ClassName = "ImageLabel",
				Children = {
					BeforeRebirthWins = beforeAfterGuard,
					AfterRebirthWins = beforeAfterGuard,
					BeforeRebirthStrength = beforeAfterGuard,
					AfterRebirthStrength = beforeAfterGuard,
					Close = { ClassName = "ImageButton" },
					Skip = { ClassName = "ImageButton" },
					Rebirth = { ClassName = "ImageButton" },
					AutoRebirth = { ClassName = "ImageButton" },
					Wins = {
						ClassName = "ImageLabel",
						Children = {
							Progress = { ClassName = "TextLabel" }
						}
					}
				}
			}
		}
	};
}

function RebirthScreen:Initialize(): nil
	self._data = Knit.GetService("DataService")
	self._rebirths = Knit.GetService("RebirthService")
	self._background = self.Instance.Background
	self._autorebirth = self._data:GetValue("AutoRebirth")

	self:UpdateAutoRebirthButton()

	local db = Debounce.new(0.5)
	self:AddToJanitor(self._background.Rebirth.MouseButton1Click:Connect(function(): nil
		if db:IsActive() then return end
		self._rebirths:Rebirth()
		return self:UpdateStats()
	end))

	self:AddToJanitor(self._data.DataUpdated:Connect(function(key)
		if key ~= "Rebirths" and key ~= "Wins" and key ~= "AutoRebirth" then return end
		self:UpdateStats()
	end))

	self:AddToJanitor(self._background.AutoRebirth.MouseButton1Click:Connect(function(): nil
		self._autorebirth = not self._autorebirth
		self._data:SetSetting("AutoRebirth", self._autorebirth)
		self:UpdateAutoRebirthButton()
		return
	end))

	self:UpdateStats()

	return
end

function RebirthScreen:UpdateAutoRebirthButton(): nil
	if self._autorebirth then
		self._background.AutoRebirth.Title.Text = "Auto Rebirth: ON"
		task.spawn(function(): nil
			self._rebirths:Rebirth()
			return
		end)
	else
		self._background.AutoRebirth.Title.Text = "Auto Rebirth: OFF"
	end
end

function RebirthScreen:UpdateStats(): nil
	self:UpdateAutoRebirthButton()
	
	task.spawn(function(): nil
		local boosts = self._rebirths:GetBeforeAndAfter()
		local wins = self._data:GetValue("Wins")
		local rebirths = self._rebirths:Get()
		local rebirthWinRequirement = RebirthRequirementsTemplate[rebirths :: number + 1]
		self._background.Wins.Progress.Text = `{abbreviate(wins)}/{abbreviate(rebirthWinRequirement)} Wins`
		self._background.BeforeRebirthWins.Value.Text = `{abbreviate(math.round(boosts.Wins.BeforeRebirth))}%`
		self._background.AfterRebirthWins.Value.Text = `{abbreviate(math.round(boosts.Wins.AfterRebirth))}%`
		self._background.BeforeRebirthStrength.Value.Text = `{abbreviate(math.round(boosts.Strength.BeforeRebirth))}%`
		self._background.AfterRebirthStrength.Value.Text = `{abbreviate(math.round(boosts.Strength.AfterRebirth))}%`
		return
	end)
	return
end

return Component.new(RebirthScreen)