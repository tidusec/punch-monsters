--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local Assets = ReplicatedStorage.Assets

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
		Name = "Tutorial",
		ClassName = "ScreenGui",
		Children = {
			Screen1 = {
				ClassName = "ImageLabel",
			},
            Screen2 = {
				ClassName = "ImageLabel",
			},
            Screen3 = {
				ClassName = "ImageLabel",
			},
            Screen4 = {
				ClassName = "ImageLabel",
			},
            Screen5 = {
				ClassName = "ImageLabel",
			},
            Screen6 = {
                ClassName = "ImageLabel",
            },
		}
	};
}

function RebirthScreen:Initialize(): nil
	self._hashadtutorial = false
	self._data = Knit.GetService("DataService")
    self._ui = Knit.GetController("UIController")
    self._hatching = Knit.GetService("HatchingService")

    self._data.TutorialTime:Connect(function()
		if self._hashadtutorial then
			return
		end
		task.wait(10)
        self._ui:SetScreen("Tutorial")
		self._hashadtutorial = true
    end)

    self._ui:AddModelToViewport(self.Instance.Screen6.Viewport, Assets:WaitForChild("Pets"):WaitForChild("Mystic Ice Demon"), { replaceModel = true })
	
    self:AddToJanitor(self.Instance.Screen1.Next.MouseButton1Click:Connect(function()
        self.Instance.Screen1.Visible = false
        self.Instance.Screen2.Visible = true
    end))

    self:AddToJanitor(self.Instance.Screen2.Next.MouseButton1Click:Connect(function()
        self.Instance.Screen2.Visible = false
        self.Instance.Screen3.Visible = true
    end))

    self:AddToJanitor(self.Instance.Screen3.Next.MouseButton1Click:Connect(function()
        self.Instance.Screen3.Visible = false
        self.Instance.Screen4.Visible = true
    end))

    self:AddToJanitor(self.Instance.Screen4.Next.MouseButton1Click:Connect(function()
        self.Instance.Screen4.Visible = false
        self.Instance.Screen5.Visible = true
    end))

    self:AddToJanitor(self.Instance.Screen5.Next.MouseButton1Click:Connect(function()
        self.Instance.Screen5.Visible = false
        self.Instance.Screen6.Visible = true
    end))

    self:AddToJanitor(self.Instance.Screen6.Next.MouseButton1Click:Connect(function()
        self.Instance.Screen6.Visible = false
        self._ui:SetScreen("MainUi")
        self._hatching:GetFreePetGift()
        self.Instance.Screen1.Visible = true
    end))

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