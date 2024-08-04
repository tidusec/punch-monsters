--!native
--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Welder = require(ReplicatedStorage.Modules.Welder)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local AssertPlayer = require(script.Parent.Parent.Modules.AssertPlayer)
local Assets = ReplicatedStorage.Assets

local abbreviate = require(ReplicatedStorage.Assets.Modules.Abbreviate)

local TitleService = Knit.CreateService {
	Name = "TitleService";
}

function TitleService:KnitStart(): nil
	self._data = Knit.GetService("DataService")
	self._gamepass = Knit.GetService("GamepassService")
	self._sound = Knit.GetService("SoundService")

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAppearanceLoaded:Connect(function(character)
			self:UpdateTitles(player)
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self._titleAnimations[player.UserId] = nil
	end)

	task.spawn(function()
		while true do
			for _, player in ipairs(Players:GetPlayers()) do
				task.spawn(function()
					self:UpdateTitles(player)
				end)
			end
			task.wait(1)
		end
	end)

	return
end

local title = Assets:WaitForChild("BillboardGui")

function TitleService:UpdateTitles(player: Player): nil
	local character = player.Character
	if not character then
		return
	end

	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not hrp then
		return
	end

	if hrp:FindFirstChild("Title") then
		local title = hrp:FindFirstChild("Title")
		title:WaitForChild("Name").Text = player.Name
		title:WaitForChild("Strength").Text = abbreviate(self._data:GetValue(player, "Strength"))
		return
	end

	local title = title:Clone()

	title.Parent = hrp
	title.Adornee = hrp
	title.Enabled = true
	title.Name = "Title"

	title:WaitForChild("Name").Text = player.Name
	title:WaitForChild("Strength").Text = abbreviate(self._data:GetValue(player, "Strength"))
end

return TitleService