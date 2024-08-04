--!native
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Component = require(Packages.Component)
local Debounce = require(ReplicatedStorage.Modules.Debounce)

local player = Players.LocalPlayer

local MapWalls: Component.Def = {
    Name = script.Name;
    Guards = {
        ClassName = "Part",
    };
}

function MapWalls:GetClosestPoint(playerPos: Vector3): Vector3
    local wall = self.Instance
    if not wall.CFrame then return end
    
    local relPoint = wall.CFrame:PointToObjectSpace(playerPos)
    local clampedPos = Vector3.new(
        math.clamp(relPoint.X, -wall.Size.X / 2, wall.Size.X / 2),
        math.clamp(relPoint.Y, -wall.Size.Y / 2, wall.Size.Y / 2),
        math.clamp(relPoint.Z, -wall.Size.Z / 2, wall.Size.Z / 2)
    )
    return wall.CFrame:PointToWorldSpace(clampedPos)
end

function MapWalls:HandleSmoothTransparency(time: number, humanoidRootPart: BasePart): nil
    local wall = self.Instance
    local elapsed = 0
    while task.wait(0.05) do
        local pos = humanoidRootPart.Position
        local closestPoint = self:GetClosestPoint(pos, wall)
        local distance = (closestPoint - pos).Magnitude
        if distance then
            if distance < 5 then
                elapsed = 0
                wall.Texture.Transparency = 1 - math.clamp(-1 / 5 * distance + 1, 0, 1)
            else
                wall.Texture.Transparency = 1
            end
            elapsed += 0.05
            if elapsed >= time then
                break
            end
        else
            wall.Texture.Transparency = 1
            elapsed += 0.25
        end
    end
    return 1
end

function MapWalls:Initialize(): nil
    if game:GetService("UserInputService").TouchEnabled then
        return
    end
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local schedulercontroller = Knit.GetController("SchedulerController")
    local db = Debounce.new(5)

    schedulercontroller:Every("1s", function()
        local pos = humanoidRootPart.Position
        local wall = self.Instance
        local closestPoint = self:GetClosestPoint(pos)
        local distance = (closestPoint - pos).Magnitude

        if distance then
            if distance < 20 then
                if db:IsActive() then return end
                self:HandleSmoothTransparency(5, humanoidRootPart)
            else
                wall.Texture.Transparency = 1
            end
        else
            wall.Texture.Transparency = 1
        end
    end)
end

return Component.new(MapWalls)
