--!native
--!strict
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Tween = require(ReplicatedStorage.Modules.Tween)
local ViewportModel = require(ReplicatedStorage.Modules.ViewportModel)

local player = Players.LocalPlayer

-- Constants
local DEFAULT_FOV = 70
local ROTATION_SPEED = 20
local FAST_ROTATION_SPEED = 25
local BUTTON_ANIMATION_SCALE = 1.1
local BUTTON_ANIMATION_DURATION = 0.1

local UIController = Knit.CreateController {
    Name = "UIController";
}

function UIController:KnitStart(): nil
    self._blur = Knit.GetController("BlurController")
    return nil
end

function UIController:KnitInit(): nil
    self.connections = {}
    self._hatching = false
    
    task.spawn(function()
        repeat 
            local success = pcall(function()
                StarterGui:SetCore("ResetButtonCallback", false)
            end)
            task.wait(1)
        until success
    end)
    
    return nil
end

function UIController:SetScreen(name: string, blur: boolean?): ScreenGui?
    if blur ~= nil then
        self._blur:Toggle(blur)
    end

    local setScreen: ScreenGui?
    for _, screen in ipairs(player:WaitForChild("PlayerGui"):GetChildren()) do
        local on = screen.Name == name or screen.Name == "Cmdr"
        task.spawn(function()
            screen.Enabled = on
        end)
        if on and screen.Name == name then
            setScreen = screen
            local frames = CollectionService:GetTagged(screen.Name.."Frame")
            for _, frame in ipairs(frames) do
                self:AnimateFrameEntry(frame)
            end
        end
    end

    if name == "MainUi" then
        for _, frame in ipairs(CollectionService:GetTagged("OutsideUI")) do
            task.spawn(function()
                frame.Enabled = true
            end)
        end
    end

    return setScreen
end

function UIController:AnimateFrameEntry(frame: GuiObject)
    local direction = math.random(1, 4) -- 1: top, 2: bottom, 3: left, 4: right
    local startPos, endPos
    local screenSize = workspace.CurrentCamera.ViewportSize
    if direction == 1 then -- top
        startPos = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, -1, 0)
    elseif direction == 2 then -- bottom
        startPos = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, 1, 0)
    elseif direction == 3 then -- left
        startPos = UDim2.new(-1, 0, frame.Position.Y.Scale, frame.Position.Y.Offset)
    else -- right
        startPos = UDim2.new(1, 0, frame.Position.Y.Scale, frame.Position.Y.Offset)
    end
    endPos = frame.Position
    frame.Position = startPos
    Tween.new(frame, {Position = endPos}, 0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
end

function UIController:SetFrameEnabled(screenName: string, frameName: string, on: boolean): nil
    local screen = player:WaitForChild("PlayerGui"):WaitForChild(screenName)
    local frame = screen:WaitForChild(frameName) :: GuiObject
    frame.Visible = on
    return nil
end

function UIController:SetShiftLock(on: boolean): nil
    -- Implement shift lock logic here
    return nil
end

function UIController:SetupViewport(viewport: ViewportFrame, modelTemplate: Model, options: {replaceModel: boolean?, rotation: number?}?): (ViewportModel?, RBXScriptConnection?)
    if not modelTemplate then
        error("Missing viewport model template")
    end
    
    local replaceModel = options and options.replaceModel or false
    if viewport:FindFirstChild("model") and not replaceModel then
        warn(`Attempt to add model to viewport already containing a model. Viewport location: {viewport:GetFullName()}`)
        return nil, nil
    end
    
    if replaceModel and viewport:FindFirstChild("model") then
        viewport.model:Destroy()
    end
    
    local model: Model = modelTemplate:Clone()
    model.Name = "model"
    model.Parent = viewport

    if not modelTemplate.PrimaryPart then
        warn(`Model {modelTemplate.Name} is missing a PrimaryPart`)
        return nil, nil
    end
    
    local camera = viewport:FindFirstChildOfClass("Camera") or Instance.new("Camera")
    camera.Parent = viewport
    viewport.CurrentCamera = camera
    
    local vpfModel = ViewportModel.new(viewport, camera)
    vpfModel:SetModel(model)
    
    local cf, size = model:GetBoundingBox()
    local defaultFOV = viewport:GetAttribute("DefaultFOV") or DEFAULT_FOV
    camera.FieldOfView = defaultFOV
    
    return vpfModel, camera
end

function UIController:AddModelToViewport(viewport: ViewportFrame, modelTemplate: Model, options: {replaceModel: boolean?}?): RBXScriptConnection?
    local vpfModel, camera = self:SetupViewport(viewport, modelTemplate, options)
    if not vpfModel or not camera then return nil end
    
    local cf, size = modelTemplate:GetBoundingBox()
    local defaultFOV = viewport:GetAttribute("DefaultFOV") or DEFAULT_FOV
    
    local theta = 0


    local connection = RunService.RenderStepped:Connect(function(dt)
        theta = theta + math.rad(ROTATION_SPEED * dt)
        local orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), theta, 0)
        local newCFrame = vpfModel:GetMinimumFitCFrame(orientation)
        
        local distance = (newCFrame.Position - cf.Position).Magnitude
        local fitFOV = 2 * math.deg(math.atan(size.Magnitude / (2 * distance)))
        camera.FieldOfView = math.min(defaultFOV, fitFOV)
        
        camera.CFrame = newCFrame
    end)
    
    return connection
end

function UIController:AddModelToFastViewport(viewport: ViewportFrame, modelTemplate: Model, options: {replaceModel: boolean?}?): RBXScriptConnection?
    local vpfModel, camera = self:SetupViewport(viewport, modelTemplate, options)
    if not vpfModel or not camera then return nil end
    
    local cf, size = modelTemplate:GetBoundingBox()
    local defaultFOV = viewport:GetAttribute("DefaultFOV") or DEFAULT_FOV
    
    local theta = -3 * math.pi / 4
    local connection = RunService.RenderStepped:Connect(function(dt)
        theta = theta + math.rad(FAST_ROTATION_SPEED * dt)
        local orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), theta, 0)
        local newCFrame = vpfModel:GetMinimumFitCFrame(orientation)
        
        local distance = (newCFrame.Position - cf.Position).Magnitude
        local fitFOV = 2 * math.deg(math.atan(size.Magnitude / (2 * distance)))
        camera.FieldOfView = math.min(defaultFOV, fitFOV)
        
        camera.CFrame = newCFrame
    end)
    
    return connection
end

function UIController:AddModelToViewportNoRotation(viewport: ViewportFrame, modelTemplate: Model, options: {replaceModel: boolean?}?): ViewportModel?
    local vpfModel, camera = self:SetupViewport(viewport, modelTemplate, options)
    if not vpfModel or not camera then return nil end
    
    local cf, size = modelTemplate:GetBoundingBox()
    local defaultFOV = viewport:GetAttribute("DefaultFOV") or DEFAULT_FOV
    
    local orientation = CFrame.fromEulerAnglesYXZ(math.rad(-20), math.rad(-90), 0)
    
    local newCFrame = vpfModel:GetMinimumFitCFrame(orientation)
    local distance = (newCFrame.Position - cf.Position).Magnitude
    local fitFOV = 2 * math.deg(math.atan(size.Magnitude / (2 * distance)))
    camera.FieldOfView = math.min(defaultFOV, fitFOV)    
    camera.CFrame = newCFrame

    return vpfModel
end

function UIController:AnimateButton(buttonInstance: GuiButton, frameInstance: GuiObject?, amount: number?)
    frameInstance = frameInstance or buttonInstance
    amount = amount or BUTTON_ANIMATION_SCALE
    local originalSize = frameInstance.Size
    local originalPosition = frameInstance.Position

    local function animateEnter()
        local newSize = UDim2.new(originalSize.X.Scale * amount, 0, originalSize.Y.Scale * amount, 0)
        local deltaX = (originalSize.X.Scale * amount - originalSize.X.Scale) / 2
        local deltaY = (originalSize.Y.Scale * amount - originalSize.Y.Scale) / 2
        local newPosition = UDim2.new(originalPosition.X.Scale - deltaX, 0, originalPosition.Y.Scale - deltaY, 0)
        local constraint = frameInstance:FindFirstChild("UIAspectRatioConstraint")
        if constraint then
            constraint.Parent = nil
        end
        Tween.new(frameInstance, {Size = newSize, Position = newPosition}, BUTTON_ANIMATION_DURATION, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
        if constraint then
            constraint.Parent = frameInstance
        end
    end

    local function animateLeave()
        local constraint = frameInstance:FindFirstChild("UIAspectRatioConstraint")
        if constraint then
            constraint.Parent = nil
        end
        Tween.new(frameInstance, {Size = originalSize, Position = originalPosition}, BUTTON_ANIMATION_DURATION, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
        if constraint then
            constraint.Parent = frameInstance
        end
    end

    local function onStateChange()
        if buttonInstance.GuiState == Enum.GuiState.Hover then
            animateEnter()
        elseif buttonInstance.GuiState == Enum.GuiState.Idle or buttonInstance.GuiState == Enum.GuiState.NonInteractable then
            animateLeave()
        end
    end

    local stateChanged = buttonInstance:GetPropertyChangedSignal("GuiState"):Connect(onStateChange)
    onStateChange()

    self.connections[buttonInstance] = self.connections[buttonInstance] or {}
    table.insert(self.connections[buttonInstance], stateChanged)
end

function UIController:RemoveButtonAnimation(buttonInstance: GuiButton): nil
    if self.connections[buttonInstance] then
        for _, connection in ipairs(self.connections[buttonInstance]) do
            connection:Disconnect()
        end
        self.connections[buttonInstance] = nil
    end
    return nil
end

function UIController:SetHatching(on: boolean): nil
    self._hatching = on
    return nil
end

function UIController:GetHatching(): boolean
    return self._hatching
end

function UIController:Destroy(): nil
    for _, connections in pairs(self.connections) do
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
    end
    self.connections = {}
    return nil
end

return UIController