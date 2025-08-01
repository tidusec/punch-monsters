--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Physics = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerCollisionService = Knit.CreateService {
  Name = "PlayerCollisionService";
}

local function assignPlayerCollisionGroup(char: Model): nil
	char:WaitForChild("HumanoidRootPart")
	char:WaitForChild("Head")
	char:WaitForChild("Humanoid")

	for _, descendant: BasePart in pairs(char:GetDescendants()) do
		task.defer(function()
			if not descendant:IsA("BasePart") then return end
			descendant.CollisionGroup = "Player"
		end)
	end
  return
end

function PlayerCollisionService:KnitInit(): nil
	Physics:RegisterCollisionGroup("Player")
	Physics:CollisionGroupSetCollidable("Player", "Player", false)
	
  Players.PlayerAdded:Connect(function(plr): nil
    plr.CharacterAppearanceLoaded:Connect(assignPlayerCollisionGroup)
		return
  end)

	return
end

return PlayerCollisionService