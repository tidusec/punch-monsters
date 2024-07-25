local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Tweens = require(script.Parent.Parent.Parent.Parent.Modules.Tweens)

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Array = require(ReplicatedStorage.Modules.NewArray)
local Component = require(Packages.Component)

local player = Players.LocalPlayer

local LoadScreen: Component.Def = {
    Name = script.Name;
    IgnoreAncestors = { StarterGui };
    Guards = {
        Ancestors = { player.PlayerGui },
        ClassName = "ScreenGui",
        Children = {
            Transition = { ClassName = "Frame" },
            Background = {
                ClassName = "Frame",
                Children = {
                    Gloves = { ClassName = "Frame" },
                    LoadingBar = {
                        ClassName = "Frame",
                        Children = {
                            Skip = { ClassName = "TextButton" },
                        }
                    }
                }
            }
        }
    };
}

function LoadScreen:Initialize(): nil
    self._preloader = Knit.GetController("PreloadController")
    self._finished = false
    
    local playerGui = self.Instance:FindFirstAncestorOfClass("PlayerGui")
    self._mainUI = playerGui:WaitForChild("MainUi")
    
    local background = self.Instance.Background
    self._background = background
    self._bar = background.LoadingBar
    self._glovesFrame = background.Gloves
    self._glovesImage = self._glovesFrame:FindFirstChildOfClass("ImageLabel")
    self._transition = self.Instance.Transition
    
    -- Setting initial properties
    self._glovesFrame.ClipsDescendants = true
    self._glovesImage.Size = UDim2.new(1, 0, 2, 0)
    self._glovesImage.Position = UDim2.new(0, 0, 0, 0)
    self._glovesImage.AnchorPoint = Vector2.new(0, 0)

    -- Debug: Print initial position
    print("Initial Gloves Image Position:", self._glovesImage.Position)

    -- Enhance background
    self._background.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    self._background.BackgroundTransparency = 0

    -- Enhance progress bar appearance
    self._bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    self._bar.BackgroundTransparency = 0.5
    self._bar.Progress.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    self._bar.Progress.BackgroundTransparency = 0

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = self._bar

    local uiCornerProgress = uiCorner:Clone()
    uiCornerProgress.Parent = self._bar.Progress

    -- Add blur effect
    self._blurEffect = Instance.new("BlurEffect")
    self._blurEffect.Size = 10
    self._blurEffect.Parent = Lighting

    self:AddToJanitor(function()
        self._blurEffect:Destroy()
    end)

    task.spawn(function()
        self:Activate()
    end)

    return
end

function LoadScreen:Activate(): nil
    self._mainUI.Enabled = false
    self.Instance.Enabled = true

    self:UpdateProgressBar(0)
    self:AnimateBar()

    -- Start the image animation
    task.spawn(function()
        while not self._finished do
            print("Starting image animation")
            local targetPosition = UDim2.new(0, 0, -1, 0)
            local tweenInfo = TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
            
            local tween = TweenService:Create(self._glovesImage, tweenInfo, {Position = targetPosition})
            tween:Play()
            
            print("Tween started. Target position:", targetPosition)
            
            tween.Completed:Connect(function()
                print("Tween completed. Current position:", self._glovesImage.Position)
                self._glovesImage.Position = UDim2.new(0, 0, 0, 0)
                print("Reset position:", self._glovesImage.Position)
            end)
            
            task.wait(4)
        end
    end)

    -- Add pulsing effect to the gloves image
    task.spawn(function()
        while not self._finished do
            TweenService:Create(
                self._glovesImage,
                TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {ImageTransparency = 0.2}
            ):Play()
            task.wait(2)
            TweenService:Create(
                self._glovesImage,
                TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {ImageTransparency = 0}
            ):Play()
            task.wait(2)
        end
    end)
    
    task.delay(1, function(): nil
        self._bar.Skip.Visible = true
        return
    end)

    self:AddToJanitor(self._bar.Skip.MouseButton1Click:Connect(function(): nil
        return self._preloader.FinishedLoading:Fire()
    end))

    self:AddToJanitor(self._preloader.ContentLoaded:Connect(function(): nil
        local loaded: number = self._preloader:GetLoaded()
        return self:UpdateProgressBar(loaded / self._preloader:GetRemaining())
    end))

    self._preloader.FinishedLoading:Wait()
    local fadeIn = TweenService:Create(
        self._transition,
        TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
        {BackgroundTransparency = 0}
    )

    fadeIn:Play()
    fadeIn.Completed:Wait()
    self._background.Visible = false
    local fadeOut = TweenService:Create(
        self._transition,
        TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.5),
        {BackgroundTransparency = 1}
    )

    self._finished = true
    self._mainUI.Enabled = true
    player:SetAttribute("Loaded", true)
    Knit.GetService("DataService"):DispatchUpdate(player)

    fadeOut:Play()
    fadeOut.Completed:Wait()
    return self:Destroy()
end

function LoadScreen:UpdateProgressBar(progress: number): nil
    return self._bar.Progress:TweenSize(
        UDim2.fromScale(math.max(progress, 0.05), 1),
        Enum.EasingDirection.In,
        Enum.EasingStyle.Linear,
        0.35, true
    )
end

function LoadScreen:AnimateBar(): nil
    local tweens = Array.new("Instance")
    local barPosition: UDim2 = self._bar.Position
    tweens:Push(
        Tweens.moveFromPosition(self._bar,
            barPosition - UDim2.fromScale(0, 1),
            TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        )
    )

    for _, tween in tweens:GetValues() do
        tween:Play()
        tween.Completed:Wait()
    end
    return
end

return Component.new(LoadScreen)