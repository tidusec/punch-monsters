--!native
--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Welder = require(ReplicatedStorage.Modules.Welder)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local AssertPlayer = require(script.Parent.Parent.Modules.AssertPlayer)

local TitleService = Knit.CreateService {
	Name = "TitleService";
}

function TitleService:KnitStart(): nil
	self._data = Knit.GetService("DataService")
	self._gamepass = Knit.GetService("GamepassService")
	self._sound = Knit.GetService("SoundService")
	self._playerTitleInfo = {}

	self._titleAnimations = {}
	Players.PlayerAdded:Connect(function(player)
		if not self._playerTitleInfo[player.UserId] then
			self._playerTitleInfo[player.UserId] = {
				Equipped = false,
				LiftDebounce = false,
				EquippedTitleTemplate = nil
			}
		end

		player.CharacterAppearanceLoaded:Connect(function(character)
			workspace:WaitForChild(character.Name)
			local animator = character:WaitForChild("Humanoid"):WaitForChild("Animator") :: Animator
			local animations = ReplicatedStorage.Assets.Animations
			self._titleAnimations[player.UserId] = animator:LoadAnimation(animations.Title)
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self._titleAnimations[player.UserId] = nil
	end)

	return
end