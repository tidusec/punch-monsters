--!native
--!strict
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Tween = require(ReplicatedStorage.Modules.Tween)

local player = Players.LocalPlayer

local UIController = Knit.CreateController {
	Name = "UIController";
}

function UIController:KnitStart(): nil
	self._blur = Knit.GetController("BlurController")
	return
end

function UIController:KnitInit(): nil
	task.spawn(function()
		repeat 
			local success = pcall(function(): nil
				return StarterGui:SetCore("ResetButtonCallback", false) 
			end)
			task.wait(1)
		until success
	end)
	self.connections = {}
    self._hatching = false
	return
end


function UIController:SetScreen(name: string, blur: boolean?): ScreenGui?
    if blur ~= nil then
        self._blur:Toggle(blur)
    end

    local setScreen: ScreenGui
    for _, screen in player:WaitForChild("PlayerGui"):GetChildren() do
        local on = screen.Name == name
        task.spawn(function()
            screen.Enabled = on
        end)
        if on then
            setScreen = screen
            local frames = CollectionService:GetTagged(screen.Name.."Frame")
            for _, frame in pairs(frames) do
                local direction = math.random(1, 4) -- 1: top, 2: bottom, 3: left, 4: right
                local startPos, endPos
                local screenSize = workspace.CurrentCamera.ViewportSize
                if direction == 1 then -- top
                    startPos = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, -1, 0)
                    endPos = frame.Position
                elseif direction == 2 then -- bottom
                    startPos = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, 1, 0)
                    endPos = frame.Position
                elseif direction == 3 then -- left
                    startPos = UDim2.new(-1, 0, frame.Position.Y.Scale, frame.Position.Y.Offset)
                    endPos = frame.Position
                else -- right
                    startPos = UDim2.new(1, 0, frame.Position.Y.Scale, frame.Position.Y.Offset)
                    endPos = frame.Position
                end
                frame.Position = startPos
                Tween.new(frame, {Position = endPos}, 0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
            end
        end
    end

    if name == "MainUi" then
		for _, frame in CollectionService:GetTagged("OutsideUI") do
			task.spawn(function()
				frame.Enabled = true
			end)
		end
	end

    return setScreen
end

function UIController:SetFrameEnabled(screenName: string, frameName: string, on: boolean): nil
	local screen = player:WaitForChild("PlayerGui"):WaitForChild(screenName)
	local frame = screen:WaitForChild(frameName) :: GuiObject
	frame.Visible = on
	return
end

--local PlayerModule = player.PlayerScripts:WaitForChild("PlayerModule")
--local Cameras = require(PlayerModule):GetCameras()
--local CameraController = Cameras.activeCameraController
--local MouseLockController = Cameras.activeMouseLockController
function UIController:SetShiftLock(on: boolean): nil
	--MouseLockController:OnMouseLockToggled()
	--CameraController:SetIsMouseLocked(on)
	return
end

function UIController:AddModelToViewport(viewport: ViewportFrame, modelTemplate: Model, options: { replaceModel: boolean? }?): nil
	task.spawn(function()
		if not modelTemplate then error("Missing viewport model template") end
		
		local replaceModel = if options then options.replaceModel else false
		if viewport:FindFirstChild("model") and not replaceModel then
			return warn(`Attempt to add model to viewport already containing a model. Viewport location: {viewport:GetFullName()}`)
		end
		
		if replaceModel and viewport:FindFirstChild("model") then
			(viewport :: any).model:Destroy()
		end
		
		local model: Model = modelTemplate:Clone()
		model.Name = "model"
		model.Parent = viewport
		
		local camera = viewport:WaitForChild("Camera") :: Camera
		local modelCFrame = CFrame.lookAt(Vector3.zero, camera.CFrame.Position)
		local fitModel = viewport:GetAttribute("FitModel")
		if fitModel then
			local cf, size = model:GetBoundingBox()
			modelCFrame *= CFrame.new(0, cf.Position.Y / 2, 0)
			camera.FieldOfView = viewport:GetAttribute("DefaultFOV") + size.Magnitude ^ 1.55
		end

		local modelRotation = viewport:GetAttribute("ModelRotation")
		if modelRotation then
			modelCFrame *= CFrame.Angles(0, math.rad(modelRotation or 0), 0)
		end

		model:PivotTo(modelCFrame)
	end)
	return
end

function UIController:AnimateButton(buttonInstance, frameInstance, amount)
    frameInstance = frameInstance or buttonInstance
    amount = amount or 1.1
    local originalSize = frameInstance.Size
    local originalPosition = frameInstance.Position

    local function animateEnter()
        local newSize = UDim2.new(originalSize.X.Scale * amount, 0, originalSize.Y.Scale * amount, 0)
        local deltaX = (originalSize.X.Scale * amount - originalSize.X.Scale) / 2
        local deltaY = (originalSize.Y.Scale * amount - originalSize.Y.Scale) / 2
        local newPosition = UDim2.new(originalPosition.X.Scale - deltaX, 0, originalPosition.Y.Scale - deltaY, 0)
        local constraint
        if frameInstance:FindFirstChild("UIAspectRatioConstraint") then
            constraint = frameInstance.UIAspectRatioConstraint
            constraint.Parent = nil
        end
        Tween.new(frameInstance, {Size = newSize, Position = newPosition}, 0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
        if constraint then
            constraint.Parent = frameInstance
        end
    end

    local function animateLeave()
        local constraint
        if frameInstance:FindFirstChild("UIAspectRatioConstraint") then
            constraint = frameInstance.UIAspectRatioConstraint
            constraint.Parent = nil
        end
        Tween.new(frameInstance, {Size = originalSize, Position = originalPosition}, 0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
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

    self.connections[buttonInstance] = {stateChanged}
end




function UIController:RemoveButtonAnimation(buttonInstance)
	if self.connections[buttonInstance] then
		for _, connection in pairs(self.connections[buttonInstance]) do
			connection:Disconnect()
		end
		self.connections[buttonInstance] = nil
	end
end

function UIController:SetHatching(on: boolean): nil
    self._hatching = on
end

function UIController:GetHatching(): boolean
    return self._hatching
end

return UIController