local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tween = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

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
							--Title = { ClassName = "TextLabel" }
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
	self._imageOffset = Vector2.new(0, 0)
	
	local playerGui = self.Instance:FindFirstAncestorOfClass("PlayerGui")
	self._mainUI = playerGui:WaitForChild("MainUi")
	
	local background = self.Instance.Background
	self._background = background
	self._bar = background.LoadingBar
	self._glovesFrame = background.Gloves
	self._glovesImage = self._glovesFrame:FindFirstChildOfClass("ImageLabel")
	self._transition = self.Instance.Transition
	
	-- Setting initial properties for the Gloves Frame and ImageLabel
	self._glovesFrame.ClipsDescendants = true
	self._glovesImage.Size = UDim2.new(2, 0, 2, 0) -- Make the ImageLabel larger than the frame for the effect

	task.spawn(function()
		self:Activate()
	end)

	return
end

function LoadScreen:Update(): nil
	-- Update function can be used to handle other updates if necessary
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
			self._glovesImage.Position = UDim2.new(0, 0, 0, 0)
			self._glovesImage:TweenPosition(UDim2.new(-1, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 2, true)
			wait(2)
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
	local fadeIn = Tween:Create(
		self._transition,
		TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
		{BackgroundTransparency = 0}
	)

	fadeIn:Play()
	fadeIn.Completed:Wait()
	self._background.Visible = false
	local fadeOut = Tween:Create(
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
	--self._bar.Title.Text = `Loading\n{math.round(progress * 100)}%`
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
