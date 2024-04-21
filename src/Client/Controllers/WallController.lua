--!native
--!strict
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local WallController = Knit.CreateController { Name = "WallController" }

function WallController:KnitStart(): nil
	return
end

function WallController:KnitInit(): nil
    local scheduler = Knit.GetController("SchedulerController")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local walls = CollectionService:GetTagged("mapwalls")
    self.cache = {}

    scheduler:Every("0.1 seconds", function()
        local pos = humanoidRootPart.Position
        for _, wall in ipairs(walls) do
            local closestPoint = self:GetClosestPoint(pos, wall)
            local distance = (closestPoint - pos).Magnitude
            if distance < 10 then
                if self.cache[wall] then continue end
                self.cache[wall] = true
                wall.Texture.Transparency = self:HandleSmoothTransparency(2, humanoidRootPart, wall)
            else
                if self.cache[wall] then continue end
                wall.Texture.Transparency = 1
            end
        end
    end)
end

function WallController:GetClosestPoint(PlayerPos: Vector3, Wall: Instance): Vector3
    local RelPoint = Wall.CFrame:PointToObjectSpace(PlayerPos)
    local ClampedPos = Vector3.new(
        math.clamp(RelPoint.X, -Wall.Size.X/2, Wall.Size.X/2),
        math.clamp(RelPoint.Y, -Wall.Size.Y/2, Wall.Size.Y/2),
        math.clamp(RelPoint.Z, -Wall.Size.Z/2, Wall.Size.Z/2)
    )
    local ClosestPoint = Wall.CFrame:PointToWorldSpace(ClampedPos)
    return ClosestPoint
end

function WallController:HandleSmoothTransparency(time: number, humanoidRootPart: Instance, wall: Instance): nil
    local elapsed = 0
    while task.wait(0.05) do
        local pos = humanoidRootPart.Position
        local closestPoint = self:GetClosestPoint(pos, wall)
        local distance = (closestPoint - pos).Magnitude
        if distance < 5 then
            elapsed = 0
            wall.Texture.Transparency = 1 - math.clamp(-1/5 * distance + 1, 0, 1)
        else
            wall.Texture.Transparency = 1
        end
        elapsed += 0.05
        if elapsed >= time then
            self.cache[wall] = nil
            break
        end
    end
end

return WallController